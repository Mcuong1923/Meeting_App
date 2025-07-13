import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

enum MeetingStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed,
}

enum MeetingType { personal, team, department, company }

enum MeetingPriority { low, medium, high, urgent }

enum MeetingLocationType { physical, virtual, hybrid }

/// Phạm vi cuộc họp
enum MeetingScope {
  personal, // Cá nhân
  team, // Team
  department, // Phòng ban
  company, // Công ty
}

/// Trạng thái phê duyệt
enum MeetingApprovalStatus {
  pending, // Chờ duyệt
  approved, // Đã duyệt
  rejected, // Từ chối
  auto_approved, // Tự động duyệt
}

class MeetingParticipant {
  final String userId;
  final String userName;
  final String userEmail;
  final String role; // chair, secretary, presenter, participant
  final bool isRequired;
  final bool hasConfirmed;
  final DateTime? confirmedAt;

  MeetingParticipant({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    this.isRequired = true,
    this.hasConfirmed = false,
    this.confirmedAt,
  });

  factory MeetingParticipant.fromMap(Map<String, dynamic> map) {
    return MeetingParticipant(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      role: map['role'] ?? 'participant',
      isRequired: map['isRequired'] ?? true,
      hasConfirmed: map['hasConfirmed'] ?? false,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role,
      'isRequired': isRequired,
      'hasConfirmed': hasConfirmed,
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    };
  }
}

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final MeetingType type;
  final MeetingStatus status;
  final MeetingLocationType locationType;
  final MeetingPriority priority;

  // Thời gian
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  // Địa điểm
  final String? physicalLocation;
  final String? virtualMeetingLink;
  final String? virtualMeetingPassword;

  // Người tạo và tham gia
  final String creatorId;
  final String creatorName;
  final List<MeetingParticipant> participants;

  // Nội dung
  final String? agenda;
  final List<String> attachments;
  final String? meetingNotes;
  final List<String> actionItems;

  // Phê duyệt
  final String? approverId;
  final String? approverName;
  final DateTime? approvedAt;
  final String? approvalNotes;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? departmentId;
  final String? departmentName;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly
  final DateTime? recurringEndDate;

  // Settings
  final bool allowJoinBeforeHost;
  final bool muteOnEntry;
  final bool recordMeeting;
  final bool requirePassword;

  // Meeting scope and approval
  final MeetingScope scope;
  final MeetingApprovalStatus approvalStatus;
  final String? targetDepartmentId;
  final String? targetTeamId;
  final String? approvedBy;
  final String? rejectedReason;

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.locationType,
    required this.priority,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.physicalLocation,
    this.virtualMeetingLink,
    this.virtualMeetingPassword,
    required this.creatorId,
    required this.creatorName,
    required this.participants,
    this.agenda,
    this.attachments = const [],
    this.meetingNotes,
    this.actionItems = const [],
    this.approverId,
    this.approverName,
    this.approvedAt,
    this.approvalNotes,
    required this.createdAt,
    required this.updatedAt,
    this.departmentId,
    this.departmentName,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringEndDate,
    this.allowJoinBeforeHost = true,
    this.muteOnEntry = false,
    this.recordMeeting = false,
    this.requirePassword = false,
    required this.scope,
    required this.approvalStatus,
    this.targetDepartmentId,
    this.targetTeamId,
    this.approvedBy,
    this.rejectedReason,
  });

  factory MeetingModel.fromMap(Map<String, dynamic> map, String id) {
    return MeetingModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: MeetingType.values.firstWhere(
        (type) => type.toString() == 'MeetingType.${map['type'] ?? 'personal'}',
        orElse: () => MeetingType.personal,
      ),
      status: MeetingStatus.values.firstWhere(
        (status) =>
            status.toString() == 'MeetingStatus.${map['status'] ?? 'pending'}',
        orElse: () => MeetingStatus.pending,
      ),
      locationType: MeetingLocationType.values.firstWhere(
        (locationType) =>
            locationType.toString() ==
            'MeetingLocationType.${map['locationType'] ?? 'physical'}',
        orElse: () => MeetingLocationType.physical,
      ),
      priority: MeetingPriority.values.firstWhere(
        (priority) =>
            priority.toString() ==
            'MeetingPriority.${map['priority'] ?? 'medium'}',
        orElse: () => MeetingPriority.medium,
      ),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 60,
      physicalLocation: map['physicalLocation'],
      virtualMeetingLink: map['virtualMeetingLink'],
      virtualMeetingPassword: map['virtualMeetingPassword'],
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      participants: (map['participants'] as List<dynamic>?)
              ?.map((p) => MeetingParticipant.fromMap(p))
              .toList() ??
          [],
      agenda: map['agenda'],
      attachments: List<String>.from(map['attachments'] ?? []),
      meetingNotes: map['meetingNotes'],
      actionItems: List<String>.from(map['actionItems'] ?? []),
      approverId: map['approverId'],
      approverName: map['approverName'],
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      approvalNotes: map['approvalNotes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      departmentId: map['departmentId'],
      departmentName: map['departmentName'],
      tags: List<String>.from(map['tags'] ?? []),
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      recurringEndDate: map['recurringEndDate'] != null
          ? (map['recurringEndDate'] as Timestamp).toDate()
          : null,
      allowJoinBeforeHost: map['allowJoinBeforeHost'] ?? true,
      muteOnEntry: map['muteOnEntry'] ?? false,
      recordMeeting: map['recordMeeting'] ?? false,
      requirePassword: map['requirePassword'] ?? false,
      scope: MeetingScope.values.firstWhere(
        (scope) =>
            scope.toString() == 'MeetingScope.${map['scope'] ?? 'personal'}',
        orElse: () => MeetingScope.personal,
      ),
      approvalStatus: MeetingApprovalStatus.values.firstWhere(
        (status) =>
            status.toString() ==
            'MeetingApprovalStatus.${map['approvalStatus'] ?? 'pending'}',
        orElse: () => MeetingApprovalStatus.pending,
      ),
      targetDepartmentId: map['targetDepartmentId'],
      targetTeamId: map['targetTeamId'],
      approvedBy: map['approvedBy'],
      rejectedReason: map['rejectedReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'locationType': locationType.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'physicalLocation': physicalLocation,
      'virtualMeetingLink': virtualMeetingLink,
      'virtualMeetingLink': virtualMeetingLink,
      'virtualMeetingPassword': virtualMeetingPassword,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'participants': participants.map((p) => p.toMap()).toList(),
      'agenda': agenda,
      'attachments': attachments,
      'meetingNotes': meetingNotes,
      'actionItems': actionItems,
      'approverId': approverId,
      'approverName': approverName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvalNotes': approvalNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'departmentId': departmentId,
      'departmentName': departmentName,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'recurringEndDate': recurringEndDate != null
          ? Timestamp.fromDate(recurringEndDate!)
          : null,
      'allowJoinBeforeHost': allowJoinBeforeHost,
      'muteOnEntry': muteOnEntry,
      'recordMeeting': recordMeeting,
      'requirePassword': requirePassword,
      'scope': scope.toString().split('.').last,
      'approvalStatus': approvalStatus.toString().split('.').last,
      'targetDepartmentId': targetDepartmentId,
      'targetTeamId': targetTeamId,
      'approvedBy': approvedBy,
      'rejectedReason': rejectedReason,
    };
  }

  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    MeetingType? type,
    MeetingStatus? status,
    MeetingLocationType? locationType,
    MeetingPriority? priority,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? physicalLocation,
    String? virtualMeetingLink,
    String? virtualMeetingPassword,
    String? creatorId,
    String? creatorName,
    List<MeetingParticipant>? participants,
    String? agenda,
    List<String>? attachments,
    String? meetingNotes,
    List<String>? actionItems,
    String? approverId,
    String? approverName,
    DateTime? approvedAt,
    String? approvalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? departmentId,
    String? departmentName,
    List<String>? tags,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? recurringEndDate,
    bool? allowJoinBeforeHost,
    bool? muteOnEntry,
    bool? recordMeeting,
    bool? requirePassword,
    MeetingScope? scope,
    MeetingApprovalStatus? approvalStatus,
    String? targetDepartmentId,
    String? targetTeamId,
    String? approvedBy,
    String? rejectedReason,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      locationType: locationType ?? this.locationType,
      priority: priority ?? this.priority,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      physicalLocation: physicalLocation ?? this.physicalLocation,
      virtualMeetingLink: virtualMeetingLink ?? this.virtualMeetingLink,
      virtualMeetingPassword:
          virtualMeetingPassword ?? this.virtualMeetingPassword,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      participants: participants ?? this.participants,
      agenda: agenda ?? this.agenda,
      attachments: attachments ?? this.attachments,
      meetingNotes: meetingNotes ?? this.meetingNotes,
      actionItems: actionItems ?? this.actionItems,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      approvedAt: approvedAt ?? this.approvedAt,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      allowJoinBeforeHost: allowJoinBeforeHost ?? this.allowJoinBeforeHost,
      muteOnEntry: muteOnEntry ?? this.muteOnEntry,
      recordMeeting: recordMeeting ?? this.recordMeeting,
      requirePassword: requirePassword ?? this.requirePassword,
      scope: scope ?? this.scope,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      targetDepartmentId: targetDepartmentId ?? this.targetDepartmentId,
      targetTeamId: targetTeamId ?? this.targetTeamId,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedReason: rejectedReason ?? this.rejectedReason,
    );
  }

  // Helper methods
  bool get isPending => status == MeetingStatus.pending;
  bool get isApproved => status == MeetingStatus.approved;
  bool get isRejected => status == MeetingStatus.rejected;
  bool get isCancelled => status == MeetingStatus.cancelled;
  bool get isCompleted => status == MeetingStatus.completed;

  bool get isVirtual => locationType == MeetingLocationType.virtual;
  bool get isPhysical => locationType == MeetingLocationType.physical;
  bool get isHybrid => locationType == MeetingLocationType.hybrid;

  bool get isUrgent => priority == MeetingPriority.urgent;
  bool get isHigh => priority == MeetingPriority.high;

  bool get needsApproval => isPending;
  bool get canJoin =>
      isApproved &&
      DateTime.now().isAfter(startTime.subtract(Duration(minutes: 15)));
  bool get isOngoing =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get isPast => DateTime.now().isAfter(endTime);

  int get participantCount => participants.length;
  int get confirmedCount => participants.where((p) => p.hasConfirmed).length;
  double get confirmationRate =>
      participantCount > 0 ? confirmedCount / participantCount : 0.0;
}
