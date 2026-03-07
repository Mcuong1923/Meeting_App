import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/meeting_decision_model.dart';
import '../models/meeting_task_model.dart';
import '../models/meeting_comment_model.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class MeetingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log Firebase configuration when provider is created
  MeetingProvider() {
    try {
      final firebaseApp = Firebase.app();
      print(
          '[MEETING_PROVIDER] Firebase Project ID: ${firebaseApp.options.projectId}');
      print(
          '[MEETING_PROVIDER] Firebase Database URL: ${firebaseApp.options.databaseURL}');
    } catch (e) {
      print('[MEETING_PROVIDER] Error getting Firebase config: $e');
    }
  }

  List<MeetingModel> _meetings = [];
  List<MeetingModel> _pendingMeetings = [];
  List<MeetingModel> _myMeetings = [];
  List<MeetingDecision> _decisions = []; // Current meeting decisions
  List<MeetingTask> _tasks = []; // Current meeting tasks
  List<MeetingComment> _comments = []; // Current meeting comments
  bool _isLoading = false;
  bool _isLoadingComments = false;
  String? _error;
  String? _commentsError;

  // Debug: Track request tokens and active meetingId
  int _loadDecisionsToken = 0;
  int _loadTasksToken = 0;
  int _loadCommentsToken = 0;
  String? _activeMeetingId;

  List<MeetingModel> get meetings => _meetings;
  List<MeetingModel> get pendingMeetings => _pendingMeetings;
  List<MeetingModel> get myMeetings => _myMeetings;
  List<MeetingDecision> get decisions => _decisions;
  List<MeetingTask> get tasks => _tasks;
  List<MeetingComment> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isLoadingComments => _isLoadingComments;
  String? get error => _error;
  String? get commentsError => _commentsError;

  // Get tasks filtered by meetingId
  List<MeetingTask> getTasksForMeeting(String meetingId) {
    return _tasks.where((task) => task.meetingId == meetingId).toList();
  }

  String get providerHash => hashCode.toRadixString(16);

  // Load tất cả cuộc họp (theo quyền)
  Future<void> loadMeetings(UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore.collection('meetings');

      // Lọc theo quyền
      if (currentUser.isSuperAdmin) {
        // Super Admin: xem tất cả
        query = query.orderBy('createdAt', descending: true);
      } else if (currentUser.isAdmin) {
        // Admin: xem cuộc họp của phòng ban
        query = query
            .where('departmentId', isEqualTo: currentUser.departmentId)
            .orderBy('createdAt', descending: true);
      } else if (currentUser.isManager) {
        // Manager: xem cuộc họp của team
        query = query.where('creatorId', whereIn: [
          currentUser.id,
          ...currentUser.teamIds
        ]).orderBy('createdAt', descending: true);
      } else {
        // Employee/Guest: chỉ xem cuộc họp của mình
        query = query
            .where('creatorId', isEqualTo: currentUser.id)
            .orderBy('createdAt', descending: true);
      }

      QuerySnapshot snapshot = await query.get();
      _meetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Load cuộc họp chờ phê duyệt
      await _loadPendingMeetings(currentUser);

      // Load cuộc họp của tôi
      await _loadMyMeetings(currentUser);
    } catch (e) {
      _error = 'Lỗi tải danh sách cuộc họp: $e';
      print('Error loading meetings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load cuộc họp chờ phê duyệt
  Future<void> _loadPendingMeetings(UserModel currentUser) async {
    try {
      Query query = _firestore.collection('meetings').where('status',
          isEqualTo: MeetingStatus.pending.toString().split('.').last);

      if (currentUser.isSuperAdmin) {
        // Super Admin: xem tất cả cuộc họp chờ phê duyệt
      } else if (currentUser.isAdmin) {
        // Admin: xem cuộc họp chờ phê duyệt của phòng ban
        query =
            query.where('departmentId', isEqualTo: currentUser.departmentId);
      } else if (currentUser.isManager) {
        // Manager: xem cuộc họp chờ phê duyệt của team
        query = query.where('creatorId',
            whereIn: [currentUser.id, ...currentUser.teamIds]);
      } else {
        // Employee: chỉ xem cuộc họp chờ phê duyệt của mình
        query = query.where('creatorId', isEqualTo: currentUser.id);
      }

      QuerySnapshot snapshot = await query.get();
      _pendingMeetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error loading pending meetings: $e');
    }
  }

  // Load cuộc họp của tôi
  Future<void> _loadMyMeetings(UserModel currentUser) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('creatorId', isEqualTo: currentUser.id)
          .orderBy('createdAt', descending: true)
          .get();

      _myMeetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error loading my meetings: $e');
    }
  }

  // ==================== Room Booking Validation ====================

  /// TTL for pending meetings in minutes (configurable)
  /// After this time, pending meetings auto-expire and release the room
  static const int pendingMeetingTTLMinutes = 30;

  /// Inactive statuses that should NOT block room booking (exclude-list approach)
  /// This handles legacy data and status inconsistencies better than allow-list
  static const List<String> _inactiveMeetingStatuses = [
    'cancelled',
    'rejected',
    'expired',
    'completed',
  ];

  /// Check if a room has conflicting meetings in the given time range
  /// Implements Option A: Pending meetings reserve room with TTL
  ///
  /// Conflict rules:
  /// - Blocks if overlap with approved meeting
  /// - Blocks if overlap with pending meeting that has NOT expired (expiresAt > now)
  /// - Does NOT block if: rejected, cancelled, expired, or pending with expired TTL
  ///
  /// Returns list of conflicting meetings (with conflict type info)
  Future<List<MeetingModel>> checkRoomConflict({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeMeetingId, // Exclude this meeting when updating
  }) async {
    try {
      final now = DateTime.now();
      print('[BOOKING][CONFLICT_CHECK] START');
      print(
          '[BOOKING][CONFLICT_CHECK] roomId=$roomId (length=${roomId.length}, isDocId=${roomId.length > 10})');
      print('[BOOKING][CONFLICT_CHECK] start=$startTime end=$endTime now=$now');
      print('[BOOKING][CONFLICT_CHECK] excludeMeetingId=$excludeMeetingId');

      // Use exclude-list approach: Get all meetings for this room, then filter out inactive ones
      // This handles legacy data and status inconsistencies better
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('roomId', isEqualTo: roomId)
          .get();

      print(
          '[BOOKING][CONFLICT_CHECK] Query returned ${snapshot.docs.length} total meetings for roomId=$roomId');

      List<MeetingModel> conflictingMeetings = [];
      List<String> expiredMeetingIds =
          []; // Track expired meetings for lazy update
      int skippedInactive = 0;
      int skippedExpired = 0;
      int skippedNoRoomId = 0;

      for (var doc in snapshot.docs) {
        // Skip the meeting being updated
        if (excludeMeetingId != null && doc.id == excludeMeetingId) {
          print(
              '[BOOKING][CONFLICT_CHECK] Skipping excluded meeting: ${doc.id}');
          continue;
        }

        final data = doc.data() as Map<String, dynamic>;
        final statusStr = (data['status'] ?? '').toString().toLowerCase();

        // Exclude inactive statuses (exclude-list approach)
        if (_inactiveMeetingStatuses.contains(statusStr)) {
          skippedInactive++;
          print(
              '[BOOKING][CONFLICT_CHECK] Skipping inactive meeting: ${doc.id} status=$statusStr');
          continue;
        }

        MeetingModel existing = MeetingModel.fromMap(data, doc.id);

        // Handle legacy data: if no roomId but has physicalLocation, compare by location
        if (existing.roomId == null || existing.roomId!.isEmpty) {
          // Fallback: compare by physicalLocation or roomName if available
          final physicalLocation = existing.physicalLocation ?? '';
          final roomName = existing.roomName ?? '';
          // For now, skip meetings without roomId (they won't conflict with roomId-based queries)
          // TODO: If needed, implement location-based matching
          skippedNoRoomId++;
          print(
              '[BOOKING][CONFLICT_CHECK] Skipping meeting without roomId: ${doc.id} physicalLocation=$physicalLocation');
          continue;
        }

        // Check if pending meeting has expired (lazy expiration check)
        if (existing.status == MeetingStatus.pending) {
          if (existing.isPendingExpired) {
            print(
                '[BOOKING][TTL_EXPIRED] meetingId=${existing.id} expiresAt=${existing.expiresAt} - marking for lazy update');
            expiredMeetingIds.add(existing.id);
            skippedExpired++;
            continue; // Skip expired pending meetings - they don't block
          }
        }

        // Handle status inconsistency: if status=approved but approvalStatus=pending, treat as active
        final approvalStatusStr =
            (data['approvalStatus'] ?? '').toString().toLowerCase();
        if (statusStr == 'approved' && approvalStatusStr == 'pending') {
          print(
              '[BOOKING][CONFLICT_CHECK] WARNING: Meeting ${doc.id} has inconsistent status: status=approved but approvalStatus=pending - treating as active');
        }

        // Check time overlap: existing.start < newEnd AND existing.end > newStart
        // Edge case: end == start is NOT a conflict (touching boundaries OK)
        bool hasTimeOverlap = existing.startTime.isBefore(endTime) &&
            existing.endTime.isAfter(startTime);

        if (hasTimeOverlap) {
          print(
              '[BOOKING][CONFLICT_FOUND] meetingId=${existing.id} status=${existing.status} '
              'title="${existing.title}" '
              'range=${existing.startTime}-${existing.endTime}');
          conflictingMeetings.add(existing);
        }
      }

      // Lazy expiration: Update expired meetings to status=expired (best-effort, non-blocking)
      if (expiredMeetingIds.isNotEmpty) {
        _lazyExpireMeetings(expiredMeetingIds);
      }

      print(
          '[BOOKING][CONFLICT_CHECK] RESULT: ${conflictingMeetings.length} active conflicts found');
      print(
          '[BOOKING][CONFLICT_CHECK] Skipped: $skippedInactive inactive, $skippedExpired expired, $skippedNoRoomId no roomId');
      if (conflictingMeetings.isNotEmpty) {
        final firstConflict = conflictingMeetings.first;
        print(
            '[BOOKING][CONFLICT_CHECK] Sample conflict: id=${firstConflict.id} '
            'roomId=${firstConflict.roomId} physicalLocation=${firstConflict.physicalLocation} '
            'start=${firstConflict.startTime} end=${firstConflict.endTime} '
            'status=${firstConflict.status} approvalStatus=${firstConflict.approvalStatus}');
      }
      return conflictingMeetings;
    } catch (e) {
      final errorStr = e.toString();
      print('[BOOKING][CONFLICT_CHECK] ERROR: $e');
      print('[BOOKING][CONFLICT_CHECK] Stack trace: ${StackTrace.current}');

      // Handle index error - don't silently return empty, fail hard with clear message
      if (errorStr.contains('requires an index') ||
          errorStr.contains('FAILED_PRECONDITION')) {
        print('[BOOKING][CONFLICT_CHECK] ❌ INDEX REQUIRED ERROR');
        print(
            '[BOOKING][CONFLICT_CHECK] Query requires Firestore index. Check error message for index creation link.');
        // Don't return empty - throw error so user knows they need to create index
        throw Exception(
            'Conflict check requires Firestore index. Please create the required index. Error: $errorStr');
      }

      // For other errors, return empty but log clearly
      print(
          '[BOOKING][CONFLICT_CHECK] ⚠️ Returning empty conflicts due to error');
      return [];
    }
  }

  /// Lazy expiration: Mark expired pending meetings as expired (best-effort)
  /// Runs asynchronously without blocking the main flow
  Future<void> _lazyExpireMeetings(List<String> meetingIds) async {
    try {
      print('[BOOKING][LAZY_EXPIRE] Expiring ${meetingIds.length} meetings');

      WriteBatch batch = _firestore.batch();
      for (String meetingId in meetingIds) {
        batch.update(
          _firestore.collection('meetings').doc(meetingId),
          {
            'status': 'expired',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      await batch.commit();

      print(
          '[BOOKING][LAZY_EXPIRE] Successfully expired ${meetingIds.length} meetings');
    } catch (e) {
      // Non-blocking - just log the error
      print('[BOOKING][LAZY_EXPIRE] ERROR (non-blocking): $e');
    }
  }

  /// Validate room booking before creating/updating meeting
  /// Checks BOTH meetings collection AND room_bookings collection
  /// Returns error message if invalid, null if valid
  ///
  /// Error messages:
  /// - Pending conflict: "Phòng đang được giữ chỗ (chờ duyệt) đến {expiresAt}"
  /// - Approved conflict: "Phòng đã được đặt cho cuộc họp từ {start}-{end}"
  Future<String?> validateRoomBooking({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeMeetingId,
  }) async {
    print('[BOOKING][VALIDATE] START');
    print(
        '[BOOKING][VALIDATE] roomId=$roomId (length=${roomId.length}, isDocId=${roomId.length > 10})');
    print('[BOOKING][VALIDATE] start=$startTime end=$endTime');
    print('[BOOKING][VALIDATE] excludeMeetingId=$excludeMeetingId');

    // Check conflicts in meetings collection
    List<MeetingModel> meetingConflicts = await checkRoomConflict(
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
      excludeMeetingId: excludeMeetingId,
    );

    // Check conflicts in room_bookings collection (using same roomId format)
    List<Map<String, dynamic>> bookingConflicts =
        await _checkRoomBookingsConflict(
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
    );

    print(
        '[BOOKING][VALIDATE] RESULT: meetingConflicts=${meetingConflicts.length} bookingConflicts=${bookingConflicts.length}');

    // Combine all conflicts
    if (meetingConflicts.isEmpty && bookingConflicts.isEmpty) {
      print('[BOOKING][VALIDATE] No conflicts found');
      return null; // No error = valid
    }

    // Format time for display
    String formatTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // Prioritize meeting conflicts (more specific)
    if (meetingConflicts.isNotEmpty) {
      MeetingModel conflict = meetingConflicts.first;
      String conflictTimeRange =
          '${formatTime(conflict.startTime)} - ${formatTime(conflict.endTime)}';

      if (conflict.status == MeetingStatus.pending) {
        String expiresAtStr = conflict.expiresAt != null
            ? '${formatTime(conflict.expiresAt!)} ngày ${conflict.expiresAt!.day}/${conflict.expiresAt!.month}'
            : 'không xác định';
        return 'Phòng đang được giữ chỗ (chờ duyệt) đến $expiresAtStr.\n'
            'Vui lòng thử lại sau hoặc chọn phòng khác.';
      } else {
        return 'Phòng đã được đặt từ $conflictTimeRange cho cuộc họp "${conflict.title}".';
      }
    }

    // Handle room_bookings conflicts
    if (bookingConflicts.isNotEmpty) {
      final conflict = bookingConflicts.first;
      final conflictStart = (conflict['startTime'] as Timestamp).toDate();
      final conflictEnd = (conflict['endTime'] as Timestamp).toDate();
      final conflictTitle = conflict['title'] ?? 'cuộc họp';
      final conflictStatus = conflict['status'] ?? 'approved';

      String conflictTimeRange =
          '${formatTime(conflictStart)} - ${formatTime(conflictEnd)}';

      if (conflictStatus == 'pending' || conflictStatus == 'reserved') {
        return 'Phòng đang được giữ chỗ từ $conflictTimeRange.\n'
            'Vui lòng thử lại sau hoặc chọn phòng khác.';
      } else {
        return 'Phòng đã được đặt từ $conflictTimeRange cho "$conflictTitle".';
      }
    }

    return null;
  }

  /// Inactive statuses for room_bookings that should NOT block room booking (exclude-list approach)
  static const List<String> _inactiveBookingStatuses = [
    'cancelled',
    'rejected',
    'releasedBySystem',
    'completed',
  ];

  /// Check conflicts in room_bookings collection
  Future<List<Map<String, dynamic>>> _checkRoomBookingsConflict({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      print('[BOOKING][CHECK_BOOKINGS] START');
      print(
          '[BOOKING][CHECK_BOOKINGS] roomId=$roomId (length=${roomId.length}, isDocId=${roomId.length > 10})');
      print('[BOOKING][CHECK_BOOKINGS] start=$startTime end=$endTime');

      // Use exclude-list approach: Get all bookings for this room, then filter out inactive ones
      // This handles legacy data and status inconsistencies better
      final snapshot = await _firestore
          .collection('room_bookings')
          .where('roomId', isEqualTo: roomId)
          .get();

      print(
          '[BOOKING][CHECK_BOOKINGS] Query returned ${snapshot.docs.length} total bookings for roomId=$roomId');

      List<Map<String, dynamic>> conflicts = [];
      int skippedInactive = 0;
      int skippedNoRoomId = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final statusStr = (data['status'] ?? '').toString().toLowerCase();

        // Exclude inactive statuses (exclude-list approach)
        if (_inactiveBookingStatuses.contains(statusStr)) {
          skippedInactive++;
          print(
              '[BOOKING][CHECK_BOOKINGS] Skipping inactive booking: ${doc.id} status=$statusStr');
          continue;
        }

        // Handle legacy data: if no roomId, skip (won't conflict with roomId-based queries)
        final bookingRoomId = data['roomId'] ?? '';
        if (bookingRoomId.isEmpty) {
          skippedNoRoomId++;
          print(
              '[BOOKING][CHECK_BOOKINGS] Skipping booking without roomId: ${doc.id}');
          continue;
        }

        final bookingStart = (data['startTime'] as Timestamp).toDate();
        final bookingEnd = (data['endTime'] as Timestamp).toDate();
        final bookingStatus = data['status'] ?? 'unknown';

        // Check overlap: bookingStart < endTime AND bookingEnd > startTime
        // Edge case: end == start is NOT a conflict (touching boundaries OK)
        bool hasOverlap =
            bookingStart.isBefore(endTime) && bookingEnd.isAfter(startTime);

        if (hasOverlap) {
          print(
              '[BOOKING][CONFLICT_BOOKING] Found conflict: bookingId=${doc.id} '
              'status=$bookingStatus '
              'start=$bookingStart end=$bookingEnd');
          conflicts.add({
            ...data,
            'id': doc.id,
          });
        }
      }

      print(
          '[BOOKING][CHECK_BOOKINGS] RESULT: Found ${conflicts.length} conflicts in room_bookings');
      print(
          '[BOOKING][CHECK_BOOKINGS] Skipped: $skippedInactive inactive, $skippedNoRoomId no roomId');
      if (conflicts.isNotEmpty) {
        final firstConflict = conflicts.first;
        print(
            '[BOOKING][CHECK_BOOKINGS] Sample conflict: id=${firstConflict['id']} '
            'roomId=${firstConflict['roomId']} roomName=${firstConflict['roomName']} '
            'start=${firstConflict['startTime']} end=${firstConflict['endTime']} '
            'status=${firstConflict['status']}');
      }
      return conflicts;
    } catch (e) {
      final errorStr = e.toString();
      print('[BOOKING][CHECK_BOOKINGS] ERROR: $e');
      print('[BOOKING][CHECK_BOOKINGS] Stack trace: ${StackTrace.current}');

      // Handle index error - don't silently return empty, fail hard with clear message
      if (errorStr.contains('requires an index') ||
          errorStr.contains('FAILED_PRECONDITION')) {
        print('[BOOKING][CHECK_BOOKINGS] ❌ INDEX REQUIRED ERROR');
        print(
            '[BOOKING][CHECK_BOOKINGS] Query requires Firestore index. Check error message for index creation link.');
        // Don't return empty - throw error so user knows they need to create index
        throw Exception(
            'Conflict check requires Firestore index. Please create the required index. Error: $errorStr');
      }

      // For other errors, return empty but log clearly
      print(
          '[BOOKING][CHECK_BOOKINGS] ⚠️ Returning empty conflicts due to error');
      return [];
    }
  }

  /// Get room availability status for a specific time range
  /// Checks BOTH meetings AND room_bookings collections
  /// Returns map with room statuses for UI display
  Future<Map<String, RoomBookingStatus>> getRoomAvailabilityForTimeRange({
    required DateTime startTime,
    required DateTime endTime,
    required List<String> roomIds,
  }) async {
    Map<String, RoomBookingStatus> result = {};

    for (String roomId in roomIds) {
      result[roomId] = RoomBookingStatus.available;
    }

    try {
      // Query all meetings for these rooms (using exclude-list approach)
      // Note: Firestore limit is 10 items in whereIn, so we may need to batch
      List<String> roomIdsBatch = roomIds.take(10).toList();
      if (roomIdsBatch.isNotEmpty) {
        QuerySnapshot meetingsSnapshot = await _firestore
            .collection('meetings')
            .where('roomId', whereIn: roomIdsBatch)
            .get();

        for (var doc in meetingsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final statusStr = (data['status'] ?? '').toString().toLowerCase();

          // Exclude inactive statuses (exclude-list approach)
          if (_inactiveMeetingStatuses.contains(statusStr)) {
            continue;
          }

          MeetingModel meeting = MeetingModel.fromMap(data, doc.id);

          String roomId = meeting.roomId ?? '';
          if (roomId.isEmpty) continue;

          // Skip expired pending meetings
          if (meeting.status == MeetingStatus.pending &&
              meeting.isPendingExpired) {
            continue;
          }

          // Check time overlap: meetingStart < endTime AND meetingEnd > startTime
          bool hasOverlap = meeting.startTime.isBefore(endTime) &&
              meeting.endTime.isAfter(startTime);

          if (hasOverlap) {
            if (meeting.status == MeetingStatus.approved) {
              result[roomId] = RoomBookingStatus.booked;
            } else if (meeting.status == MeetingStatus.pending) {
              // Only set to pending if not already booked
              if (result[roomId] != RoomBookingStatus.booked) {
                result[roomId] = RoomBookingStatus.pendingReserved;
              }
            }
          }
        }
      }

      // Also check room_bookings collection
      for (String roomId in roomIds) {
        // Skip if already marked as booked
        if (result[roomId] == RoomBookingStatus.booked) continue;

        List<Map<String, dynamic>> bookingConflicts =
            await _checkRoomBookingsConflict(
          roomId: roomId,
          startTime: startTime,
          endTime: endTime,
        );

        if (bookingConflicts.isNotEmpty) {
          final conflict = bookingConflicts.first;
          final status = conflict['status'] ?? 'approved';

          if (status == 'approved' || status == 'converted') {
            result[roomId] = RoomBookingStatus.booked;
          } else if (status == 'pending' || status == 'reserved') {
            // Only set to pending if not already booked
            if (result[roomId] != RoomBookingStatus.booked) {
              result[roomId] = RoomBookingStatus.pendingReserved;
            }
          }
        }
      }
    } catch (e) {
      print('[BOOKING][AVAILABILITY] ERROR: $e');
    }

    return result;
  }

  /// Lấy lịch trình của một phòng trong 1 khoảng thời gian (để hiển thị timeline)
  Future<List<Map<String, dynamic>>> getRoomSchedule(
      String roomId, DateTime dayStart, DateTime dayEnd) async {
    List<Map<String, dynamic>> schedule = [];
    try {
      // 1. Lấy lịch từ meetings
      QuerySnapshot meetingsSnapshot = await _firestore
          .collection('meetings')
          .where('roomId', isEqualTo: roomId)
          .get();

      for (var doc in meetingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final statusStr = (data['status'] ?? '').toString().toLowerCase();
        if (_inactiveMeetingStatuses.contains(statusStr)) continue;

        MeetingModel meeting = MeetingModel.fromMap(data, doc.id);
        if (meeting.status == MeetingStatus.pending && meeting.isPendingExpired) {
          continue;
        }

        if (meeting.startTime.isBefore(dayEnd) &&
            meeting.endTime.isAfter(dayStart)) {
          schedule.add({
            'start': meeting.startTime,
            'end': meeting.endTime,
            'status':
                meeting.status == MeetingStatus.approved ? 'booked' : 'pending',
            'source': 'meeting',
            'title': meeting.title,
          });
        }
      }

      // 2. Lấy lịch từ room_bookings
      QuerySnapshot bookingsSnapshot = await _firestore
          .collection('room_bookings')
          .where('roomId', isEqualTo: roomId)
          .get();

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final statusStr = (data['status'] ?? '').toString().toLowerCase();
        if (_inactiveBookingStatuses.contains(statusStr)) continue;

        final bookingStart = (data['startTime'] as Timestamp).toDate();
        final bookingEnd = (data['endTime'] as Timestamp).toDate();
        final title = data['title'] ?? 'Đã đặt phòng';

        if (bookingStart.isBefore(dayEnd) && bookingEnd.isAfter(dayStart)) {
          schedule.add({
            'start': bookingStart,
            'end': bookingEnd,
            'status': (statusStr == 'approved' || statusStr == 'converted')
                ? 'booked'
                : 'pending',
            'source': 'booking',
            'title': title,
          });
        }
      }

      // Sort: Sớm nhất lên đầu
      schedule.sort(
          (a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));
      print(
          '[TIMELINE] Lấy lịch của phòng $roomId (${schedule.length} blocks)');
    } catch (e) {
      print('[TIMELINE] getRoomSchedule LỖI: $e');
    }
    return schedule;
  }

  // Tạo cuộc họp mới
  Future<MeetingModel?> createMeeting(MeetingModel meeting,
      UserModel currentUser, NotificationProvider? notificationProvider) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validate: Cannot create meeting in the past (with 5 minutes grace period)
      final now = DateTime.now();
      const gracePeriod = Duration(minutes: 5);
      final minStartTime = now.subtract(gracePeriod);

      if (meeting.startTime.isBefore(minStartTime)) {
        final errorMsg =
            'Không thể tạo cuộc họp trong quá khứ. Thời gian bắt đầu phải sau ${minStartTime.hour}:${minStartTime.minute.toString().padLeft(2, '0')}';
        print(
            '[MEETING][CREATE] VALIDATION FAILED: startTime=${meeting.startTime} is before minStartTime=$minStartTime');
        throw Exception(errorMsg);
      }

      // Kiểm tra quyền tạo cuộc họp
      if (!currentUser.canCreateMeeting(meeting.type)) {
        throw Exception('Bạn không có quyền tạo cuộc họp loại này');
      }

      // --- LOG INPUT (Diagnose Step 2) ---
      print('[MEETING][CREATE] Input type=${meeting.type}');
      print(
          '[MEETING][CREATE] Input participants=${meeting.participants.map((p) => '{userId:${p.userId}, role:${p.role}, hasConfirmed:${p.hasConfirmed}, attendanceStatus:${p.attendanceStatus.value}}').toList()}');

      // --- START NORMALIZATION (Spec 3.1 & 3.2) ---
      final nowTime = DateTime.now();
      String? secretaryId;

      final normalizedParticipants = meeting.participants.map((p) {
        if (p.userId == currentUser.id) {
          // Creator/Host => accepted always
          return p.copyWith(
            role: 'host',
            attendanceStatus: ParticipantAttendanceStatus.accepted,
            respondedAt: nowTime,
            confirmedAt: nowTime,
          );
        } else {
          // Everyone else => pending
          String r = p.role;
          if (r != 'host' && r != 'secretary') r = 'participant';
          if (r == 'secretary') secretaryId = p.userId;

          return p.copyWith(
            role: r,
            attendanceStatus: ParticipantAttendanceStatus.pending,
            respondedAt: null,
            confirmedAt: null,
          );
        }
      }).toList();

      meeting = meeting.copyWith(
        participants: normalizedParticipants,
        creatorId: currentUser.id,
      );

      print(
          '[MEETING][CREATE] normalizedParticipants=${normalizedParticipants.map((p) => '{userId:${p.userId}, role:${p.role}, status:${p.attendanceStatus.value}}').toList()}');

      // Ensure creator is in participants
      bool isParticipant =
          meeting.participants.any((p) => p.userId == currentUser.id);
      if (!isParticipant) {
        throw Exception('Người tạo phải có mặt trong danh sách tham gia');
      }

      // --- VALIDATE TYPE CONSTRAINTS ---
      if (currentUser.isEmployee) {
        if (meeting.type != MeetingType.personal) {
          throw Exception('Nhân viên chỉ được tạo cuộc họp cá nhân (personal)');
        }
      }
      // Với các loại họp khác personal, bắt buộc phải có thư ký trong participants
      if (meeting.type != MeetingType.personal && secretaryId == null) {
        throw Exception(
          'Cuộc họp loại ${meeting.type.toString().split('.').last} bắt buộc phải có thư ký trong danh sách tham gia',
        );
      }

      // --- DERIVE APPROVAL LEVEL FOR ALL ROLES (Spec 3.4) ---
      MeetingApprovalLevel derivedLevel = MeetingApprovalLevel.team;
      try {
        for (var p in meeting.participants) {
          if (p.userId == currentUser.id) continue;

          var userDoc =
              await _firestore.collection('users').doc(p.userId).get();
          if (userDoc.exists) {
            final deptId = userDoc.data()?['departmentId'];
            final teamId = userDoc.data()?['teamId'];

            if (deptId != currentUser.departmentId) {
              derivedLevel = MeetingApprovalLevel.company;
              break;
            } else if (teamId != currentUser.teamId &&
                derivedLevel != MeetingApprovalLevel.company) {
              derivedLevel = MeetingApprovalLevel.department;
            }
          }
        }
      } catch (e) {
        print('[MEETING][CREATE] Error deriving approval level: $e');
      }

      meeting = meeting.copyWith(approvalLevel: derivedLevel);

      // --- EVALUATE AUTO APPROVE (Spec 3.4) ---
      bool canAutoApprove = false;
      if (currentUser.isSuperAdmin || currentUser.isAdmin) {
        canAutoApprove = true;
      } else if (currentUser.isDirector) {
        canAutoApprove = (derivedLevel == MeetingApprovalLevel.team ||
            derivedLevel == MeetingApprovalLevel.department);
      } else if (currentUser.isManager) {
        canAutoApprove = (derivedLevel == MeetingApprovalLevel.team);
      } else {
        canAutoApprove = false; // Employee always pending
      }

      // Nếu user KHÔNG CÓ quyền tự duyệt (canAutoApprove = false) VÀ mời người ngoài team
      // -> Bắt buộc nhập lý do phê duyệt. 
      // Admin/Director tự duyệt được nên bỏ qua validation này.
      if (!canAutoApprove && meeting.approvalLevel != MeetingApprovalLevel.team) {
        if (meeting.approvalReason == null ||
            meeting.approvalReason!.trim().length < 10) {
          throw Exception(
              'Bắt buộc nhập lý do phê duyệt (tối thiểu 10 ký tự) khi mời người ngoài Team/Phòng ban');
        }
      }

      print(
          '[MEETING][CREATE] role=${currentUser.role} derivedLevel=$derivedLevel canAutoApprove=$canAutoApprove');

      // Set initial status and approval fields
      MeetingStatus initialStatus;
      MeetingApprovalStatus initialApprovalStatus;
      DateTime? approvedAt;
      String? approvedBy;
      String? approverId;
      String? approverName;
      DateTime? expiresAt;

      if (canAutoApprove) {
        // Auto-approve for admin/director/manager within scope
        initialStatus = MeetingStatus.approved;
        initialApprovalStatus = MeetingApprovalStatus.auto_approved;
        approvedAt = DateTime.now();
        approvedBy = currentUser.id;
        approverId = currentUser.id;
        approverName = currentUser.displayName;
        expiresAt = null; // No expiration for approved meetings
        print(
            '[MEETING][CREATE] AUTO-APPROVE: status=$initialStatus approvalStatus=$initialApprovalStatus');
      } else {
        // Pending approval if escalated
        initialStatus = MeetingStatus.pending;
        initialApprovalStatus = MeetingApprovalStatus.pending;
        approvedAt = null;
        approvedBy = null;
        approverId = null;
        approverName = null;
        expiresAt =
            DateTime.now().add(const Duration(minutes: pendingMeetingTTLMinutes));
        print(
            '[MEETING][CREATE] PENDING APPROVAL: status=$initialStatus approvalStatus=$initialApprovalStatus expiresAt=$expiresAt');
      }

      // Check conflicts BEFORE transaction
      // Note: Transaction cannot do queries, so we check before and rely on Firestore
      // security rules + optimistic locking pattern
      if (meeting.locationType == MeetingLocationType.physical ||
          meeting.locationType == MeetingLocationType.hybrid) {
        if (meeting.roomId != null && meeting.roomId!.isNotEmpty) {
          print(
              '[BOOKING][CREATE] Validating roomId=${meeting.roomId} roomName=${meeting.roomName}');
          String? conflictError = await validateRoomBooking(
            roomId: meeting.roomId!,
            startTime: meeting.startTime,
            endTime: meeting.endTime,
          );
          if (conflictError != null) {
            throw Exception(conflictError);
          }
          print('[BOOKING][CREATE] Room booking validated: no conflicts');
        }
      }

      // Create meeting document with proper approval fields
      // Note: Firestore transactions cannot do queries, so we rely on:
      // 1. Pre-validation above (catches most cases)
      // 2. Firestore security rules (if implemented)
      // 3. Optimistic concurrency (retry on conflict)
      DocumentReference docRef = _firestore.collection('meetings').doc();

      // Build meeting data with auto-approve fields if applicable
      final meetingData = {
        ...meeting.toMap(),
        'status': initialStatus.toString().split('.').last,
        'approvalStatus': initialApprovalStatus.toString().split('.').last,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt) : null,
        'approvedBy': approvedBy,
        'approverId': approverId,
        'approverName': approverName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print(
          '[MEETING][CREATE] Final payload: status=${meetingData['status']} approvalStatus=${meetingData['approvalStatus']} approvedBy=${meetingData['approvedBy']}');

      await docRef.set(meetingData);

      // Fetch the created meeting to get server timestamps
      DocumentSnapshot doc = await docRef.get();
      MeetingModel newMeeting = MeetingModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      // Thêm vào danh sách
      _meetings.insert(0, newMeeting);
      _myMeetings.insert(0, newMeeting);

      if (newMeeting.isPending) {
        _pendingMeetings.insert(0, newMeeting);
      }

      // Gửi thông báo phê duyệt nếu cần
      if (newMeeting.isPending) {
        await _sendApprovalRequestToAdmins(newMeeting, notificationProvider);
      }

      // Gửi notifications dựa trên approval status
      print('🔄 MeetingProvider: Attempting to send notifications...');
      print('🔄 NotificationProvider is null: ${notificationProvider == null}');
      print(
          '🔄 Meeting status: ${newMeeting.status}, approvalStatus: ${newMeeting.approvalStatus}');

      if (notificationProvider != null) {
        try {
          // Chỉ gửi invitation cho meeting đã được approve (admin tạo)
          if (newMeeting.approvalStatus ==
                  MeetingApprovalStatus.auto_approved ||
              newMeeting.approvalStatus == MeetingApprovalStatus.approved) {
            print(
                '🔄 Sending participant invitations for auto-approved meeting...');
            await _sendParticipantInvitations(newMeeting, notificationProvider);
            print('✅ Participant invitations sent');
          } else {
            print(
                'ℹ️ Meeting pending approval, skipping participant notifications');
          }
        } catch (e) {
          print('❌ Error sending meeting notifications: $e');
        }
      } else {
        print('❌ NotificationProvider is null!');
      }

      return newMeeting;
    } catch (e) {
      _error = 'Lỗi tạo cuộc họp: $e';
      print('Error creating meeting: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật cuộc họp
  Future<bool> updateMeeting(
      MeetingModel meeting, UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền chỉnh sửa
      if (meeting.creatorId != currentUser.id &&
          !currentUser.isSuperAdmin &&
          !currentUser.isAdmin) {
        throw Exception('Bạn không có quyền chỉnh sửa cuộc họp này');
      }

      // Get existing meeting to check if room/time changed
      DocumentSnapshot existingDoc =
          await _firestore.collection('meetings').doc(meeting.id).get();

      if (!existingDoc.exists) {
        throw Exception('Cuộc họp không tồn tại');
      }

      MeetingModel existingMeeting = MeetingModel.fromMap(
        existingDoc.data() as Map<String, dynamic>,
        meeting.id,
      );

      // Validate: Cannot update meeting to past time (with 5 minutes grace period)
      final now = DateTime.now();
      const gracePeriod = Duration(minutes: 5);
      final minStartTime = now.subtract(gracePeriod);

      if (meeting.startTime.isBefore(minStartTime)) {
        final errorMsg =
            'Không thể cập nhật cuộc họp vào quá khứ. Thời gian bắt đầu phải sau ${minStartTime.hour}:${minStartTime.minute.toString().padLeft(2, '0')}';
        print(
            '[MEETING][UPDATE] VALIDATION FAILED: startTime=${meeting.startTime} is before minStartTime=$minStartTime');
        throw Exception(errorMsg);
      }

      // Check if room or time changed - need to validate conflicts
      bool roomChanged = existingMeeting.roomId != meeting.roomId;
      bool timeChanged = existingMeeting.startTime != meeting.startTime ||
          existingMeeting.endTime != meeting.endTime;

      if ((roomChanged || timeChanged) &&
          (meeting.locationType == MeetingLocationType.physical ||
              meeting.locationType == MeetingLocationType.hybrid)) {
        if (meeting.roomId != null && meeting.roomId!.isNotEmpty) {
          print(
              '[BOOKING][UPDATE] Validating roomId=${meeting.roomId} roomName=${meeting.roomName}');
          // Validate new room/time combination (exclude current meeting)
          String? conflictError = await validateRoomBooking(
            roomId: meeting.roomId!,
            startTime: meeting.startTime,
            endTime: meeting.endTime,
            excludeMeetingId: meeting.id,
          );
          if (conflictError != null) {
            throw Exception(conflictError);
          }
          print('[BOOKING][UPDATE] Room/time change validated: no conflicts');
        }
      }

      // Update meeting
      // Note: Conflicts already checked above before transaction
      await _firestore.collection('meetings').doc(meeting.id).update({
        ...meeting.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meeting.id);
      if (index != -1) {
        _meetings[index] = meeting;
      }

      int myIndex = _myMeetings.indexWhere((m) => m.id == meeting.id);
      if (myIndex != -1) {
        _myMeetings[myIndex] = meeting;
      }

      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật cuộc họp: $e';
      print('Error updating meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa cuộc họp
  Future<bool> deleteMeeting(String meetingId, UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get meeting from Firestore (more reliable than local list)
      DocumentSnapshot doc =
          await _firestore.collection('meetings').doc(meetingId).get();

      if (!doc.exists) {
        throw Exception('Cuộc họp không tồn tại');
      }

      MeetingModel meeting = MeetingModel.fromMap(
        doc.data() as Map<String, dynamic>,
        meetingId,
      );

      // Kiểm tra quyền xóa
      if (meeting.creatorId != currentUser.id &&
          !currentUser.isSuperAdmin &&
          !currentUser.isAdmin) {
        throw Exception('Bạn không có quyền xóa cuộc họp này');
      }

      // Delete meeting and update related bookings
      // Note: Query bookings BEFORE transaction (transaction cannot do queries)
      List<DocumentReference> bookingRefsToUpdate = [];
      if (meeting.roomId != null && meeting.roomId!.isNotEmpty) {
        // Find related bookings BEFORE transaction
        QuerySnapshot bookingsSnapshot = await _firestore
            .collection('room_bookings')
            .where('meetingId', isEqualTo: meetingId)
            .where('status',
                whereIn: ['pending', 'approved', 'reserved']).get();

        bookingRefsToUpdate =
            bookingsSnapshot.docs.map((doc) => doc.reference).toList();
        print(
            '[BOOKING][DELETE] Found ${bookingRefsToUpdate.length} related bookings to cancel');
      }

      // Use transaction to delete meeting and update bookings atomically
      await _firestore.runTransaction((Transaction transaction) async {
        // Delete meeting
        transaction.delete(_firestore.collection('meetings').doc(meetingId));

        // Update bookings to cancelled status (using refs from pre-query)
        for (var bookingRef in bookingRefsToUpdate) {
          transaction.update(
            bookingRef,
            {
              'status': 'cancelled',
              'cancellationReason': 'Cuộc họp đã bị hủy',
              'cancelledAt': FieldValue.serverTimestamp(),
            },
          );
        }
      });

      if (bookingRefsToUpdate.isNotEmpty) {
        print(
            '[BOOKING][DELETE] Updated ${bookingRefsToUpdate.length} related bookings to cancelled');
      }

      // Xóa khỏi danh sách
      _meetings.removeWhere((m) => m.id == meetingId);
      _myMeetings.removeWhere((m) => m.id == meetingId);
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      print('[BOOKING][DELETE] Meeting $meetingId deleted successfully');
      return true;
    } catch (e) {
      _error = 'Lỗi xóa cuộc họp: $e';
      print('Error deleting meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Phê duyệt cuộc họp
  Future<bool> approveMeeting(String meetingId, UserModel approver,
      {String? notes, NotificationProvider? notificationProvider}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền phê duyệt
      if (!approver.hasPermission('approve_meetings') &&
          !approver.isSuperAdmin &&
          !approver.isAdmin &&
          !approver.isManager) {
        throw Exception('Bạn không có quyền phê duyệt cuộc họp');
      }

      // Fetch meeting to check current status
      DocumentSnapshot doc =
          await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) throw Exception('Meeting not found');

      MeetingModel meeting =
          MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Guard: Prevent duplicate approvals
      if (meeting.approvalStatus == MeetingApprovalStatus.approved ||
          meeting.approvalStatus == MeetingApprovalStatus.auto_approved) {
        print('⚠️ Meeting already approved, skipping notification');
        return false;
      }

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.approved.toString().split('.').last,
        'approvalStatus':
            MeetingApprovalStatus.approved.toString().split('.').last,
        'approverId': approver.id,
        'approverName': approver.displayName,
        'approvedBy': approver.id,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch updated meeting
      DocumentSnapshot updatedDoc =
          await _firestore.collection('meetings').doc(meetingId).get();
      MeetingModel approvedMeeting = MeetingModel.fromMap(
        updatedDoc.data() as Map<String, dynamic>,
        updatedDoc.id,
      );

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = approvedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      // Gửi thông báo
      if (notificationProvider != null) {
        // 1. Notify creator
        await notificationProvider.createNotification(
          NotificationTemplate.meetingApproved(
            userId: meeting.creatorId,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            approverName: approver.displayName,
          ),
        );

        // 2. Send invitations to ALL participants
        await _sendParticipantInvitations(
            approvedMeeting, notificationProvider);
      }

      return true;
    } catch (e) {
      _error = 'Lỗi phê duyệt cuộc họp: $e';
      print('Error approving meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Từ chối cuộc họp
  Future<bool> rejectMeeting(String meetingId, UserModel rejector,
      {required String reason,
      NotificationProvider? notificationProvider}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền từ chối
      if (!rejector.hasPermission('approve_meetings') &&
          !rejector.isSuperAdmin &&
          !rejector.isAdmin &&
          !rejector.isManager) {
        throw Exception('Bạn không có quyền từ chối cuộc họp');
      }

      // Fetch meeting
      DocumentSnapshot doc =
          await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) throw Exception('Meeting not found');

      MeetingModel meeting =
          MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.rejected.toString().split('.').last,
        'approvalStatus':
            MeetingApprovalStatus.rejected.toString().split('.').last,
        'rejectedBy': rejector.id,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch updated meeting
      DocumentSnapshot updatedDoc =
          await _firestore.collection('meetings').doc(meetingId).get();
      MeetingModel rejectedMeeting = MeetingModel.fromMap(
        updatedDoc.data() as Map<String, dynamic>,
        updatedDoc.id,
      );

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = rejectedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      // Gửi thông báo cho creator
      if (notificationProvider != null) {
        await notificationProvider.createNotification(
          NotificationTemplate.meetingRejected(
            userId: meeting.creatorId,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            rejectorName: rejector.displayName,
            reason: reason,
          ),
        );
      }

      return true;
    } catch (e) {
      _error = 'Lỗi từ chối cuộc họp: $e';
      print('Error rejecting meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hủy cuộc họp
  Future<bool> cancelMeeting(String meetingId, UserModel currentUser,
      {String? reason}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Tìm cuộc họp
      MeetingModel? meeting = _meetings.firstWhere((m) => m.id == meetingId);

      // Kiểm tra quyền hủy
      if (meeting.creatorId != currentUser.id &&
          !currentUser.isSuperAdmin &&
          !currentUser.isAdmin) {
        throw Exception('Bạn không có quyền hủy cuộc họp này');
      }

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.cancelled.toString().split('.').last,
        'approvalNotes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        MeetingModel updatedMeeting = _meetings[index].copyWith(
          status: MeetingStatus.cancelled,
          approvalNotes: reason,
          updatedAt: DateTime.now(),
        );
        _meetings[index] = updatedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt nếu có
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      return true;
    } catch (e) {
      _error = 'Lỗi hủy cuộc họp: $e';
      print('Error cancelling meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Gửi thông báo phê duyệt
  Future<void> _sendApprovalNotification(
      MeetingModel meeting, UserModel creator) async {
    try {
      // Tìm người phê duyệt
      List<UserModel> approvers = await _getApprovers(creator);

      for (UserModel approver in approvers) {
        await _firestore.collection('notifications').add({
          'userId': approver.id,
          'title': 'Cuộc họp cần phê duyệt',
          'message': 'Cuộc họp "${meeting.title}" cần được phê duyệt',
          'type': 'meeting_approval',
          'meetingId': meeting.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      print('Error sending approval notification: $e');
    }
  }

  // Gửi thông báo kết quả phê duyệt
  Future<void> _sendApprovalResultNotification(
      String meetingId, bool approved, String? notes) async {
    try {
      MeetingModel? meeting = _meetings.firstWhere((m) => m.id == meetingId);

      String title =
          approved ? 'Cuộc họp đã được phê duyệt' : 'Cuộc họp bị từ chối';
      String message = approved
          ? 'Cuộc họp "${meeting.title}" đã được phê duyệt'
          : 'Cuộc họp "${meeting.title}" bị từ chối: $notes';

      await _firestore.collection('notifications').add({
        'userId': meeting.creatorId,
        'title': title,
        'message': message,
        'type': 'meeting_approval_result',
        'meetingId': meetingId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending approval result notification: $e');
    }
  }

  // Lấy danh sách người phê duyệt
  Future<List<UserModel>> _getApprovers(UserModel creator) async {
    try {
      List<UserModel> approvers = [];

      if (creator.isEmployee) {
        // Employee: Manager phê duyệt
        if (creator.managerId != null) {
          DocumentSnapshot managerDoc = await _firestore
              .collection('users')
              .doc(creator.managerId!)
              .get();
          if (managerDoc.exists) {
            approvers.add(UserModel.fromMap(
                managerDoc.data() as Map<String, dynamic>, managerDoc.id));
          }
        }
      } else if (creator.isManager) {
        // Manager: Admin phê duyệt
        QuerySnapshot adminSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: UserRole.admin.toString().split('.').last)
            .where('departmentId', isEqualTo: creator.departmentId)
            .get();

        approvers.addAll(adminSnapshot.docs.map((doc) =>
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      return approvers;
    } catch (e) {
      print('Error getting approvers: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PARTICIPANT ATTENDANCE WORKFLOW
  // ─────────────────────────────────────────────────────────────────────────────

  /// Participant responds to meeting invitation.
  /// Updates only their own attendanceStatus + hasConfirmed + respondedAt.
  /// Uses optimistic local update + Firestore write.
  Future<bool> respondToMeeting({
    required String meetingId,
    required String userId,
    required ParticipantAttendanceStatus status,
  }) async {
    try {
      print('[PARTICIPANT][RESPOND][START] '
          'meetingId=$meetingId userId=$userId status=${status.value}');

      // Use a transaction to safely update only this participant's status.
      final docRef = _firestore.collection('meetings').doc(meetingId);

      MeetingModel? updatedMeeting;

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) {
          throw Exception('Meeting not found');
        }

        final data = snap.data() as Map<String, dynamic>;
        final meeting = MeetingModel.fromMap(data, snap.id);

        final pIndex =
            meeting.participants.indexWhere((p) => p.userId == userId);
        if (pIndex == -1) {
          throw Exception('Bạn không có trong danh sách tham gia');
        }

        final oldP = meeting.participants[pIndex];
        print('[PARTICIPANT][RESPOND][BEFORE] '
            'participant=$oldP attendance=${oldP.attendanceStatus.value}');

        final now = DateTime.now();

        final updatedP = oldP.copyWith(
          attendanceStatus: status,
          respondedAt: now,
          confirmedAt: status == ParticipantAttendanceStatus.accepted
              ? now
              : oldP.confirmedAt,
        );

        final updatedParticipants =
            List<MeetingParticipant>.from(meeting.participants);
        updatedParticipants[pIndex] = updatedP;

        final updateData = {
          'participants': updatedParticipants.map((p) => p.toMap()).toList(),
          'participantIds': updatedParticipants.map((p) => p.userId).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        print('[PARTICIPANT][RESPOND][WRITE] updateKeys=${updateData.keys}');

        tx.update(docRef, updateData);

        updatedMeeting = meeting.copyWith(participants: updatedParticipants);
      });

      // Optimistic local update after successful transaction
      if (updatedMeeting != null) {
        _updateMeetingInLists(
          meetingId,
          (_) => updatedMeeting!,
        );
      }

      print('[PARTICIPANT][RESPOND][SUCCESS] '
          'meetingId=$meetingId userId=$userId status=${status.value}');
      return true;
    } catch (e, st) {
      _error = 'Lỗi cập nhật trạng thái: $e';
      print('[PARTICIPANT][RESPOND][ERROR] $e');
      print(st);
      notifyListeners();
      return false;
    }
  }

  /// Host/Admin changes a participant's meeting role.
  /// Enforces: only one chair at a time.
  Future<bool> updateParticipantRole({
    required String meetingId,
    required String targetUserId,
    required String newRole,
    required UserModel currentUser,
  }) async {
    try {
      // Fetch meeting
      final doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) throw Exception('Meeting not found');

      final meeting =
          MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Permission check: only chair or admin
      final currentP = meeting.participants
          .where((p) => p.userId == currentUser.id)
          .firstOrNull;
      final isHost = currentP?.role == 'chair';
      if (!isHost && !currentUser.isAdmin) {
        throw Exception('Chỉ chủ trì hoặc admin mới được thay đổi vai trò');
      }

      // Find target
      final pIndex =
          meeting.participants.indexWhere((p) => p.userId == targetUserId);
      if (pIndex == -1) throw Exception('Không tìm thấy người tham gia');

      final updatedParticipants =
          List<MeetingParticipant>.from(meeting.participants);

      // If promoting to chair → demote previous chair to participant
      if (newRole == 'chair') {
        for (int i = 0; i < updatedParticipants.length; i++) {
          if (updatedParticipants[i].role == 'chair' && i != pIndex) {
            updatedParticipants[i] =
                updatedParticipants[i].copyWith(role: 'participant');
          }
        }
      }

      updatedParticipants[pIndex] =
          updatedParticipants[pIndex].copyWith(role: newRole);

      await _firestore.collection('meetings').doc(meetingId).update({
        'participants': updatedParticipants.map((p) => p.toMap()).toList(),
        'secretaryId': updatedParticipants
            .where((p) => p.role == 'secretary')
            .map((p) => p.userId)
            .firstOrNull,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _updateMeetingInLists(
          meetingId, (m) => m.copyWith(participants: updatedParticipants));

      print(
          '[PARTICIPANT][ROLE] targetUserId=$targetUserId newRole=$newRole meetingId=$meetingId');
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật vai trò: $e';
      print('[PARTICIPANT][ROLE][ERROR] $e');
      notifyListeners();
      return false;
    }
  }

  /// Helper: update a meeting in all local lists using a transform function
  void _updateMeetingInLists(
      String meetingId, MeetingModel Function(MeetingModel) transform) {
    for (final list in [_meetings, _myMeetings, _pendingMeetings]) {
      final idx = list.indexWhere((m) => m.id == meetingId);
      if (idx != -1) {
        list[idx] = transform(list[idx]);
      }
    }
    notifyListeners();
  }

  // Load decisions for a meeting
  Future<void> loadDecisions(String meetingId) async {
    final token = ++_loadDecisionsToken;
    final now = DateTime.now().toIso8601String();

    print(
        '[DECISION][LOAD][START] meetingId=$meetingId token=$token time=$now');

    try {
      // Clear old decisions immediately to prevent stale data flash
      _decisions = [];
      _activeMeetingId = meetingId;
      _isLoading = true;
      _error = null;
      print(
          '[DECISION][LOAD][CLEAR] meetingId=$meetingId token=$token clearedList=true');
      notifyListeners();

      final queryPath = 'decisions where meetingId==$meetingId';
      print(
          '[DECISION][LOAD][QUERY] meetingId=$meetingId token=$token path="$queryPath"');

      QuerySnapshot snapshot = await _firestore
          .collection('decisions')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();

      final docIds = snapshot.docs.take(3).map((d) => d.id).toList();
      print(
          '[DECISION][LOAD][RESULT] meetingId=$meetingId token=$token count=${snapshot.docs.length} docIds=$docIds');

      // Check if this is still the active request
      if (_activeMeetingId == meetingId && token == _loadDecisionsToken) {
        _decisions = snapshot.docs
            .map((doc) => MeetingDecision.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        print(
            '[DECISION][LOAD][APPLY] meetingId=$meetingId token=$token applied=true activeMeetingId=$_activeMeetingId');

        // DB verification
        print(
            '[DECISION][DB_CHECK] meetingId=$meetingId countFromDB=${snapshot.docs.length} time=${DateTime.now().toIso8601String()}');
      } else {
        print(
            '[DECISION][LOAD][DISCARD] meetingId=$meetingId token=$token reason="stale token" activeToken=$_loadDecisionsToken activeMeetingId=$_activeMeetingId');
      }
    } catch (e) {
      _error = 'Lỗi tải quyết định: $e';
      print(
          '[DECISION][LOAD][ERROR] meetingId=$meetingId token=$token error=$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new decision
  Future<bool> addDecision(MeetingDecision decision) async {
    final now = DateTime.now().toIso8601String();
    const collectionPath = 'decisions';

    print(
        '[DECISION][CREATE][START] meetingId=${decision.meetingId} path="$collectionPath" payloadMeetingId=${decision.meetingId} by=${decision.createdBy} time=$now');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create new decision in Firestore
      DocumentReference docRef = await _firestore.collection('decisions').add({
        ...decision.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '[DECISION][CREATE][SUCCESS] meetingId=${decision.meetingId} docId=${docRef.id} path="$collectionPath/${docRef.id}"');

      // Create a local copy with the new ID for immediate UI update
      MeetingDecision newDecision = decision.copyWith(id: docRef.id);

      // Update local list
      _decisions.insert(0, newDecision);

      // DB verification
      final verifySnapshot = await _firestore
          .collection('decisions')
          .where('meetingId', isEqualTo: decision.meetingId)
          .get();
      print(
          '[DECISION][DB_CHECK] meetingId=${decision.meetingId} countFromDB=${verifySnapshot.docs.length} time=${DateTime.now().toIso8601String()}');

      return true;
    } catch (e) {
      _error = 'Lỗi thêm quyết định: $e';
      print(
          '[DECISION][CREATE][ERROR] meetingId=${decision.meetingId} error=$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a decision
  Future<bool> updateDecision(MeetingDecision decision) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('decisions').doc(decision.id).update({
        ...decision.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      int index = _decisions.indexWhere((d) => d.id == decision.id);
      if (index != -1) {
        _decisions[index] = decision;
      }

      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật quyết định: $e';
      print('Error updating decision: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a decision
  Future<bool> deleteDecision(String decisionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('decisions').doc(decisionId).delete();

      // Update local list
      _decisions.removeWhere((d) => d.id == decisionId);

      return true;
    } catch (e) {
      _error = 'Lỗi xóa quyết định: $e';
      print('Error deleting decision: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear decisions
  void clearDecisions() {
    _decisions = [];
    notifyListeners();
  }

  // --- Tasks Management ---

  // Load tasks for a meeting
  Future<void> loadTasks(String meetingId) async {
    final token = ++_loadTasksToken;
    final now = DateTime.now().toIso8601String();

    print('[TASK][LOAD][START] meetingId=$meetingId token=$token time=$now');

    try {
      // Clear old tasks immediately to prevent stale data flash
      _tasks = [];
      _activeMeetingId = meetingId;
      _isLoading = true;
      _error = null;
      print(
          '[TASK][LOAD][CLEAR] meetingId=$meetingId token=$token clearedList=true');
      notifyListeners();

      final queryPath = 'tasks where meetingId==$meetingId';
      print(
          '[TASK][LOAD][QUERY] meetingId=$meetingId token=$token path="$queryPath"');

      QuerySnapshot snapshot = await _firestore
          .collection('tasks')
          .where('meetingId', isEqualTo: meetingId)
          .get();

      final docIds = snapshot.docs.take(3).map((d) => d.id).toList();
      print(
          '[TASK][LOAD][RESULT] meetingId=$meetingId token=$token count=${snapshot.docs.length} docIds=$docIds');

      // Check if this is still the active request
      if (_activeMeetingId == meetingId && token == _loadTasksToken) {
        _tasks = snapshot.docs
            .map((doc) =>
                MeetingTask.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        // Sort client-side: newest first
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print(
            '[TASK][LOAD][APPLY] meetingId=$meetingId token=$token applied=true count=${_tasks.length} activeMeetingId=$_activeMeetingId');

        // DB verification
        print(
            '[TASK][DB_CHECK] meetingId=$meetingId countFromDB=${snapshot.docs.length} time=${DateTime.now().toIso8601String()}');
      } else {
        print(
            '[TASK][LOAD][DISCARD] meetingId=$meetingId token=$token reason="stale token" activeToken=$_loadTasksToken activeMeetingId=$_activeMeetingId');
      }
    } catch (e) {
      _error = 'Lỗi tải nhiệm vụ: $e';
      print('[TASK][LOAD][ERROR] meetingId=$meetingId token=$token error=$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new task (returns docId on success, null on failure)
  Future<String?> addTask(MeetingTask task) async {
    final now = DateTime.now().toIso8601String();
    const collectionPath = 'tasks';

    print(
        '[TASK][CREATE][START] meetingId=${task.meetingId} path="$collectionPath" payloadMeetingId=${task.meetingId} by=${task.createdBy} time=$now');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create new task in Firestore
      DocumentReference docRef = await _firestore.collection('tasks').add({
        ...task.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '[TASK][CREATE][SUCCESS] meetingId=${task.meetingId} docId=${docRef.id} path="$collectionPath/${docRef.id}"');

      // READBACK - Verify persistence
      DocumentSnapshot createdDoc = await docRef.get();
      if (createdDoc.exists) {
        final data = createdDoc.data() as Map<String, dynamic>;
        print(
            '[TASK][CREATE][READBACK] docId=${docRef.id} meetingId=${data['meetingId']} status=${data['status']} createdAt=${data['createdAt']}');
      } else {
        print(
            '[TASK][CREATE][READBACK] ERROR: Document not found immediately after create!');
      }

      // Create a local copy with the new ID for immediate UI update
      MeetingTask newTask = task.copyWith(id: docRef.id);

      // Update local list
      _tasks.insert(0, newTask);

      // DB verification (Count check)
      final verifySnapshot = await _firestore
          .collection('tasks')
          .where('meetingId', isEqualTo: task.meetingId)
          .get();
      print(
          '[TASK][DB_CHECK] meetingId=${task.meetingId} countFromDB=${verifySnapshot.docs.length} time=${DateTime.now().toIso8601String()}');

      return docRef.id; // Return document ID on success
    } catch (e) {
      _error = 'Lỗi thêm nhiệm vụ: $e';
      print('[TASK][CREATE][ERROR] meetingId=${task.meetingId} error=$e');
      return null; // Return null on failure
    } finally {
      notifyListeners();
    }
  }

  // Update a task
  Future<bool> updateTask(MeetingTask task) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          '[TASK][UPDATE][START] taskId=${task.id} status=${task.status} meetingId=${task.meetingId}');

      await _firestore.collection('tasks').doc(task.id).update({
        ...task.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      int index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        print('[TASK][UPDATE][SUCCESS] Updated local task index=$index');
      }

      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật nhiệm vụ: $e';
      print('[TASK][UPDATE][ERROR] taskId=${task.id} error=$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('[TASK][DELETE][START] taskId=$taskId');

      await _firestore.collection('tasks').doc(taskId).delete();

      // Update local list
      _tasks.removeWhere((t) => t.id == taskId);
      print('[TASK][DELETE][SUCCESS] Removed from local list');

      return true;
    } catch (e) {
      _error = 'Lỗi xóa nhiệm vụ: $e';
      print('[TASK][DELETE][ERROR] taskId=$taskId error=$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Helper Methods (Fix for Bug A) ====================

  /// Fetch meeting directly from Firestore (bypassing local list/filtering)
  /// Includes auto-migration for pending participants on approved meetings
  Future<MeetingModel?> getMeetingById(String meetingId) async {
    try {
      print('🔍 Fetching meeting directly: $meetingId');
      final doc = await _firestore.collection('meetings').doc(meetingId).get();

      if (!doc.exists) {
        print('❌ Meeting not found: $meetingId');
        return null;
      }

      print('✅ Meeting found: $meetingId (Status: ${doc.data()?['status']})');
      MeetingModel meeting =
          MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Auto-migrate pending participants if meeting is approved
      meeting = await _autoMigratePendingParticipants(meeting);

      return meeting;
    } catch (e) {
      print('❌ Error fetching meetingById: $e');
      return null;
    }
  }

  /// Auto-migrate pending participants to accepted for approved meetings
  Future<MeetingModel> _autoMigratePendingParticipants(
      MeetingModel meeting) async {
    // Only migrate if meeting is approved
    if (meeting.status != MeetingStatus.approved &&
        meeting.approvalStatus != MeetingApprovalStatus.approved &&
        meeting.approvalStatus != MeetingApprovalStatus.auto_approved) {
      return meeting;
    }

    // Check if any participants need migration (hasConfirmed == false)
    final pendingParticipants =
        meeting.participants.where((p) => !p.hasConfirmed).toList();

    if (pendingParticipants.isEmpty) {
      print(
          '[PARTICIPANT][MIGRATE] meetingId=${meeting.id} no pending participants');
      return meeting;
    }

    print(
        '[PARTICIPANT][MIGRATE] meetingId=${meeting.id} pending->accepted count=${pendingParticipants.length}');

    try {
      // Create migrated participants list
      final migratedParticipants = meeting.participants.map((p) {
        if (!p.hasConfirmed) {
          print(
              '[PARTICIPANT][MIGRATE] userId=${p.userId} name=${p.userName} pending->accepted');
          return MeetingParticipant(
            userId: p.userId,
            userName: p.userName,
            userEmail: p.userEmail,
            role: p.role,
            isRequired: p.isRequired,
            attendanceStatus: ParticipantAttendanceStatus.accepted,
            confirmedAt: DateTime.now(),
          );
        }
        return p;
      }).toList();

      // Ensure participantIds contains all userIds
      final participantIds = migratedParticipants.map((p) => p.userId).toList();

      // Update Firestore
      await _firestore.collection('meetings').doc(meeting.id).update({
        'participants': migratedParticipants.map((p) => p.toMap()).toList(),
        'participantIds': participantIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '[PARTICIPANT][MIGRATE] meetingId=${meeting.id} migration completed successfully');

      // Return updated meeting
      return meeting.copyWith(participants: migratedParticipants);
    } catch (e) {
      print('[PARTICIPANT][MIGRATE] meetingId=${meeting.id} ERROR: $e');
      // Return original meeting if migration fails
      return meeting;
    }
  }

  // ==================== Helper Methods for Approval Workflow ====================

  /// Send approval request notifications to the precise approver role based on approvalLevel
  Future<void> _sendApprovalRequestToAdmins(
    MeetingModel meeting,
    NotificationProvider? notificationProvider,
  ) async {
    if (notificationProvider == null) return;

    try {
      // Find the creator to know their team/department
      var creatorDoc =
          await _firestore.collection('users').doc(meeting.creatorId).get();
      if (!creatorDoc.exists) return;

      final creatorDeptId = creatorDoc.data()?['departmentId'];
      final creatorTeamId = creatorDoc.data()?['teamId'];

      QuerySnapshot approverSnapshot;

      if (meeting.approvalLevel == MeetingApprovalLevel.team &&
          creatorTeamId != null) {
        approverSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'manager')
            .where('teamId', isEqualTo: creatorTeamId)
            .get();
      } else if (meeting.approvalLevel == MeetingApprovalLevel.department &&
          creatorDeptId != null) {
        approverSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'director')
            .where('departmentId', isEqualTo: creatorDeptId)
            .get();
      } else {
        // Fallback to admin for company level or if other levels missing IDs
        approverSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
      }

      print(
          '🔄 Sending approval requests to ${approverSnapshot.docs.length} approvers at level ${meeting.approvalLevel.name}');

      for (var doc in approverSnapshot.docs) {
        await notificationProvider.createNotification(
          NotificationTemplate.meetingApprovalRequest(
            userId: doc.id,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            creatorName: meeting.creatorName,
          ),
        );
      }

      print('✅ Sent approval requests for: ${meeting.title}');
    } catch (e) {
      print('❌ Error sending approval requests: $e');
    }
  }

  /// Send invitation notifications to all participants
  Future<void> _sendParticipantInvitations(
    MeetingModel meeting,
    NotificationProvider notificationProvider,
  ) async {
    try {
      // Get participant IDs (use latest from meeting)
      List<String> participantIds =
          meeting.participants.map((p) => p.userId).toList();

      print('🔄 Sending invitations to ${participantIds.length} participants');

      for (String participantId in participantIds) {
        await notificationProvider.createNotification(
          NotificationTemplate.meetingInvitation(
            userId: participantId,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            meetingTime: meeting.startTime,
            creatorName: meeting.creatorName,
          ),
        );
      }

      print(
          '✅ Sent invitations to ${participantIds.length} participants for: ${meeting.title}');
    } catch (e) {
      print('❌ Error sending participant invitations: $e');
    }
  }

  // ==================== Task Management ====================

  List<MeetingTask> _allTasks = [];
  List<MeetingTask> get allTasks => _allTasks;

  /// Load all tasks for a specific user (assigned to or created by)
  Future<void> loadAllUserTasks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Loading all tasks for user: $userId');

      // Query 1: Tasks assigned to user
      QuerySnapshot assignedTasksSnapshot = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .get();

      // Query 2: Tasks created by user
      QuerySnapshot createdTasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      // Merge and deduplicate
      Map<String, MeetingTask> taskMap = {};

      for (var doc in assignedTasksSnapshot.docs) {
        taskMap[doc.id] =
            MeetingTask.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in createdTasksSnapshot.docs) {
        if (!taskMap.containsKey(doc.id)) {
          taskMap[doc.id] =
              MeetingTask.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      _allTasks = taskMap.values.toList();

      // Sort: Completed last, then by deadline
      _allTasks.sort((a, b) {
        if (a.status == MeetingTaskStatus.completed &&
            b.status != MeetingTaskStatus.completed) {
          return 1;
        }
        if (a.status != MeetingTaskStatus.completed &&
            b.status == MeetingTaskStatus.completed) {
          return -1;
        }
        return a.deadline.compareTo(b.deadline);
      });

      print('✅ Loaded ${_allTasks.length} total tasks for user $userId');
    } catch (e) {
      _error = 'Lỗi tải danh sách công việc: $e';
      print('❌ Error loading all tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load comments for a meeting
  Future<void> loadComments(String meetingId) async {
    final token = ++_loadCommentsToken;

    // Log project info
    final projectId = _firestore.app.options.projectId;
    final appName = _firestore.app.name;

    // Log exact Firestore path
    final collectionPath = 'meetings/$meetingId/comments';
    final fullPath =
        'projects/$projectId/databases/(default)/documents/$collectionPath';

    print('═══════════════════════════════════════════════════════════');
    print('[MEETING_PROVIDER][loadComments] START');
    print('[MEETING_PROVIDER][loadComments] meetingId=$meetingId token=$token');
    print('[MEETING_PROVIDER][loadComments] Firebase Project ID: $projectId');
    print('[MEETING_PROVIDER][loadComments] Firebase App Name: $appName');
    print('[MEETING_PROVIDER][loadComments] Collection Path: $collectionPath');
    print('[MEETING_PROVIDER][loadComments] Full Firestore Path: $fullPath');
    print(
        '[MEETING_PROVIDER][loadComments] Query: .collection("meetings").doc("$meetingId").collection("comments").orderBy("createdAt")');
    print('═══════════════════════════════════════════════════════════');

    try {
      _isLoadingComments = true;
      _commentsError = null;
      notifyListeners();

      final query = _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('comments')
          .orderBy('createdAt', descending: false);

      print('[MEETING_PROVIDER][loadComments] Executing query...');
      final snapshot = await query.get();

      if (token != _loadCommentsToken) {
        print(
            '[MEETING_PROVIDER][loadComments] CANCELLED (newer request) token=$token');
        return;
      }

      _comments = snapshot.docs
          .map((doc) => MeetingComment.fromMap(doc.data(), doc.id))
          .toList();

      print('[MEETING_PROVIDER][loadComments] SUCCESS');
      print(
          '[MEETING_PROVIDER][loadComments] Loaded ${_comments.length} comments');
      print(
          '[MEETING_PROVIDER][loadComments] Document IDs: ${snapshot.docs.map((d) => d.id).toList()}');
    } catch (e) {
      if (token != _loadCommentsToken) {
        print(
            '[MEETING_PROVIDER][loadComments] ERROR but cancelled token=$token');
        return;
      }

      // Handle permission-denied error specifically
      String errorMessage = 'Lỗi tải bình luận: $e';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Bạn không có quyền xem bình luận của cuộc họp này.';
      }

      _commentsError = errorMessage;
      print('[MEETING_PROVIDER][loadComments] ERROR: $e');
      print('[MEETING_PROVIDER][loadComments] Error type: ${e.runtimeType}');
      print('[MEETING_PROVIDER][loadComments] Error toString: ${e.toString()}');
      if (e.toString().contains('permission-denied')) {
        print(
            '[MEETING_PROVIDER][loadComments] ⚠️ PERMISSION DENIED - Check Firestore rules for path: $collectionPath');
      }
      // Don't clear comments on error, keep existing ones
    } finally {
      if (token == _loadCommentsToken) {
        _isLoadingComments = false;
        notifyListeners();
      }
    }
  }

  // Save a new comment
  Future<MeetingComment?> saveComment(
    String meetingId,
    String content,
    String authorId,
    String authorName,
    String? authorAvatar,
  ) async {
    // Log project info
    final projectId = _firestore.app.options.projectId;
    final appName = _firestore.app.name;

    // Log exact Firestore path
    final collectionPath = 'meetings/$meetingId/comments';
    final fullPath =
        'projects/$projectId/databases/(default)/documents/$collectionPath';

    print('═══════════════════════════════════════════════════════════');
    print('[MEETING_PROVIDER][saveComment] START');
    print(
        '[MEETING_PROVIDER][saveComment] meetingId=$meetingId authorId=$authorId');
    print('[MEETING_PROVIDER][saveComment] Firebase Project ID: $projectId');
    print('[MEETING_PROVIDER][saveComment] Firebase App Name: $appName');
    print('[MEETING_PROVIDER][saveComment] Collection Path: $collectionPath');
    print('[MEETING_PROVIDER][saveComment] Full Firestore Path: $fullPath');
    print('[MEETING_PROVIDER][saveComment] Content length: ${content.length}');
    print(
        '[MEETING_PROVIDER][saveComment] Query: .collection("meetings").doc("$meetingId").collection("comments").doc()');
    print('═══════════════════════════════════════════════════════════');

    // Validate input
    if (content.trim().isEmpty) {
      _commentsError = 'Nội dung bình luận không được để trống';
      print('[MEETING_PROVIDER][saveComment] ERROR: Empty content');
      notifyListeners();
      return null;
    }

    if (authorId.isEmpty) {
      _commentsError = 'Không xác định được người gửi. Vui lòng đăng nhập lại.';
      print('[MEETING_PROVIDER][saveComment] ERROR: Empty authorId');
      notifyListeners();
      return null;
    }

    try {
      final now = DateTime.now();
      final commentRef = _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('comments')
          .doc();

      final newComment = MeetingComment(
        id: commentRef.id,
        meetingId: meetingId,
        content: content.trim(),
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        createdAt: now,
        updatedAt: now,
      );

      final commentData = newComment.toMap();
      print(
          '[MEETING_PROVIDER][saveComment] Comment document ID: ${commentRef.id}');
      print(
          '[MEETING_PROVIDER][saveComment] Comment data keys: ${commentData.keys.toList()}');
      print('[MEETING_PROVIDER][saveComment] Comment data: $commentData');
      print('[MEETING_PROVIDER][saveComment] Executing set()...');

      await commentRef.set(commentData);

      print('[MEETING_PROVIDER][saveComment] set() completed successfully');

      // Add to local list
      _comments.add(newComment);
      notifyListeners();

      print('[MEETING_PROVIDER][saveComment] SUCCESS');
      print('[MEETING_PROVIDER][saveComment] Comment ID: ${newComment.id}');
      return newComment;
    } catch (e) {
      // Handle permission-denied error specifically
      String errorMessage = 'Lỗi gửi bình luận: $e';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Bạn không có quyền gửi bình luận trong cuộc họp này.';
      }

      _commentsError = errorMessage;
      print('[MEETING_PROVIDER][saveComment] ERROR: $e');
      print('[MEETING_PROVIDER][saveComment] Error type: ${e.runtimeType}');
      print('[MEETING_PROVIDER][saveComment] Error toString: ${e.toString()}');
      if (e.toString().contains('permission-denied')) {
        print(
            '[MEETING_PROVIDER][saveComment] ⚠️ PERMISSION DENIED - Check Firestore rules for path: $collectionPath');
      }
      notifyListeners();
      return null;
    }
  }
}
