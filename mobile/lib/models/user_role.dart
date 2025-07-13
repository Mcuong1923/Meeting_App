import 'meeting_model.dart';

enum UserRole {
  admin, // Trước đây là superAdmin - Quyền cao nhất
  director, // Trước đây là admin - Quản lý cấp trung
  manager,
  employee,
  guest,
}

// Đảm bảo KHÔNG có enum MeetingType ở đây!

// Đã chuyển MeetingStatus sang meeting_model.dart, KHÔNG định nghĩa hoặc export MeetingStatus ở đây nữa.

class UserRoleModel {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final bool canCreateMeeting;
  final bool needsApproval;
  final List<MeetingType> allowedMeetingTypes;

  UserRoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.canCreateMeeting,
    required this.needsApproval,
    required this.allowedMeetingTypes,
  });

  factory UserRoleModel.fromMap(Map<String, dynamic> map) {
    return UserRoleModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      canCreateMeeting: map['canCreateMeeting'] ?? false,
      needsApproval: map['needsApproval'] ?? true,
      allowedMeetingTypes: (map['allowedMeetingTypes'] as List<dynamic>?)
              ?.map((e) => MeetingType.values.firstWhere(
                    (type) => type.toString() == 'MeetingType.$e',
                    orElse: () => MeetingType.personal,
                  ))
              .toList() ??
          [MeetingType.personal],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'canCreateMeeting': canCreateMeeting,
      'needsApproval': needsApproval,
      'allowedMeetingTypes': allowedMeetingTypes
          .map((type) => type.toString().split('.').last)
          .toList(),
    };
  }

  static UserRoleModel getRoleByEnum(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return UserRoleModel(
          id: 'admin',
          name: 'Admin',
          description: 'Quản trị viên - Toàn quyền hệ thống',
          permissions: [
            'manage_all_users',
            'manage_all_meetings',
            'manage_system_settings',
            'view_all_reports',
            'manage_departments',
            'manage_rooms',
          ],
          canCreateMeeting: true,
          needsApproval: false,
          allowedMeetingTypes: MeetingType.values.toList(),
        );
      case UserRole.director:
        return UserRoleModel(
          id: 'director',
          name: 'Director',
          description: 'Giám đốc - Quản lý phòng ban',
          permissions: [
            'manage_department_users',
            'manage_department_meetings',
            'view_department_reports',
            'manage_rooms',
          ],
          canCreateMeeting: true,
          needsApproval: false,
          allowedMeetingTypes: [
            MeetingType.team,
            MeetingType.department,
            MeetingType.company,
          ],
        );
      case UserRole.manager:
        return UserRoleModel(
          id: 'manager',
          name: 'Manager',
          description: 'Quản lý - Quản lý team/dự án',
          permissions: [
            'manage_team_users',
            'manage_team_meetings',
            'view_team_reports',
            'approve_team_meetings',
          ],
          canCreateMeeting: true,
          needsApproval: false,
          allowedMeetingTypes: [
            MeetingType.personal,
            MeetingType.team,
          ],
        );
      case UserRole.employee:
        return UserRoleModel(
          id: 'employee',
          name: 'Employee',
          description: 'Nhân viên - Tạo cuộc họp cá nhân',
          permissions: [
            'create_personal_meetings',
            'view_personal_reports',
            'join_invited_meetings',
          ],
          canCreateMeeting: true,
          needsApproval: true,
          allowedMeetingTypes: [MeetingType.personal],
        );
      case UserRole.guest:
        return UserRoleModel(
          id: 'guest',
          name: 'Guest',
          description: 'Khách - Chỉ tham gia cuộc họp được mời',
          permissions: [
            'join_invited_meetings',
          ],
          canCreateMeeting: false,
          needsApproval: false,
          allowedMeetingTypes: [],
        );
    }
  }
}
