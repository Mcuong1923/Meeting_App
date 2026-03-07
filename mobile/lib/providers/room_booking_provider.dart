import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_booking_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/room_model.dart';
import '../utils/app_logger.dart';
import '../utils/booking_permissions.dart';

class RoomBookingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<RoomBooking> _bookings = [];
  List<RoomBooking> _myBookings = [];
  List<RoomBooking> _pendingApprovals = [];
  List<RoomBooking> _quickBookingsNeedingReminder = [];
  bool _isLoading = false;
  String? _error;
  
  // User booking stats cache
  final Map<String, UserBookingStats> _userStatsCache = {};
  
  // Getters
  List<RoomBooking> get bookings => _bookings;
  List<RoomBooking> get myBookings => _myBookings;
  List<RoomBooking> get pendingApprovals => _pendingApprovals;
  List<RoomBooking> get quickBookingsNeedingReminder => _quickBookingsNeedingReminder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load bookings for a specific date
  Future<List<RoomBooking>> getBookingsForDate(
    DateTime date, {
    String? roomId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection('room_bookings')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          // Đếm mọi booking đang giữ chỗ/thực sự chặn phòng
          .where('status', whereIn: ['reserved', 'pending', 'approved']);

      if (roomId != null) {
        query = query.where('roomId', isEqualTo: roomId);
      }

      final snapshot = await query.get();
      
      _bookings = snapshot.docs
          .map((doc) => RoomBooking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort by start time
      _bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      return _bookings;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error loading bookings for date: $e');
      return [];
    }
  }

  /// Load bookings for a date range
  Future<List<RoomBooking>> getBookingsForDateRange(
    DateTime start,
    DateTime end, {
    String? roomId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      Query query = _firestore
          .collection('room_bookings')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          // Đếm mọi booking đang giữ chỗ/thực sự chặn phòng
          .where('status', whereIn: ['reserved', 'pending', 'approved']);

      if (roomId != null) {
        query = query.where('roomId', isEqualTo: roomId);
      }

      final snapshot = await query.get();
      
      final bookings = snapshot.docs
          .map((doc) => RoomBooking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      return bookings;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error loading bookings for date range: $e');
      return [];
    }
  }

  /// Load user's own bookings
  Future<List<RoomBooking>> getMyBookings(
    String userId, {
    BookingStatus? status,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      Query query = _firestore
          .collection('room_bookings')
          .where('createdBy', isEqualTo: userId)
          .orderBy('startTime', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      
      _myBookings = snapshot.docs
          .map((doc) => RoomBooking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      return _myBookings;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error loading my bookings: $e');
      return [];
    }
  }

  /// Load pending approvals (for Directors/Admins)
  Future<List<RoomBooking>> getPendingApprovals({
    String? departmentId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      Query query = _firestore
          .collection('room_bookings')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);

      if (departmentId != null) {
        query = query.where('createdByDepartmentId', isEqualTo: departmentId);
      }

      final snapshot = await query.get();
      
      _pendingApprovals = snapshot.docs
          .map((doc) => RoomBooking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      return _pendingApprovals;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error loading pending approvals: $e');
      return [];
    }
  }

  /// Create a new booking
  Future<RoomBooking?> createBooking({
    required RoomModel room,
    required UserModel user,
    required DateTime startTime,
    required DateTime endTime,
    required String title,
    String? description,
    String? meetingId,
    List<String> participantIds = const [],
    List<String> participantNames = const [],
    bool isRecurring = false,
    RecurringPattern? recurringPattern,
  }) async {
    try {
      // Validate booking
      final validation = BookingPermissions.validateBooking(
        user: user,
        room: room,
        startTime: startTime,
        endTime: endTime,
        isRecurring: isRecurring,
      );

      if (!validation.isValid) {
        _error = validation.errorMessage;
        notifyListeners();
        return null;
      }

      // Log selected room info before creating booking
      debugPrint('[BOOKING][CREATE][ROOM_SELECTED] roomId=${room.id} '
          'roomName=${room.name} '
          'source=RoomModel.id '
          'isDocId=${room.id.length > 10}'); // DocId typically > 10 chars

      // Check conflicts
      final conflicts = await checkConflicts(room.id, startTime, endTime);
      if (conflicts.isNotEmpty && !BookingPermissions.canOverrideConflict(user)) {
        _error = 'Phòng đã được đặt trong khoảng thời gian này';
        notifyListeners();
        return null;
      }

      // Determine if needs approval
      final needsApproval = user.role == UserRole.employee || 
                           user.role == UserRole.guest;
      
      final booking = RoomBooking(
        id: '', // Will be set by Firestore
        roomId: room.id, // Use docId format (from RoomProvider)
        roomName: room.name,
        meetingId: meetingId,
        startTime: startTime,
        endTime: endTime,
        title: title,
        description: description,
        createdBy: user.id,
        createdByName: user.displayName,
        createdByDepartmentId: user.departmentId,
        createdAt: DateTime.now(),
        status: needsApproval ? BookingStatus.pending : BookingStatus.approved,
        approvedBy: needsApproval ? null : user.id,
        approvedByName: needsApproval ? null : user.displayName,
        approvedAt: needsApproval ? null : DateTime.now(),
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
        participantIds: participantIds,
        participantNames: participantNames,
      );

      final docRef = await _firestore.collection('room_bookings').add(booking.toMap());
      
      final createdBooking = booking.copyWith(id: docRef.id);
      
      _bookings.add(createdBooking);
      _myBookings.insert(0, createdBooking);
      
      _error = null;
      notifyListeners();
      
      debugPrint('[BOOKING][CREATE] Created booking ${docRef.id} for room ${room.name}');
      
      return createdBooking;
    } catch (e) {
      _error = 'Lỗi tạo booking: $e';
      notifyListeners();
      debugPrint('Error creating booking: $e');
      return null;
    }
  }

  /// Update a booking
  Future<bool> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
    UserModel user,
  ) async {
    try {
      // Get current booking
      final doc = await _firestore.collection('room_bookings').doc(bookingId).get();
      if (!doc.exists) {
        _error = 'Booking không tồn tại';
        notifyListeners();
        return false;
      }

      final booking = RoomBooking.fromMap(doc.data()!, doc.id);
      
      // Check permission
      if (!BookingPermissions.canEditBooking(user, booking)) {
        _error = 'Bạn không có quyền chỉnh sửa booking này';
        notifyListeners();
        return false;
      }

      await _firestore.collection('room_bookings').doc(bookingId).update(updates);
      
      // Update local list
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = RoomBooking.fromMap({...doc.data()!, ...updates}, bookingId);
      }
      
      _error = null;
      notifyListeners();
      
      debugPrint('[BOOKING][UPDATE] Updated booking $bookingId');
      
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật booking: $e';
      notifyListeners();
      debugPrint('Error updating booking: $e');
      return false;
    }
  }

  /// Approve a booking
  Future<bool> approveBooking(String bookingId, UserModel user) async {
    if (!BookingPermissions.canApproveBooking(user)) {
      _error = 'Bạn không có quyền duyệt booking';
      notifyListeners();
      return false;
    }

    return updateBooking(bookingId, {
      'status': 'approved',
      'approvedBy': user.id,
      'approvedByName': user.displayName,
      'approvedAt': Timestamp.now(),
    }, user);
  }

  /// Reject a booking
  Future<bool> rejectBooking(
    String bookingId,
    UserModel user,
    String reason,
  ) async {
    if (!BookingPermissions.canApproveBooking(user)) {
      _error = 'Bạn không có quyền từ chối booking';
      notifyListeners();
      return false;
    }

    return updateBooking(bookingId, {
      'status': 'rejected',
      'rejectionReason': reason,
    }, user);
  }

  /// Cancel a booking
  Future<bool> cancelBooking(
    String bookingId,
    UserModel user,
    String reason,
  ) async {
    try {
      final doc = await _firestore.collection('room_bookings').doc(bookingId).get();
      if (!doc.exists) {
        _error = 'Booking không tồn tại';
        notifyListeners();
        return false;
      }

      final booking = RoomBooking.fromMap(doc.data()!, doc.id);
      
      if (!BookingPermissions.canCancelBooking(user, booking)) {
        _error = 'Bạn không có quyền hủy booking này';
        notifyListeners();
        return false;
      }

      await _firestore.collection('room_bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
      });
      
      // Update local lists
      _bookings.removeWhere((b) => b.id == bookingId);
      _myBookings = _myBookings.map((b) {
        if (b.id == bookingId) {
          return b.copyWith(status: BookingStatus.cancelled, cancellationReason: reason);
        }
        return b;
      }).toList();
      
      _error = null;
      notifyListeners();
      
      debugPrint('[BOOKING][CANCEL] Cancelled booking $bookingId');
      
      return true;
    } catch (e) {
      _error = 'Lỗi hủy booking: $e';
      notifyListeners();
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  /// Check for booking conflicts
  Future<List<RoomBooking>> checkConflicts(
    String roomId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      // Query bookings that might overlap
      final snapshot = await _firestore
          .collection('room_bookings')
          .where('roomId', isEqualTo: roomId)
          // Mọi booking đang giữ chỗ hoặc đã duyệt đều phải chặn phòng
          .where('status', whereIn: ['reserved', 'pending', 'approved'])
          .where('startTime', isLessThan: Timestamp.fromDate(endTime))
          .get();
      
      final conflicts = <RoomBooking>[];
      
      for (final doc in snapshot.docs) {
        final booking = RoomBooking.fromMap(doc.data(), doc.id);
        
        // Check if actually overlaps (endTime > startTime)
        if (booking.endTime.isAfter(startTime)) {
          conflicts.add(booking);
        }
      }
      
      return conflicts;
    } catch (e) {
      debugPrint('Error checking conflicts: $e');
      return [];
    }
  }

  /// Check room availability for a time slot
  Future<bool> checkAvailability(
    String roomId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final conflicts = await checkConflicts(roomId, startTime, endTime);
    return conflicts.isEmpty;
  }

  /// Get bookings for a specific room on a date
  List<RoomBooking> getBookingsForRoom(String roomId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _bookings.where((b) {
      return b.roomId == roomId &&
             b.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             b.startTime.isBefore(endOfDay);
    }).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // QUICK BOOKING SPECIFIC METHODS
  // ============================================================

  /// Get user booking statistics for quota and violation checking
  Future<UserBookingStats> getUserBookingStats(String userId) async {
    // Check cache first
    if (_userStatsCache.containsKey(userId)) {
      final cached = _userStatsCache[userId]!;
      // Check if cache is still valid (same day)
      if (_isSameDay(DateTime.now(), cached.restrictedAt ?? DateTime.now())) {
        return cached;
      }
    }

    try {
      // Get today's quick bookings count
      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayBookingsSnapshot = await _firestore
          .collection('room_bookings')
          .where('createdBy', isEqualTo: userId)
          .where('type', isEqualTo: BookingType.quickBooking.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      // Get violations in last 7 days
      final sevenDaysAgo = DateTime.now().subtract(
        const Duration(days: BookingRules.violationPeriodDays),
      );

      final violationsSnapshot = await _firestore
          .collection('room_bookings')
          .where('createdBy', isEqualTo: userId)
          .where('type', isEqualTo: BookingType.quickBooking.name)
          .where('status', isEqualTo: BookingStatus.releasedBySystem.name)
          .where('releaseReason', isEqualTo: ReleaseReason.notConvertedToMeeting.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // Check if user is restricted
      final userDoc = await _firestore.collection('user_booking_stats').doc(userId).get();
      bool isRestricted = false;
      DateTime? restrictedAt;
      
      if (userDoc.exists) {
        isRestricted = userDoc.data()?['isRestricted'] ?? false;
        restrictedAt = userDoc.data()?['restrictedAt']?.toDate();
      }

      final stats = UserBookingStats(
        userId: userId,
        quickBookingsToday: todayBookingsSnapshot.docs.length,
        violationsLast7Days: violationsSnapshot.docs.length,
        isRestricted: isRestricted,
        restrictedAt: restrictedAt,
      );

      // Cache the stats
      _userStatsCache[userId] = stats;

      // Auto-unlock if restriction period has passed
      if (stats.shouldAutoUnlock()) {
        await _unlockUserRestriction(userId);
        return stats.copyWith(isRestricted: false);
      }

      return stats;
    } catch (e) {
      debugPrint('[BOOKING][STATS] Error getting user stats: $e');
      return UserBookingStats(userId: userId);
    }
  }

  /// Create a quick booking (room reservation)
  Future<RoomBooking?> createQuickBooking({
    required RoomModel room,
    required UserModel user,
    required DateTime startTime,
    required DateTime endTime,
    required String title,
    String? note,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get user stats for validation
      final stats = await getUserBookingStats(user.id);

      // Validate quick booking
      final validation = QuickBookingPermissions.validateQuickBooking(
        user: user,
        room: room,
        startTime: startTime,
        endTime: endTime,
        stats: stats,
      );

      if (!validation.isValid) {
        _error = validation.errorMessage;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Log selected room info before creating quick booking
      debugPrint('[BOOKING][QUICK][ROOM_SELECTED] roomId=${room.id} '
          'roomName=${room.name} '
          'source=RoomModel.id '
          'isDocId=${room.id.length > 10}'); // DocId typically > 10 chars

      // Check conflicts
      final conflicts = await checkConflicts(room.id, startTime, endTime);
      if (conflicts.isNotEmpty) {
        _error = 'Phòng đã được đặt trong khoảng thời gian này';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Determine approval status
      ApprovalStatus approvalStatus = ApprovalStatus.none;
      BookingStatus bookingStatus = BookingStatus.reserved;

      if (validation.requiresAdminApproval || stats.isRestricted) {
        approvalStatus = ApprovalStatus.pendingApproval;
      }

      final booking = RoomBooking(
        id: '',
        roomId: room.id, // Use docId format (from RoomProvider)
        roomName: room.name,
        type: BookingType.quickBooking,
        requiresMeeting: true,
        startTime: startTime,
        endTime: endTime,
        title: title,
        description: note,
        createdBy: user.id,
        createdByName: user.displayName,
        createdByDepartmentId: user.departmentId,
        createdAt: DateTime.now(),
        status: bookingStatus,
        approvalStatus: approvalStatus,
      );

      final docRef = await _firestore.collection('room_bookings').add(booking.toMap());
      final createdBooking = booking.copyWith(id: docRef.id);

      _bookings.add(createdBooking);
      _myBookings.insert(0, createdBooking);

      // Clear stats cache to force refresh
      _userStatsCache.remove(user.id);

      _error = null;
      _isLoading = false;
      notifyListeners();

      debugPrint('[BOOKING][QUICK] Created quick booking ${docRef.id} for room ${room.name}');
      debugPrint('[BOOKING][QUICK] User has ${validation.remainingQuota} quick bookings remaining today');

      return createdBooking;
    } catch (e) {
      _error = 'Lỗi tạo booking: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('[BOOKING][QUICK] Error creating quick booking: $e');
      return null;
    }
  }

  /// Convert quick booking to meeting
  Future<bool> convertToMeeting(String bookingId, String meetingId) async {
    try {
      final doc = await _firestore.collection('room_bookings').doc(bookingId).get();
      if (!doc.exists) {
        _error = 'Booking không tồn tại';
        notifyListeners();
        return false;
      }

      final booking = RoomBooking.fromMap(doc.data()!, doc.id);

      // Check if already converted
      if (booking.meetingId != null) {
        _error = 'Booking đã được chuyển thành cuộc họp';
        notifyListeners();
        return false;
      }

      // Check if expired
      if (booking.status == BookingStatus.releasedBySystem) {
        _error = 'Booking đã hết hạn';
        notifyListeners();
        return false;
      }

      await _firestore.collection('room_bookings').doc(bookingId).update({
        'meetingId': meetingId,
        'status': BookingStatus.converted.name,
        'convertedAt': Timestamp.now(),
      });

      // Update local list
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = booking.copyWith(
          meetingId: meetingId,
          status: BookingStatus.converted,
          convertedAt: DateTime.now(),
        );
      }

      _error = null;
      notifyListeners();

      debugPrint('[BOOKING][CONVERT] Converted booking $bookingId to meeting $meetingId');

      return true;
    } catch (e) {
      _error = 'Lỗi chuyển đổi booking: $e';
      notifyListeners();
      debugPrint('[BOOKING][CONVERT] Error converting booking: $e');
      return false;
    }
  }

  // Add a flag to prevent log spam if index is missing
  bool _indexErrorLogged = false;

  /// Auto-release expired quick bookings (call on app resume/open)
  Future<int> autoReleaseExpiredBookings() async {
    try {
      final now = DateTime.now();
      final releaseDeadline = now.subtract(
        const Duration(minutes: BookingRules.autoReleaseMinutesAfterStart),
      );

      // Query quick bookings that should be released
      final snapshot = await _firestore
          .collection('room_bookings')
          .where('type', isEqualTo: BookingType.quickBooking.name)
          .where('status', isEqualTo: BookingStatus.reserved.name)
          .where('meetingId', isNull: true)
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(releaseDeadline))
          .get();

      int releasedCount = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final booking = RoomBooking.fromMap(doc.data(), doc.id);
        
        // Double check the booking should be released
        if (booking.isOverdueForConversion) {
          batch.update(doc.reference, {
            'status': BookingStatus.releasedBySystem.name,
            'releaseReason': ReleaseReason.notConvertedToMeeting.name,
          });

          // Record violation
          await _recordViolation(booking.createdBy);
          
          releasedCount++;
          debugPrint('[BOOKING][AUTO-RELEASE] Released booking ${doc.id} for user ${booking.createdBy}');
        }
      }

      if (releasedCount > 0) {
        await batch.commit();
        
        // Refresh bookings list
        if (_bookings.isNotEmpty) {
          final date = _bookings.first.startTime;
          await getBookingsForDate(date);
        }
      }

      if (releasedCount > 0) {
        AppLogger.i('Released $releasedCount expired bookings', tag: 'BOOKING_AUTO_RELEASE');
      }
      return releasedCount;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        if (!_indexErrorLogged) {
          AppLogger.e(
              'Thiếu Index Firestore cho Auto Release: Truy cập Firebase Console để tạo index. Error: ${e.message}',
              tag: 'BOOKING_AUTO_RELEASE');
          _indexErrorLogged = true; // Avoid spam
        }
        return 0; // Return gracefully without crashing/spamming
      }
      AppLogger.e('Error auto-releasing bookings', error: e, tag: 'BOOKING_AUTO_RELEASE');
      return 0;
    } catch (e) {
      AppLogger.e('Unknown error auto-releasing bookings', error: e, tag: 'BOOKING_AUTO_RELEASE');
      return 0;
    }
  }

  /// Record a violation for a user
  Future<void> _recordViolation(String userId) async {
    try {
      final statsRef = _firestore.collection('user_booking_stats').doc(userId);
      final statsDoc = await statsRef.get();

      int currentViolations = 0;
      if (statsDoc.exists) {
        currentViolations = statsDoc.data()?['violationsLast7Days'] ?? 0;
      }

      final newViolations = currentViolations + 1;
      final shouldRestrict = newViolations >= BookingRules.violationThreshold;

      await statsRef.set({
        'userId': userId,
        'violationsLast7Days': newViolations,
        'lastViolationAt': Timestamp.now(),
        'isRestricted': shouldRestrict,
        'restrictedAt': shouldRestrict ? Timestamp.now() : null,
      }, SetOptions(merge: true));

      // Clear cache
      _userStatsCache.remove(userId);

      if (shouldRestrict) {
        debugPrint('[BOOKING][VIOLATION] User $userId is now RESTRICTED after $newViolations violations');
      } else {
        debugPrint('[BOOKING][VIOLATION] User $userId has $newViolations violations');
      }
    } catch (e) {
      debugPrint('[BOOKING][VIOLATION] Error recording violation: $e');
    }
  }

  /// Unlock user restriction (after successful conversion or admin approval)
  Future<void> _unlockUserRestriction(String userId) async {
    try {
      await _firestore.collection('user_booking_stats').doc(userId).update({
        'isRestricted': false,
        'restrictedAt': null,
      });

      // Clear cache
      _userStatsCache.remove(userId);

      debugPrint('[BOOKING][UNLOCK] User $userId restriction unlocked');
    } catch (e) {
      debugPrint('[BOOKING][UNLOCK] Error unlocking user: $e');
    }
  }

  /// Unlock user after successful booking conversion
  Future<void> unlockUserAfterSuccessfulConversion(String userId) async {
    final stats = await getUserBookingStats(userId);
    if (stats.isRestricted) {
      await _unlockUserRestriction(userId);
    }
  }

  /// Get quick bookings that need reminders
  Future<List<RoomBooking>> getBookingsNeedingReminder(String userId) async {
    try {
      final now = DateTime.now();
      final reminderWindow = now.add(
        const Duration(minutes: BookingRules.reminderMinutesBefore + 5), // Some buffer
      );

      final snapshot = await _firestore
          .collection('room_bookings')
          .where('createdBy', isEqualTo: userId)
          .where('type', isEqualTo: BookingType.quickBooking.name)
          .where('status', isEqualTo: BookingStatus.reserved.name)
          .where('meetingId', isNull: true)
          .where('reminderSent', isEqualTo: false)
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(reminderWindow))
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .get();

      _quickBookingsNeedingReminder = snapshot.docs
          .map((doc) => RoomBooking.fromMap(doc.data(), doc.id))
          .where((b) => b.shouldSendReminder)
          .toList();

      notifyListeners();
      return _quickBookingsNeedingReminder;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        AppLogger.e('Thiếu Index Firestore cho Get Bookings Needing Reminder: Yêu cầu cập nhật Index.',
            tag: 'BOOKING_REMINDER');
        return [];
      }
      AppLogger.e('Error getting bookings needing reminder', error: e, tag: 'BOOKING_REMINDER');
      return [];
    } catch (e) {
      AppLogger.e('Unknown error getting bookings needing reminder', error: e, tag: 'BOOKING_REMINDER');
      return [];
    }
  }

  /// Mark reminder as sent
  Future<void> markReminderSent(String bookingId) async {
    try {
      await _firestore.collection('room_bookings').doc(bookingId).update({
        'reminderSent': true,
        'reminderSentAt': Timestamp.now(),
      });

      _quickBookingsNeedingReminder.removeWhere((b) => b.id == bookingId);
      notifyListeners();

      debugPrint('[BOOKING][REMINDER] Marked reminder sent for booking $bookingId');
    } catch (e) {
      debugPrint('[BOOKING][REMINDER] Error marking reminder sent: $e');
    }
  }

  /// Get booking by ID
  Future<RoomBooking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('room_bookings').doc(bookingId).get();
      if (!doc.exists) return null;
      return RoomBooking.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[BOOKING] Error getting booking by ID: $e');
      return null;
    }
  }

  /// Admin approve restricted user's booking
  Future<bool> adminApproveRestrictedBooking(String bookingId, UserModel admin) async {
    if (!BookingPermissions.canApproveBooking(admin)) {
      _error = 'Bạn không có quyền duyệt booking';
      notifyListeners();
      return false;
    }

    try {
      await _firestore.collection('room_bookings').doc(bookingId).update({
        'approvalStatus': ApprovalStatus.adminApproved.name,
        'approvedBy': admin.id,
        'approvedByName': admin.displayName,
        'approvedAt': Timestamp.now(),
      });

      _error = null;
      notifyListeners();

      debugPrint('[BOOKING][ADMIN] Approved restricted booking $bookingId');
      return true;
    } catch (e) {
      _error = 'Lỗi duyệt booking: $e';
      notifyListeners();
      return false;
    }
  }

  /// Admin reject restricted user's booking
  Future<bool> adminRejectRestrictedBooking(
    String bookingId, 
    UserModel admin,
    String reason,
  ) async {
    if (!BookingPermissions.canApproveBooking(admin)) {
      _error = 'Bạn không có quyền từ chối booking';
      notifyListeners();
      return false;
    }

    try {
      await _firestore.collection('room_bookings').doc(bookingId).update({
        'approvalStatus': ApprovalStatus.adminRejected.name,
        'status': BookingStatus.rejected.name,
        'rejectionReason': reason,
      });

      _error = null;
      notifyListeners();

      debugPrint('[BOOKING][ADMIN] Rejected restricted booking $bookingId');
      return true;
    } catch (e) {
      _error = 'Lỗi từ chối booking: $e';
      notifyListeners();
      return false;
    }
  }

  // Helper methods
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Extension for UserBookingStats copyWith
extension UserBookingStatsExtension on UserBookingStats {
  UserBookingStats copyWith({
    String? userId,
    int? quickBookingsToday,
    int? violationsLast7Days,
    bool? isRestricted,
    DateTime? restrictedAt,
    DateTime? lastViolationAt,
  }) {
    return UserBookingStats(
      userId: userId ?? this.userId,
      quickBookingsToday: quickBookingsToday ?? this.quickBookingsToday,
      violationsLast7Days: violationsLast7Days ?? this.violationsLast7Days,
      isRestricted: isRestricted ?? this.isRestricted,
      restrictedAt: restrictedAt ?? this.restrictedAt,
      lastViolationAt: lastViolationAt ?? this.lastViolationAt,
    );
  }
}
