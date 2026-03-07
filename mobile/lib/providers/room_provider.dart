import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/room_model.dart';
import '../models/user_model.dart';

class RoomProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RoomModel> _rooms = [];
  List<MaintenanceRecord> _maintenanceRecords = [];
  bool _isLoading = false;
  String _error = '';

  // Real-time occupancy subscription
  StreamSubscription<QuerySnapshot>? _occupancySubscription;
  Timer? _occupancyTimer; // Timer để re-check định kỳ

  // Getters
  List<RoomModel> get rooms => _rooms;
  List<MaintenanceRecord> get maintenanceRecords => _maintenanceRecords;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Lỗi riêng cho maintenance (không ảnh hưởng các tab khác)
  String _maintenanceError = '';
  String get maintenanceError => _maintenanceError;

  // Filtered rooms
  List<RoomModel> get availableRooms =>
      _rooms.where((room) => room.isAvailable).toList();
  List<RoomModel> get occupiedRooms =>
      _rooms.where((room) => room.status == RoomStatus.occupied).toList();
  List<RoomModel> get maintenanceRooms =>
      _rooms.where((room) => room.status == RoomStatus.maintenance).toList();
  List<RoomModel> get disabledRooms =>
      _rooms.where((room) => room.status == RoomStatus.disabled).toList();
  List<RoomModel> get roomsNeedMaintenance =>
      _rooms.where((room) => room.needsMaintenance).toList();

  // Statistics (based on operational status - NOT dynamic occupancy)
  int get totalRooms => _rooms.length;
  int get availableCount => availableRooms.length;
  int get occupiedCount => occupiedRooms.length;
  int get maintenanceCount => maintenanceRooms.length;
  int get disabledCount => disabledRooms.length;
  double get occupancyRate =>
      totalRooms > 0 ? (occupiedCount / totalRooms) * 100 : 0;

  // ==================== Bookable Rooms (for meeting creation) ====================

  /// Rooms that can be booked for meetings
  /// Only rooms with operational status = available (not maintenance/disabled)
  List<RoomModel> get bookableRooms =>
      _rooms.where((room) => room.status == RoomStatus.available).toList();

  int get bookableCount => bookableRooms.length;

  // ==================== Dynamic Occupancy (based on current meetings) ====================

  Map<String, bool> _currentlyOccupied = {};

  /// Số phòng THỰC SỰ đang có meeting diễn ra RIGHT NOW (real-time)
  int get currentlyOccupiedCount => _currentlyOccupied.length;

  /// Check if a room is currently occupied based on ongoing meetings
  bool isRoomCurrentlyOccupied(String roomId) {
    return _currentlyOccupied[roomId] ?? false;
  }

  /// Mở Firestore REAL-TIME stream lắng nghe meetings đang diễn ra.
  /// Tự động cập nhật _currentlyOccupied mỗi khi có meeting thay đổi.
  void subscribeOccupancy() {
    _occupancySubscription?.cancel();
    _occupancyTimer?.cancel();

    final now = DateTime.now();

    // Lắng nghe meetings approved/pending có startTime <= now
    // Firestore không hỗ trợ range query 2 field, nên filter endTime ở client
    _occupancySubscription = _firestore
        .collection('meetings')
        .where('status', whereIn: ['approved', 'pending'])
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .snapshots()
        .listen((snapshot) {
      final nowCheck = DateTime.now();
      final Map<String, bool> newOccupancy = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final roomId = data['roomId'] as String?;
        if (roomId == null || roomId.isEmpty) continue;

        final endTs = data['endTime'];
        if (endTs == null) continue;
        final endTime = (endTs as Timestamp).toDate();

        // Meeting đang diễn ra: startTime <= now < endTime
        if (endTime.isAfter(nowCheck)) {
          newOccupancy[roomId] = true;
          print('[ROOM][REALTIME] Room $roomId OCCUPIED by meeting ${doc.id}');
        }
      }

      _currentlyOccupied = newOccupancy;
      print('[ROOM][REALTIME] Currently occupied: ${_currentlyOccupied.length} rooms');
      notifyListeners();
    }, onError: (e) {
      print('[ROOM][REALTIME] Stream error: $e');
    });

    // Timer re-subscribe mỗi 60 giây để cập nhật startTime <= now mới
    // (Firestore stream không trigger khi thời gian trôi qua, chỉ khi data đổi)
    _occupancyTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      subscribeOccupancy();
    });
  }

  void unsubscribeOccupancy() {
    _occupancySubscription?.cancel();
    _occupancySubscription = null;
    _occupancyTimer?.cancel();
    _occupancyTimer = null;
  }

  @override
  void dispose() {
    unsubscribeOccupancy();
    super.dispose();
  }

  /// Load current occupancy status for all rooms (one-shot, legacy)
  Future<void> loadCurrentOccupancy() async {
    try {
      final now = DateTime.now();
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('status', whereIn: ['approved', 'pending'])
          .get();

      Map<String, bool> newOccupancy = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final roomId = data['roomId'];
        if (roomId == null) continue;
        final startTime = (data['startTime'] as Timestamp).toDate();
        final endTime = (data['endTime'] as Timestamp).toDate();
        if (startTime.isBefore(now) && endTime.isAfter(now)) {
          newOccupancy[roomId] = true;
        }
      }
      _currentlyOccupied = newOccupancy;
      notifyListeners();
    } catch (e) {
      print('[ROOM][OCCUPANCY] ERROR: $e');
    }
  }

  /// Get rooms with their current occupancy status
  List<Map<String, dynamic>> get roomsWithOccupancy {
    return _rooms.map((room) {
      bool isOccupied = isRoomCurrentlyOccupied(room.id);
      return {
        'room': room,
        'isCurrentlyOccupied': isOccupied,
        'displayStatus': isOccupied ? 'Đang sử dụng' : _getStatusDisplayText(room.status),
      };
    }).toList();
  }

  String _getStatusDisplayText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Sẵn sàng';
      case RoomStatus.occupied:
        return 'Đang sử dụng'; // Legacy, should compute dynamically
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.disabled:
        return 'Tạm ngưng';
    }
  }

  // ==================== Usage Statistics (Time-based) ====================

  /// Calculate usage rate for today
  /// Formula: usedMinutes / totalAvailableMinutes
  Future<Map<String, dynamic>> calculateTodayUsageStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      print('[ROOM][STATS] Calculating usage for $todayStart to $todayEnd');

      // Get all bookable rooms
      int bookableRoomCount = bookableRooms.length;
      if (bookableRoomCount == 0) {
        return {
          'usageRate': 0.0,
          'totalMinutes': 0,
          'usedMinutes': 0,
          'meetingCount': 0,
          'bookableRooms': 0,
        };
      }

      // Total available minutes = bookable rooms * 24 hours * 60 minutes
      // (Or use business hours: 8 hours * 60 = 480 minutes per room)
      const int businessHoursPerDay = 10; // 8:00 - 18:00
      int totalAvailableMinutes = bookableRoomCount * businessHoursPerDay * 60;

      // Query today's meetings
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('startTime', isLessThan: Timestamp.fromDate(todayEnd))
          .where('status', whereIn: ['approved', 'pending'])
          .get();

      int usedMinutes = 0;
      int meetingCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final roomId = data['roomId'];
        if (roomId == null) continue; // Skip meetings without room

        final startTime = (data['startTime'] as Timestamp).toDate();
        final endTime = (data['endTime'] as Timestamp).toDate();

        // Clamp to today's range
        final clampedStart = startTime.isBefore(todayStart) ? todayStart : startTime;
        final clampedEnd = endTime.isAfter(todayEnd) ? todayEnd : endTime;

        int duration = clampedEnd.difference(clampedStart).inMinutes;
        if (duration > 0) {
          usedMinutes += duration;
          meetingCount++;
        }
      }

      double usageRate = totalAvailableMinutes > 0
          ? (usedMinutes / totalAvailableMinutes) * 100
          : 0.0;

      print('[ROOM][STATS] Result: usageRate=${usageRate.toStringAsFixed(1)}% '
          'usedMinutes=$usedMinutes/$totalAvailableMinutes meetingCount=$meetingCount');

      return {
        'usageRate': usageRate,
        'totalMinutes': totalAvailableMinutes,
        'usedMinutes': usedMinutes,
        'meetingCount': meetingCount,
        'bookableRooms': bookableRoomCount,
      };
    } catch (e) {
      print('[ROOM][STATS] ERROR: $e');
      return {
        'usageRate': 0.0,
        'totalMinutes': 0,
        'usedMinutes': 0,
        'meetingCount': 0,
        'bookableRooms': 0,
        'error': e.toString(),
      };
    }
  }

  /// Tải tất cả phòng họp
  Future<void> loadRooms() async {
    try {
      _setLoading(true);
      _setError('');

      QuerySnapshot snapshot =
          await _firestore.collection('rooms').orderBy('name').get();

      // Always use Firestore document ID as canonical roomId
      _rooms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RoomModel.fromMap({
          ...data,
          // Force id to be the Firestore docId to avoid mismatches
          'id': doc.id,
        });
      }).toList();

      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải danh sách phòng: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Tải lịch sử bảo trì
  Future<void> loadMaintenanceRecords({String? roomId}) async {
    // Reset maintenance error trước khi tải
    _maintenanceError = '';
    try {
      Query query = _firestore.collection('maintenance_records');

      if (roomId != null) {
        query = query.where('roomId', isEqualTo: roomId);
        // Không dùng orderBy ở đây vì cần composite index (roomId + scheduledDate).
        // Thay vào đó sort client-side sau khi nhận kết quả.
      }

      QuerySnapshot snapshot = roomId == null
          // Khi không filter roomId, orderBy đơn lᮣ không cần composite index
          ? await query.orderBy('scheduledDate', descending: true).get()
          // Khi filter roomId, bỏ orderBy để tránh lỗi missing index
          : await query.get();

      _maintenanceRecords = snapshot.docs
          .map((doc) =>
              MaintenanceRecord.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort client-side theo scheduledDate giảm dần
      _maintenanceRecords.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      notifyListeners();
    } catch (e) {
      // Dùng _maintenanceError để không ảnh hưởng toàn bộ màn hình
      _maintenanceError = 'Lỗi tải lịch sử bảo trì: $e';
      print('[ROOM] ❌ $_maintenanceError');
      notifyListeners();
    }
  }

  /// Tạo phòng họp mới
  Future<void> createRoom(RoomModel room, UserModel currentUser) async {
    try {
      _setLoading(true);
      _setError('');

      // Kiểm tra quyền
      if (!currentUser.isAdmin && !currentUser.isDirector) {
        throw Exception('Bạn không có quyền tạo phòng họp');
      }

      // Tạo ID mới
      String roomId = _firestore.collection('rooms').doc().id;

      // Tạo QR code (có thể tích hợp thư viện QR sau)
      String qrCode = 'ROOM_${roomId.substring(0, 8).toUpperCase()}';

      RoomModel newRoom = room.copyWith(
        id: roomId,
        qrCode: qrCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
      );

      await _firestore.collection('rooms').doc(roomId).set(newRoom.toMap());

      // Thêm vào list local
      _rooms.add(newRoom);
      notifyListeners();

      print('✅ Đã tạo phòng họp: ${newRoom.name}');
    } catch (e) {
      _setError('Lỗi tạo phòng họp: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật phòng họp
  Future<void> updateRoom(RoomModel room, UserModel currentUser) async {
    try {
      _setLoading(true);
      _setError('');

      // Kiểm tra quyền
      if (!currentUser.isAdmin && !currentUser.isDirector) {
        throw Exception('Bạn không có quyền cập nhật phòng họp');
      }

      RoomModel updatedRoom = room.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: currentUser.id,
      );

      await _firestore
          .collection('rooms')
          .doc(room.id)
          .update(updatedRoom.toMap());

      // Cập nhật trong list local
      int index = _rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _rooms[index] = updatedRoom;
        notifyListeners();
      }

      print('✅ Đã cập nhật phòng họp: ${room.name}');
    } catch (e) {
      _setError('Lỗi cập nhật phòng họp: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Xóa phòng họp
  Future<void> deleteRoom(String roomId, UserModel currentUser) async {
    try {
      _setLoading(true);
      _setError('');

      // Kiểm tra quyền
      if (!currentUser.isAdmin) {
        throw Exception('Chỉ Admin mới có quyền xóa phòng họp');
      }

      // Kiểm tra phòng có đang được sử dụng không
      RoomModel? room = _rooms.firstWhere((r) => r.id == roomId);
      if (room.status == RoomStatus.occupied) {
        throw Exception('Không thể xóa phòng đang được sử dụng');
      }

      await _firestore.collection('rooms').doc(roomId).delete();

      // Xóa khỏi list local
      _rooms.removeWhere((r) => r.id == roomId);
      notifyListeners();

      print('✅ Đã xóa phòng họp: ${room.name}');
    } catch (e) {
      _setError('Lỗi xóa phòng họp: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Thay đổi trạng thái phòng
  Future<void> changeRoomStatus(
      String roomId, RoomStatus newStatus, UserModel currentUser) async {
    try {
      _setLoading(true);
      _setError('');

      // Kiểm tra quyền
      if (!currentUser.isAdmin && !currentUser.isDirector) {
        throw Exception('Bạn không có quyền thay đổi trạng thái phòng');
      }

      await _firestore.collection('rooms').doc(roomId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.id,
      });

      // Cập nhật trong list local
      int index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = _rooms[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
          updatedBy: currentUser.id,
        );
        notifyListeners();
      }

      print(
          '✅ Đã thay đổi trạng thái phòng: ${_rooms[index].name} -> ${newStatus.toString()}');
    } catch (e) {
      _setError('Lỗi thay đổi trạng thái phòng: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo lịch bảo trì
  Future<void> createMaintenanceRecord(
      MaintenanceRecord record, UserModel currentUser) async {
    try {
      _setLoading(true);
      _setError('');

      // Kiểm tra quyền
      if (!currentUser.isAdmin && !currentUser.isDirector) {
        throw Exception('Bạn không có quyền tạo lịch bảo trì');
      }

      String recordId = _firestore.collection('maintenance_records').doc().id;
      MaintenanceRecord newRecord = MaintenanceRecord(
        id: recordId,
        roomId: record.roomId,
        type: record.type,
        priority: record.priority,
        title: record.title,
        description: record.description,
        technician: record.technician,
        scheduledDate: record.scheduledDate,
        cost: record.cost,
        additionalData: {
          ...record.additionalData,
          'createdBy': currentUser.id,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      await _firestore
          .collection('maintenance_records')
          .doc(recordId)
          .set(newRecord.toMap());

      // Cập nhật nextMaintenanceDate của phòng
      await _firestore.collection('rooms').doc(record.roomId).update({
        'nextMaintenanceDate': Timestamp.fromDate(record.scheduledDate),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.id,
      });

      // Thêm vào list local
      _maintenanceRecords.insert(0, newRecord);
      notifyListeners();

      print('✅ Đã tạo lịch bảo trì: ${record.title}');
    } catch (e) {
      _setError('Lỗi tạo lịch bảo trì: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Hoàn thành bảo trì
  Future<void> completeMaintenanceRecord(String recordId, UserModel currentUser,
      {double? actualCost}) async {
    try {
      _setLoading(true);
      _setError('');

      DateTime completedDate = DateTime.now();

      await _firestore.collection('maintenance_records').doc(recordId).update({
        'status': 'completed',
        'completedDate': Timestamp.fromDate(completedDate),
        'cost': actualCost ?? 0,
        'additionalData.completedBy': currentUser.id,
      });

      // Tìm record và cập nhật lastMaintenanceDate của phòng
      MaintenanceRecord? record =
          _maintenanceRecords.firstWhere((r) => r.id == recordId);
      await _firestore.collection('rooms').doc(record.roomId).update({
        'lastMaintenanceDate': Timestamp.fromDate(completedDate),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.id,
      });

      // Cập nhật list local
      int index = _maintenanceRecords.indexWhere((r) => r.id == recordId);
      if (index != -1) {
        _maintenanceRecords[index] = MaintenanceRecord(
          id: record.id,
          roomId: record.roomId,
          type: record.type,
          priority: record.priority,
          title: record.title,
          description: record.description,
          technician: record.technician,
          scheduledDate: record.scheduledDate,
          completedDate: completedDate,
          cost: actualCost ?? record.cost,
          status: 'completed',
          photos: record.photos,
          additionalData: {
            ...record.additionalData,
            'completedBy': currentUser.id,
          },
        );
        notifyListeners();
      }
    
      print('✅ Đã hoàn thành bảo trì: ${record.title}');
    } catch (e) {
      _setError('Lỗi hoàn thành bảo trì: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Tìm kiếm phòng theo tiêu chí
  List<RoomModel> searchRooms({
    String? keyword,
    RoomStatus? status,
    List<RoomAmenity>? requiredAmenities,
    int? minCapacity,
    int? maxCapacity,
    String? building,
    String? floor,
  }) {
    List<RoomModel> results = _rooms;

    if (keyword != null && keyword.isNotEmpty) {
      results = results
          .where((room) =>
              room.name.toLowerCase().contains(keyword.toLowerCase()) ||
              room.description.toLowerCase().contains(keyword.toLowerCase()) ||
              room.location.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    if (status != null) {
      results = results.where((room) => room.status == status).toList();
    }

    if (requiredAmenities != null && requiredAmenities.isNotEmpty) {
      results = results
          .where((room) => requiredAmenities
              .every((amenity) => room.amenities.contains(amenity)))
          .toList();
    }

    if (minCapacity != null) {
      results = results.where((room) => room.capacity >= minCapacity).toList();
    }

    if (maxCapacity != null) {
      results = results.where((room) => room.capacity <= maxCapacity).toList();
    }

    if (building != null && building.isNotEmpty) {
      results = results.where((room) => room.building == building).toList();
    }

    if (floor != null && floor.isNotEmpty) {
      results = results.where((room) => room.floor == floor).toList();
    }

    return results;
  }

  /// Lấy thống kê sử dụng phòng theo thời gian
  Future<Map<String, dynamic>> getRoomUsageStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Tạo query cho meetings trong khoảng thời gian
      Query query = _firestore.collection('meetings');

      if (startDate != null) {
        query = query.where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('startTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      QuerySnapshot meetingSnapshot = await query.get();

      // Thống kê theo phòng
      Map<String, int> roomUsageCount = {};
      Map<String, double> roomUsageHours = {};

      for (var doc in meetingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final roomId = data['roomId'] ?? '';
        final startTime = (data['startTime'] as Timestamp).toDate();
        final endTime = (data['endTime'] as Timestamp).toDate();
        final duration = endTime.difference(startTime).inHours.toDouble();

        if (roomId.isNotEmpty) {
          roomUsageCount[roomId] = (roomUsageCount[roomId] ?? 0) + 1;
          roomUsageHours[roomId] = (roomUsageHours[roomId] ?? 0) + duration;
        }
      }

      return {
        'totalMeetings': meetingSnapshot.docs.length,
        'roomUsageCount': roomUsageCount,
        'roomUsageHours': roomUsageHours,
        'mostUsedRooms': roomUsageCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      };
    } catch (e) {
      print('❌ Lỗi lấy thống kê: $e');
      return {};
    }
  }

  /// Lấy phòng theo ID
  RoomModel? getRoomById(String roomId) {
    try {
      return _rooms.firstWhere((room) => room.id == roomId);
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh sách tòa nhà
  List<String> get buildings {
    return _rooms
        .map((room) => room.building)
        .where((building) => building.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Lấy danh sách tầng theo tòa nhà
  List<String> getFloorsByBuilding(String building) {
    return _rooms
        .where((room) => room.building == building)
        .map((room) => room.floor)
        .where((floor) => floor.isNotEmpty)
        .toSet()
        .toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    if (error.isNotEmpty) {
      print('❌ RoomProvider Error: $error');
    }
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
