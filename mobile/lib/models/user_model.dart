import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';
import 'meeting_model.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final String? departmentId;
  final String? departmentName;
  final String? managerId;
  final String? managerName;
  final List<String> teamIds;
  final List<String> teamNames;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? additionalData;
  final UserRole? pendingRole;
  final String? pendingDepartment;
  final DateTime? requestedAt;
  final bool isRoleApproved;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.managerId,
    this.managerName,
    this.teamIds = const [],
    this.teamNames = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.additionalData,
    this.pendingRole,
    this.pendingDepartment,
    this.requestedAt,
    this.isRoleApproved = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    try {
      return UserModel(
        id: id,
        email: map['email']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? '',
        photoURL: map['photoURL']?.toString(),
        role: _parseUserRole(map['role']),
        departmentId: map['departmentId']?.toString(),
        departmentName: map['departmentName']?.toString(),
        managerId: map['managerId']?.toString(),
        managerName: map['managerName']?.toString(),
        teamIds: _parseStringList(map['teamIds']),
        teamNames: _parseStringList(map['teamNames']),
        createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
        lastLoginAt: _parseTimestamp(map['lastLoginAt']),
        isActive: map['isActive'] == true,
        additionalData: map['additionalData'] as Map<String, dynamic>?,
        pendingRole: map['pendingRole'] != null
            ? UserRole.values.firstWhere(
                (role) => role.toString() == 'UserRole.${map['pendingRole']}',
                orElse: () => UserRole.guest,
              )
            : null,
        pendingDepartment: map['pendingDepartment']?.toString(),
        requestedAt: _parseTimestamp(map['requestedAt']),
        isRoleApproved: map['isRoleApproved'] == true,
      );
    } catch (e) {
      print('Error parsing UserModel for ID $id: $e');
      // Trả về user mặc định nếu có lỗi
      return UserModel(
        id: id,
        email: map['email']?.toString() ?? 'unknown@email.com',
        displayName: map['displayName']?.toString() ?? 'Unknown User',
        role: UserRole.guest,
        createdAt: DateTime.now(),
        isActive: true,
        isRoleApproved: true,
      );
    }
  }

  // Helper methods để parse dữ liệu an toàn
  static UserRole _parseUserRole(dynamic value) {
    if (value == null) return UserRole.guest;

    String roleStr = value.toString().toLowerCase().trim();

    // Xử lý các trường hợp role khác nhau
    switch (roleStr) {
      case 'super admin':
      case 'superadmin':
      case 'superAdmin':
      case 'admin':
        return UserRole.admin; // Admin là quyền cao nhất
      case 'director':
        return UserRole.director; // Director là quản lý cấp trung
      case 'manager':
        return UserRole.manager;
      case 'employee':
        return UserRole.employee;
      case 'guest':
        return UserRole.guest;
      default:
        // Thử parse theo format cũ UserRole.xxx
        return UserRole.values.firstWhere(
          (role) => role.toString() == 'UserRole.$roleStr',
          orElse: () => UserRole.guest,
        );
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return [];
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.parse(value);
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'managerId': managerId,
      'managerName': managerName,
      'teamIds': teamIds,
      'teamNames': teamNames,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'additionalData': additionalData,
      'pendingRole': pendingRole?.toString().split('.').last,
      'pendingDepartment': pendingDepartment,
      'requestedAt': requestedAt != null ? Timestamp.fromDate(requestedAt!) : null,
      'isRoleApproved': isRoleApproved,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    String? departmentId,
    String? departmentName,
    String? managerId,
    String? managerName,
    List<String>? teamIds,
    List<String>? teamNames,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? additionalData,
    UserRole? pendingRole,
    String? pendingDepartment,
    DateTime? requestedAt,
    bool? isRoleApproved,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      teamIds: teamIds ?? this.teamIds,
      teamNames: teamNames ?? this.teamNames,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      additionalData: additionalData ?? this.additionalData,
      pendingRole: pendingRole ?? this.pendingRole,
      pendingDepartment: pendingDepartment ?? this.pendingDepartment,
      requestedAt: requestedAt ?? this.requestedAt,
      isRoleApproved: isRoleApproved ?? this.isRoleApproved,
    );
  }

  // Helper methods
  bool get isAdmin => role == UserRole.admin; // Quyền cao nhất (admin)
  bool get isDirector => role == UserRole.director; // Quản lý cấp trung
  bool get isManager => role == UserRole.manager;
  bool get isEmployee => role == UserRole.employee;
  bool get isGuest => role == UserRole.guest;

  // Backward compatibility
  bool get isSuperAdmin => isAdmin;

  bool canCreateMeeting(MeetingType meetingType) {
    final roleModel = UserRoleModel.getRoleByEnum(role);
    return roleModel.canCreateMeeting &&
        roleModel.allowedMeetingTypes.contains(meetingType);
  }

  bool needsApproval(MeetingType meetingType) {
    final roleModel = UserRoleModel.getRoleByEnum(role);
    return roleModel.needsApproval;
  }

  List<MeetingType> getAllowedMeetingTypes() {
    final roleModel = UserRoleModel.getRoleByEnum(role);
    return roleModel.allowedMeetingTypes;
  }

  List<String> getPermissions() {
    final roleModel = UserRoleModel.getRoleByEnum(role);
    return roleModel.permissions;
  }

  bool hasPermission(String permission) {
    return getPermissions().contains(permission);
  }
}
