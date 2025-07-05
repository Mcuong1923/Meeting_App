import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái phòng họp
enum RoomStatus {
  available, // Sẵn sàng
  occupied, // Đang sử dụng
  maintenance, // Bảo trì
  disabled, // Tạm ngưng
}

/// Loại tiện ích phòng họp
enum RoomAmenity {
  projector, // Máy chiếu
  whiteboard, // Bảng trắng
  wifi, // WiFi
  airConditioner, // Điều hòa
  microphone, // Micro
  speaker, // Loa
  camera, // Camera
  monitor, // Màn hình
  flipChart, // Bảng giấy
  waterDispenser, // Cây nước
  powerOutlet, // Ổ cắm điện
  videoConference, // Thiết bị họp online
}

/// Mức độ ưu tiên bảo trì
enum MaintenancePriority {
  low, // Thấp
  medium, // Trung bình
  high, // Cao
  urgent, // Khẩn cấp
}

/// Loại bảo trì
enum MaintenanceType {
  routine, // Bảo trì định kỳ
  repair, // Sửa chữa
  upgrade, // Nâng cấp
  cleaning, // Vệ sinh
  inspection, // Kiểm tra
}

/// Lịch sử bảo trì
class MaintenanceRecord {
  final String id;
  final String roomId;
  final MaintenanceType type;
  final MaintenancePriority priority;
  final String title;
  final String description;
  final String technician;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final double cost;
  final String status; // scheduled, in_progress, completed, cancelled
  final List<String> photos;
  final Map<String, dynamic> additionalData;

  MaintenanceRecord({
    required this.id,
    required this.roomId,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.technician,
    required this.scheduledDate,
    this.completedDate,
    this.cost = 0.0,
    this.status = 'scheduled',
    this.photos = const [],
    this.additionalData = const {},
  });

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      type: MaintenanceType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MaintenanceType.routine,
      ),
      priority: MaintenancePriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => MaintenancePriority.medium,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      technician: map['technician'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      completedDate: map['completedDate'] != null
          ? (map['completedDate'] as Timestamp).toDate()
          : null,
      cost: (map['cost'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'scheduled',
      photos: List<String>.from(map['photos'] ?? []),
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'description': description,
      'technician': technician,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'completedDate':
          completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'cost': cost,
      'status': status,
      'photos': photos,
      'additionalData': additionalData,
    };
  }
}

/// Model phòng họp
class RoomModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final String floor;
  final String building;
  final int capacity;
  final RoomStatus status;
  final List<RoomAmenity> amenities;
  final String qrCode;
  final double area; // m²
  final String photoUrl;
  final List<String> photos;
  final Map<String, dynamic>
      settings; // Cài đặt phòng (nhiệt độ, ánh sáng, v.v.)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String createdBy;
  final String updatedBy;
  final bool isActive;
  final Map<String, dynamic> additionalData;

  RoomModel({
    required this.id,
    required this.name,
    this.description = '',
    this.location = '',
    this.floor = '',
    this.building = '',
    this.capacity = 0,
    this.status = RoomStatus.available,
    this.amenities = const [],
    this.qrCode = '',
    this.area = 0.0,
    this.photoUrl = '',
    this.photos = const [],
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.createdBy = '',
    this.updatedBy = '',
    this.isActive = true,
    this.additionalData = const {},
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      floor: map['floor'] ?? '',
      building: map['building'] ?? '',
      capacity: map['capacity'] ?? 0,
      status: RoomStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => RoomStatus.available,
      ),
      amenities: (map['amenities'] as List<dynamic>?)
              ?.map((e) => RoomAmenity.values.firstWhere(
                    (amenity) => amenity.toString().split('.').last == e,
                    orElse: () => RoomAmenity.wifi,
                  ))
              .toList() ??
          [],
      qrCode: map['qrCode'] ?? '',
      area: (map['area'] ?? 0.0).toDouble(),
      photoUrl: map['photoUrl'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastMaintenanceDate: map['lastMaintenanceDate'] != null
          ? (map['lastMaintenanceDate'] as Timestamp).toDate()
          : null,
      nextMaintenanceDate: map['nextMaintenanceDate'] != null
          ? (map['nextMaintenanceDate'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      isActive: map['isActive'] ?? true,
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'floor': floor,
      'building': building,
      'capacity': capacity,
      'status': status.toString().split('.').last,
      'amenities': amenities.map((e) => e.toString().split('.').last).toList(),
      'qrCode': qrCode,
      'area': area,
      'photoUrl': photoUrl,
      'photos': photos,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMaintenanceDate': lastMaintenanceDate != null
          ? Timestamp.fromDate(lastMaintenanceDate!)
          : null,
      'nextMaintenanceDate': nextMaintenanceDate != null
          ? Timestamp.fromDate(nextMaintenanceDate!)
          : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'additionalData': additionalData,
    };
  }

  // Helper methods
  String get statusText {
    switch (status) {
      case RoomStatus.available:
        return 'Sẵn sàng';
      case RoomStatus.occupied:
        return 'Đang sử dụng';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.disabled:
        return 'Tạm ngưng';
    }
  }

  String get fullLocation {
    List<String> parts = [];
    if (building.isNotEmpty) parts.add(building);
    if (floor.isNotEmpty) parts.add('Tầng $floor');
    if (location.isNotEmpty) parts.add(location);
    return parts.join(', ');
  }

  bool get needsMaintenance {
    if (nextMaintenanceDate == null) return false;
    return DateTime.now().isAfter(nextMaintenanceDate!);
  }

  bool get isAvailable => status == RoomStatus.available && isActive;

  List<String> get amenityNames {
    return amenities.map((amenity) {
      switch (amenity) {
        case RoomAmenity.projector:
          return 'Máy chiếu';
        case RoomAmenity.whiteboard:
          return 'Bảng trắng';
        case RoomAmenity.wifi:
          return 'WiFi';
        case RoomAmenity.airConditioner:
          return 'Điều hòa';
        case RoomAmenity.microphone:
          return 'Micro';
        case RoomAmenity.speaker:
          return 'Loa';
        case RoomAmenity.camera:
          return 'Camera';
        case RoomAmenity.monitor:
          return 'Màn hình';
        case RoomAmenity.flipChart:
          return 'Bảng giấy';
        case RoomAmenity.waterDispenser:
          return 'Cây nước';
        case RoomAmenity.powerOutlet:
          return 'Ổ cắm điện';
        case RoomAmenity.videoConference:
          return 'Thiết bị họp online';
      }
    }).toList();
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? floor,
    String? building,
    int? capacity,
    RoomStatus? status,
    List<RoomAmenity>? amenities,
    String? qrCode,
    double? area,
    String? photoUrl,
    List<String>? photos,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    String? createdBy,
    String? updatedBy,
    bool? isActive,
    Map<String, dynamic>? additionalData,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      floor: floor ?? this.floor,
      building: building ?? this.building,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      amenities: amenities ?? this.amenities,
      qrCode: qrCode ?? this.qrCode,
      area: area ?? this.area,
      photoUrl: photoUrl ?? this.photoUrl,
      photos: photos ?? this.photos,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isActive: isActive ?? this.isActive,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
