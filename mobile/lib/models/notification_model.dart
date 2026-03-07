import 'package:cloud_firestore/cloud_firestore.dart';
import 'meeting_model.dart';

/// Loại thông báo
enum NotificationType {
  info, // Thông tin chung
  warning, // Cảnh báo
  error, // Lỗi
  success, // Thành công
  reminder, // Nhắc nhở
  meeting, // Cuộc họp
  system, // Hệ thống
  meetingApproval, // Phê duyệt cuộc họp
  meetingApprovalResult, // Kết quả phê duyệt
  meetingReminder, // Nhắc nhở cuộc họp
  meetingCancelled, // Hủy cuộc họp
  meetingUpdated, // Cập nhật cuộc họp
  meetingInvitation, // Mời tham gia cuộc họp
  roomMaintenance, // Bảo trì phòng
  roleChange, // Thay đổi vai trò
  general, // Thông báo chung
  bookingReminder, // Nhắc nhở đặt phòng nhanh
  bookingExpired, // Đặt phòng đã hết hạn
  bookingApprovalRequired, // Đặt phòng cần admin duyệt
}

/// Mức độ ưu tiên thông báo
enum NotificationPriority {
  low, // Thấp
  normal, // Bình thường
  high, // Cao
  urgent, // Khẩn cấp
}

/// Model thông báo
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String? meetingId;
  final String? roomId;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic>? actionData;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final bool isRead;
  final bool isDelivered;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? meetingTitle;
  final MeetingScope? meetingScope;
  final String? targetAudience; // 'company', 'department:tech', 'team:dev_team'
  
  // Các field bắt buộc để đồng bộ với Firestore Rules mới
  final String? createdBy;
  final String? scope; // 'team', 'department', 'company', 'personal'
  final String? teamId;
  final String? departmentId;
  final List<String> recipients;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.meetingId,
    this.roomId,
    this.senderId,
    this.senderName,
    this.actionData,
    required this.createdAt,
    this.scheduledAt,
    this.isRead = false,
    this.isDelivered = false,
    this.readAt,
    this.deliveredAt,
    this.meetingTitle,
    this.meetingScope,
    this.targetAudience,
    this.createdBy,
    this.scope,
    this.teamId,
    this.departmentId,
    this.recipients = const [],
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.toString().split('.').last == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      meetingId: map['meetingId'],
      roomId: map['roomId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      actionData: map['actionData'] != null
          ? Map<String, dynamic>.from(map['actionData'])
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scheduledAt: map['scheduledAt'] != null
          ? (map['scheduledAt'] as Timestamp).toDate()
          : null,
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? false,
      readAt:
          map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      meetingTitle: map['meetingTitle'],
      meetingScope: map['meetingScope'] != null
          ? MeetingScope.values.firstWhere(
              (scope) =>
                  scope.toString().split('.').last == map['meetingScope'],
              orElse: () => MeetingScope.personal,
            )
          : null,
      targetAudience: map['targetAudience'],
      createdBy: map['createdBy'],
      scope: map['scope'],
      teamId: map['teamId'],
      departmentId: map['departmentId'],
      recipients: map['recipients'] != null ? List<String>.from(map['recipients']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'meetingId': meetingId,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'actionData': actionData,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'meetingTitle': meetingTitle,
      'meetingScope': meetingScope?.toString().split('.').last,
      'targetAudience': targetAudience,
      'createdBy': createdBy,
      'scope': scope,
      'teamId': teamId,
      'departmentId': departmentId,
      'recipients': recipients,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? meetingId,
    String? roomId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? actionData,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? isRead,
    bool? isDelivered,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? meetingTitle,
    MeetingScope? meetingScope,
    String? targetAudience,
    String? createdBy,
    String? scope,
    String? teamId,
    String? departmentId,
    List<String>? recipients,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      meetingId: meetingId ?? this.meetingId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      actionData: actionData ?? this.actionData,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      meetingScope: meetingScope ?? this.meetingScope,
      targetAudience: targetAudience ?? this.targetAudience,
      createdBy: createdBy ?? this.createdBy,
      scope: scope ?? this.scope,
      teamId: teamId ?? this.teamId,
      departmentId: departmentId ?? this.departmentId,
      recipients: recipients ?? this.recipients,
    );
  }

  // Helper methods
  bool get isUnread => !isRead;
  bool get isPending => !isDelivered;
  bool get isScheduled =>
      scheduledAt != null && DateTime.now().isBefore(scheduledAt!);
  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isHigh => priority == NotificationPriority.high;

  String get typeDisplayName {
    switch (type) {
      case NotificationType.meetingApproval:
        return 'Phê duyệt cuộc họp';
      case NotificationType.meetingApprovalResult:
        return 'Kết quả phê duyệt';
      case NotificationType.meetingReminder:
        return 'Nhắc nhở cuộc họp';
      case NotificationType.meetingCancelled:
        return 'Hủy cuộc họp';
      case NotificationType.meetingUpdated:
        return 'Cập nhật cuộc họp';
      case NotificationType.meetingInvitation:
        return 'Thêm vào cuộc họp';
      case NotificationType.roomMaintenance:
        return 'Bảo trì phòng';
      case NotificationType.roleChange:
        return 'Thay đổi vai trò';
      case NotificationType.system:
        return 'Cập nhật hệ thống';
      case NotificationType.general:
        return 'Thông báo chung';
      default:
        return 'Thông báo';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Thấp';
      case NotificationPriority.normal:
        return 'Bình thường';
      case NotificationPriority.high:
        return 'Cao';
      case NotificationPriority.urgent:
        return 'Khẩn cấp';
    }
  }
}

/// Template thông báo để tạo nhanh
class NotificationTemplate {
  static NotificationModel meetingApproval({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required String creatorName,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Cuộc họp cần phê duyệt',
      message: 'Cuộc họp "$meetingTitle" từ $creatorName cần được phê duyệt',
      type: NotificationType.meetingApproval,
      priority: NotificationPriority.high,
      meetingId: meetingId,
      createdAt: DateTime.now(),
      createdBy: creatorName, // Placeholder for actual ID, handle appropriately in Provider.
      recipients: [userId],
    );
  }

  static NotificationModel meetingReminder({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required DateTime meetingTime,
    required int minutesBefore,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Nhắc nhở cuộc họp',
      message: 'Cuộc họp "$meetingTitle" sẽ bắt đầu sau $minutesBefore phút',
      type: NotificationType.meetingReminder,
      priority: NotificationPriority.normal,
      meetingId: meetingId,
      createdAt: DateTime.now(),
      scheduledAt: meetingTime.subtract(Duration(minutes: minutesBefore)),
      recipients: [userId],
    );
  }

  static NotificationModel meetingApprovalResult({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required bool isApproved,
    String? approverName,
    String? notes,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: isApproved ? 'Cuộc họp đã được phê duyệt' : 'Cuộc họp bị từ chối',
      message: isApproved
          ? 'Cuộc họp "$meetingTitle" đã được phê duyệt${approverName != null ? ' bởi $approverName' : ''}'
          : 'Cuộc họp "$meetingTitle" bị từ chối${notes != null ? ': $notes' : ''}',
      type: NotificationType.meetingApprovalResult,
      priority: NotificationPriority.high,
      meetingId: meetingId,
      createdAt: DateTime.now(),
      recipients: [userId],
    );
  }

  static NotificationModel roomMaintenance({
    required String userId,
    required String roomName,
    required String roomId,
    required DateTime maintenanceDate,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Thông báo bảo trì phòng',
      message:
          'Phòng "$roomName" sẽ được bảo trì vào ${maintenanceDate.day}/${maintenanceDate.month}/${maintenanceDate.year}',
      type: NotificationType.roomMaintenance,
      priority: NotificationPriority.normal,
      roomId: roomId,
      createdAt: DateTime.now(),
      recipients: [userId],
    );
  }

  static NotificationModel meetingApprovalRequest({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required String creatorName,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Yêu cầu phê duyệt cuộc họp',
      message: '$creatorName đã tạo cuộc họp "$meetingTitle" và cần bạn phê duyệt.',
      type: NotificationType.meetingApproval,
      priority: NotificationPriority.high,
      isRead: false,
      createdAt: DateTime.now(),
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      recipients: [userId],
    );
  }

  static NotificationModel meetingApproved({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required String approverName,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Cuộc họp đã được phê duyệt',
      message: 'Cuộc họp "$meetingTitle" của bạn đã được $approverName phê duyệt.',
      type: NotificationType.meetingApprovalResult,
      priority: NotificationPriority.high,
      isRead: false,
      createdAt: DateTime.now(),
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      recipients: [userId],
    );
  }

  static NotificationModel meetingRejected({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required String rejectorName,
    required String reason,
  }) {
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Cuộc họp bị từ chối',
      message: 'Cuộc họp "$meetingTitle" đã bị $rejectorName từ chối. Lý do: $reason',
      type: NotificationType.meetingApprovalResult,
      priority: NotificationPriority.high,
      isRead: false,
      createdAt: DateTime.now(),
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      recipients: [userId],
    );
  }

  static NotificationModel meetingInvitation({
    required String userId,
    required String meetingTitle,
    required String meetingId,
    required DateTime meetingTime,
    required String creatorName,
  }) {
    // Format meeting time
    final formattedTime = '${meetingTime.day.toString().padLeft(2, '0')}/${meetingTime.month.toString().padLeft(2, '0')}/${meetingTime.year} lúc ${meetingTime.hour.toString().padLeft(2, '0')}:${meetingTime.minute.toString().padLeft(2, '0')}';
    
    return NotificationModel(
      id: '',
      userId: userId,
      title: 'Bạn đã được thêm vào cuộc họp',
      message: 'Bạn đã được thêm vào cuộc họp "$meetingTitle" vào $formattedTime. Người tạo: $creatorName.',
      type: NotificationType.meetingInvitation,
      priority: NotificationPriority.normal,
      isRead: false,
      createdAt: DateTime.now(),
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      recipients: [userId],
    );
  }

  /// Nhắc nhở đặt phòng nhanh - 15 phút trước giờ bắt đầu
  static NotificationModel bookingReminder({
    required String userId,
    required String bookingId,
    required String bookingTitle,
    required String roomName,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final formattedTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final formattedEndTime = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    
    return NotificationModel(
      id: '',
      userId: userId,
      title: '⏰ Đặt phòng sắp bắt đầu!',
      message: 'Phòng $roomName ($formattedTime - $formattedEndTime) sẽ bắt đầu sau 15 phút. Vui lòng tạo cuộc họp ngay để xác nhận.',
      type: NotificationType.bookingReminder,
      priority: NotificationPriority.urgent,
      isRead: false,
      createdAt: DateTime.now(),
      roomId: bookingId, // Using roomId field to store bookingId
      actionData: {
        'bookingId': bookingId,
        'roomName': roomName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'action': 'create_meeting',
      },
      recipients: [userId],
    );
  }

  /// Thông báo đặt phòng đã hết hạn (auto-released)
  static NotificationModel bookingExpired({
    required String userId,
    required String bookingTitle,
    required String roomName,
    required DateTime startTime,
  }) {
    final formattedTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    
    return NotificationModel(
      id: '',
      userId: userId,
      title: '⚠️ Đặt phòng đã bị hủy',
      message: 'Đặt phòng "$bookingTitle" tại $roomName ($formattedTime) đã bị hủy do không tạo cuộc họp kịp thời. Đây là 1 lần vi phạm.',
      type: NotificationType.bookingExpired,
      priority: NotificationPriority.high,
      isRead: false,
      createdAt: DateTime.now(),
      recipients: [userId],
    );
  }

  /// Thông báo đặt phòng cần admin duyệt (restricted user)
  static NotificationModel bookingNeedsAdminApproval({
    required String userId,
    required String bookingTitle,
    required String roomName,
    required DateTime startTime,
  }) {
    final formattedTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    
    return NotificationModel(
      id: '',
      userId: userId,
      title: '🔒 Đặt phòng chờ duyệt',
      message: 'Đặt phòng "$bookingTitle" tại $roomName ($formattedTime) đang chờ admin duyệt do bạn đang bị hạn chế.',
      type: NotificationType.bookingApprovalRequired,
      priority: NotificationPriority.normal,
      isRead: false,
      createdAt: DateTime.now(),
      recipients: [userId],
    );
  }

  /// Thông báo cho Admin về booking cần duyệt
  static NotificationModel adminBookingApprovalRequest({
    required String adminId,
    required String bookingTitle,
    required String roomName,
    required String userName,
    required String bookingId,
    required DateTime startTime,
  }) {
    final formattedTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    
    return NotificationModel(
      id: '',
      userId: adminId,
      title: '📋 Yêu cầu duyệt đặt phòng',
      message: '$userName (đang bị hạn chế) yêu cầu đặt phòng "$bookingTitle" tại $roomName lúc $formattedTime.',
      type: NotificationType.bookingApprovalRequired,
      priority: NotificationPriority.high,
      isRead: false,
      createdAt: DateTime.now(),
      actionData: {
        'bookingId': bookingId,
        'action': 'approve_booking',
      },
      recipients: [adminId],
    );
  }
}
