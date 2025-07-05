import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

class RoomSetupHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo phòng họp mẫu cho hệ thống
  static Future<void> setupDefaultRooms(UserModel currentUser) async {
    try {
      print('🏗️ Bắt đầu setup phòng họp mặc định...');

      // Kiểm tra quyền
      if (!currentUser.isAdmin && !currentUser.isDirector) {
        throw Exception('Bạn không có quyền setup phòng họp');
      }

      // Kiểm tra đã có phòng chưa
      QuerySnapshot existingRooms =
          await _firestore.collection('rooms').limit(1).get();
      if (existingRooms.docs.isNotEmpty) {
        print('⚠️ Đã có phòng trong hệ thống, bỏ qua setup mặc định');
        return;
      }

      List<RoomModel> defaultRooms = _getDefaultRoomTemplates(currentUser);

      int createdCount = 0;
      for (RoomModel room in defaultRooms) {
        try {
          await _firestore.collection('rooms').doc(room.id).set(room.toMap());
          print('✅ Đã tạo phòng: ${room.name}');
          createdCount++;
        } catch (e) {
          print('❌ Lỗi tạo phòng ${room.name}: $e');
        }
      }

      print('🎉 Hoàn thành! Đã tạo $createdCount phòng mặc định');
    } catch (e) {
      print('❌ Lỗi setup phòng mặc định: $e');
      rethrow;
    }
  }

  /// Lấy danh sách template phòng mặc định
  static List<RoomModel> _getDefaultRoomTemplates(UserModel currentUser) {
    DateTime now = DateTime.now();

    return [
      // Phòng họp nhỏ
      RoomModel(
        id: 'room_small_01',
        name: 'Phòng họp A1',
        description:
            'Phòng họp nhỏ dành cho 4-6 người, thích hợp cho cuộc họp team',
        location: 'Cạnh thang máy chính',
        floor: '1',
        building: 'Tòa A',
        capacity: 6,
        status: RoomStatus.available,
        amenities: [
          RoomAmenity.wifi,
          RoomAmenity.whiteboard,
          RoomAmenity.monitor,
          RoomAmenity.airConditioner,
          RoomAmenity.powerOutlet,
        ],
        qrCode: 'ROOM_A1_001',
        area: 15.0,
        photoUrl: '',
        photos: [],
        settings: {
          'preferredTemperature': 24,
          'lightingLevel': 'medium',
          'soundProofing': true,
        },
        createdAt: now,
        updatedAt: now,
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        isActive: true,
        additionalData: {
          'roomType': 'small_meeting',
          'isTemplate': false,
          'setupBy': 'system_default',
        },
      ),

      // Phòng họp trung bình
      RoomModel(
        id: 'room_medium_01',
        name: 'Phòng họp B1',
        description:
            'Phòng họp trung bình cho 8-12 người, có đầy đủ thiết bị thuyết trình',
        location: 'Cuối hành lang',
        floor: '2',
        building: 'Tòa A',
        capacity: 12,
        status: RoomStatus.available,
        amenities: [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.whiteboard,
          RoomAmenity.microphone,
          RoomAmenity.speaker,
          RoomAmenity.airConditioner,
          RoomAmenity.powerOutlet,
          RoomAmenity.videoConference,
        ],
        qrCode: 'ROOM_B1_002',
        area: 30.0,
        photoUrl: '',
        photos: [],
        settings: {
          'preferredTemperature': 23,
          'lightingLevel': 'high',
          'soundProofing': true,
          'projectorType': 'HD',
        },
        createdAt: now,
        updatedAt: now,
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        isActive: true,
        additionalData: {
          'roomType': 'medium_meeting',
          'isTemplate': false,
          'setupBy': 'system_default',
        },
      ),

      // Phòng hội thảo lớn
      RoomModel(
        id: 'room_large_01',
        name: 'Hội trường C1',
        description:
            'Hội trường lớn cho 50+ người, thích hợp cho hội thảo và sự kiện',
        location: 'Tầng trệt, cạnh sảnh chính',
        floor: '1',
        building: 'Tòa C',
        capacity: 80,
        status: RoomStatus.available,
        amenities: [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.microphone,
          RoomAmenity.speaker,
          RoomAmenity.camera,
          RoomAmenity.monitor,
          RoomAmenity.airConditioner,
          RoomAmenity.powerOutlet,
          RoomAmenity.videoConference,
          RoomAmenity.waterDispenser,
        ],
        qrCode: 'ROOM_C1_003',
        area: 120.0,
        photoUrl: '',
        photos: [],
        settings: {
          'preferredTemperature': 22,
          'lightingLevel': 'high',
          'soundProofing': true,
          'audioSystem': 'professional',
          'seatArrangement': 'theater',
        },
        createdAt: now,
        updatedAt: now,
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        isActive: true,
        additionalData: {
          'roomType': 'large_conference',
          'isTemplate': false,
          'setupBy': 'system_default',
        },
      ),

      // Phòng training
      RoomModel(
        id: 'room_training_01',
        name: 'Phòng đào tạo D1',
        description:
            'Phòng đào tạo với bàn ghế linh hoạt, thích hợp cho workshop',
        location: 'Gần khu vực nghỉ ngơi',
        floor: '3',
        building: 'Tòa D',
        capacity: 20,
        status: RoomStatus.available,
        amenities: [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.whiteboard,
          RoomAmenity.flipChart,
          RoomAmenity.microphone,
          RoomAmenity.speaker,
          RoomAmenity.airConditioner,
          RoomAmenity.powerOutlet,
          RoomAmenity.waterDispenser,
        ],
        qrCode: 'ROOM_D1_004',
        area: 50.0,
        photoUrl: '',
        photos: [],
        settings: {
          'preferredTemperature': 24,
          'lightingLevel': 'bright',
          'soundProofing': false,
          'seatArrangement': 'classroom',
          'movableFurniture': true,
        },
        createdAt: now,
        updatedAt: now,
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        isActive: true,
        additionalData: {
          'roomType': 'training',
          'isTemplate': false,
          'setupBy': 'system_default',
        },
      ),

      // Phòng họp VIP
      RoomModel(
        id: 'room_vip_01',
        name: 'Phòng họp VIP',
        description:
            'Phòng họp cao cấp dành cho khách VIP và cuộc họp quan trọng',
        location: 'Tầng cao nhất',
        floor: '10',
        building: 'Tòa A',
        capacity: 8,
        status: RoomStatus.available,
        amenities: [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.monitor,
          RoomAmenity.microphone,
          RoomAmenity.speaker,
          RoomAmenity.camera,
          RoomAmenity.airConditioner,
          RoomAmenity.powerOutlet,
          RoomAmenity.videoConference,
          RoomAmenity.waterDispenser,
        ],
        qrCode: 'ROOM_VIP_005',
        area: 40.0,
        photoUrl: '',
        photos: [],
        settings: {
          'preferredTemperature': 23,
          'lightingLevel': 'premium',
          'soundProofing': true,
          'furnitureType': 'executive',
          'privacyLevel': 'high',
        },
        createdAt: now,
        updatedAt: now,
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        isActive: true,
        additionalData: {
          'roomType': 'vip_meeting',
          'isTemplate': false,
          'setupBy': 'system_default',
        },
      ),

      // Phòng bảo trì (để demo)
      RoomModel(
        id: 'room_maintenance_demo',
        name: 'Phòng họp E1 (Demo bảo trì)',
        description:
            'Phòng demo trạng thái bảo trì - cần sửa chữa hệ thống điều hòa',
        location: 'Tầng 2, phía Tây',
        floor: '2',
        building: 'Tòa E',
        capacity: 10,
        status: RoomStatus.maintenance,
        amenities: [
          RoomAmenity.wifi,
          RoomAmenity.whiteboard,
          RoomAmenity.powerOutlet,
          // Không có điều hòa vì đang bảo trì
        ],
        qrCode: 'ROOM_E1_006',
        area: 25.0,
        photoUrl: '',
        photos: [],
        settings: {
          'preferredTemperature': 25,
          'lightingLevel': 'medium',
          'soundProofing': false,
        },
        createdAt: now,
        updatedAt: now,
        lastMaintenanceDate: now.subtract(const Duration(days: 30)),
        nextMaintenanceDate: now.add(const Duration(days: 7)),
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        isActive: true,
        additionalData: {
          'roomType': 'standard_meeting',
          'isTemplate': false,
          'setupBy': 'system_default',
          'maintenanceIssue': 'Air conditioning system needs repair',
        },
      ),
    ];
  }

  /// Tạo maintenance records mẫu
  static Future<void> setupSampleMaintenanceRecords(
      UserModel currentUser) async {
    try {
      print('🔧 Tạo lịch sử bảo trì mẫu...');

      List<MaintenanceRecord> sampleRecords = [
        MaintenanceRecord(
          id: 'maint_001',
          roomId: 'room_maintenance_demo',
          type: MaintenanceType.repair,
          priority: MaintenancePriority.high,
          title: 'Sửa chữa hệ thống điều hòa',
          description: 'Điều hòa không hoạt động, cần thay thế linh kiện',
          technician: 'Nguyễn Văn A',
          scheduledDate: DateTime.now().add(const Duration(days: 3)),
          cost: 2500000,
          status: 'scheduled',
          additionalData: {
            'createdBy': currentUser.id,
            'priority': 'high',
            'estimatedHours': 4,
          },
        ),
        MaintenanceRecord(
          id: 'maint_002',
          roomId: 'room_large_01',
          type: MaintenanceType.routine,
          priority: MaintenancePriority.medium,
          title: 'Bảo trì định kỳ hệ thống âm thanh',
          description: 'Kiểm tra và vệ sinh hệ thống âm thanh định kỳ',
          technician: 'Trần Thị B',
          scheduledDate: DateTime.now().subtract(const Duration(days: 7)),
          completedDate: DateTime.now().subtract(const Duration(days: 5)),
          cost: 500000,
          status: 'completed',
          additionalData: {
            'createdBy': currentUser.id,
            'priority': 'medium',
            'completedBy': currentUser.id,
          },
        ),
      ];

      for (MaintenanceRecord record in sampleRecords) {
        await _firestore
            .collection('maintenance_records')
            .doc(record.id)
            .set(record.toMap());
        print('✅ Đã tạo maintenance record: ${record.title}');
      }

      print('🎉 Hoàn thành tạo maintenance records mẫu!');
    } catch (e) {
      print('❌ Lỗi tạo maintenance records: $e');
    }
  }

  /// Tạo room templates cho user tự chọn
  static List<Map<String, dynamic>> getRoomTemplates() {
    return [
      {
        'id': 'template_small',
        'name': 'Phòng họp nhỏ',
        'description': 'Dành cho 4-8 người',
        'capacity': 6,
        'amenities': [
          RoomAmenity.wifi,
          RoomAmenity.whiteboard,
          RoomAmenity.monitor,
          RoomAmenity.airConditioner,
        ],
        'suggestedArea': 15.0,
        'icon': '🏢',
      },
      {
        'id': 'template_medium',
        'name': 'Phòng họp trung bình',
        'description': 'Dành cho 8-15 người',
        'capacity': 12,
        'amenities': [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.microphone,
          RoomAmenity.speaker,
          RoomAmenity.airConditioner,
          RoomAmenity.videoConference,
        ],
        'suggestedArea': 30.0,
        'icon': '🏛️',
      },
      {
        'id': 'template_large',
        'name': 'Hội trường',
        'description': 'Dành cho 20+ người',
        'capacity': 50,
        'amenities': [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.microphone,
          RoomAmenity.speaker,
          RoomAmenity.camera,
          RoomAmenity.monitor,
          RoomAmenity.airConditioner,
          RoomAmenity.videoConference,
        ],
        'suggestedArea': 80.0,
        'icon': '🏟️',
      },
      {
        'id': 'template_training',
        'name': 'Phòng đào tạo',
        'description': 'Dành cho workshop và training',
        'capacity': 20,
        'amenities': [
          RoomAmenity.wifi,
          RoomAmenity.projector,
          RoomAmenity.whiteboard,
          RoomAmenity.flipChart,
          RoomAmenity.airConditioner,
        ],
        'suggestedArea': 50.0,
        'icon': '📚',
      },
      {
        'id': 'template_vip',
        'name': 'Phòng VIP',
        'description': 'Phòng cao cấp cho khách VIP',
        'capacity': 8,
        'amenities': RoomAmenity.values, // Tất cả tiện ích
        'suggestedArea': 40.0,
        'icon': '👑',
      },
    ];
  }

  /// Kiểm tra xem đã setup chưa
  static Future<bool> isRoomsSetupCompleted() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('rooms').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Lỗi kiểm tra setup rooms: $e');
      return false;
    }
  }

  /// Xóa tất cả phòng (chỉ dùng để reset)
  static Future<void> resetAllRooms(UserModel currentUser) async {
    try {
      if (!currentUser.isAdmin) {
        throw Exception('Chỉ Admin mới có quyền reset phòng');
      }

      print('🗑️ Đang xóa tất cả phòng...');

      QuerySnapshot snapshot = await _firestore.collection('rooms').get();
      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Đã xóa tất cả phòng');

      // Xóa maintenance records
      QuerySnapshot maintenanceSnapshot =
          await _firestore.collection('maintenance_records').get();
      WriteBatch maintenanceBatch = _firestore.batch();

      for (QueryDocumentSnapshot doc in maintenanceSnapshot.docs) {
        maintenanceBatch.delete(doc.reference);
      }

      await maintenanceBatch.commit();
      print('✅ Đã xóa tất cả maintenance records');
    } catch (e) {
      print('❌ Lỗi reset rooms: $e');
      rethrow;
    }
  }

  /// Export cấu hình phòng
  static Map<String, dynamic> exportRoomsConfig(List<RoomModel> rooms) {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'totalRooms': rooms.length,
      'rooms': rooms.map((room) => room.toMap()).toList(),
    };
  }

  /// Import cấu hình phòng
  static List<RoomModel> importRoomsConfig(Map<String, dynamic> config) {
    try {
      List<dynamic> roomsData = config['rooms'] ?? [];
      return roomsData.map((data) => RoomModel.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Lỗi import config: $e');
    }
  }
}
