import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

enum MeetingStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed,
  expired, // Pending meeting that exceeded TTL
}

/// Room booking status for UI display
enum RoomBookingStatus {
  available,      // Room is free for the time range
  pendingReserved, // Room is reserved by a pending meeting (soft lock)
  booked,         // Room is booked by an approved meeting
  maintenance,    // Room is under maintenance
  disabled,       // Room is disabled
}

enum MeetingType { personal, team, department, company }

enum MeetingPriority { low, medium, high, urgent }

enum MeetingLocationType {
  physical, // Trực tiếp
  virtual, // Trực tuyến
  hybrid, // Kết hợp
}

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

/// Cấp độ phê duyệt (dựa trên thành phần tham gia)
enum MeetingApprovalLevel {
  team,
  department,
  company,
}

/// Trạng thái phản hồi lời mời tham gia cuộc họp
enum ParticipantAttendanceStatus {
  pending,   // Chờ phản hồi
  accepted,  // Đã xác nhận
  declined,  // Từ chối
  tentative, // Có thể tham gia
}

extension ParticipantAttendanceStatusX on ParticipantAttendanceStatus {
  String get value => toString().split('.').last;

  String get label {
    switch (this) {
      case ParticipantAttendanceStatus.pending:   return 'Chờ phản hồi';
      case ParticipantAttendanceStatus.accepted:  return 'Đã xác nhận';
      case ParticipantAttendanceStatus.declined:  return 'Từ chối';
      case ParticipantAttendanceStatus.tentative: return 'Có thể';
    }
  }

  static ParticipantAttendanceStatus fromString(String? s) {
    switch (s) {
      case 'accepted':  return ParticipantAttendanceStatus.accepted;
      case 'declined':  return ParticipantAttendanceStatus.declined;
      case 'tentative': return ParticipantAttendanceStatus.tentative;
      default:          return ParticipantAttendanceStatus.pending;
    }
  }
}

class MeetingParticipant {
  final String userId;
  final String userName;
  final String userEmail;
  final String role; // chair, secretary, presenter, participant
  final bool isRequired;
  /// Attendance status — replaces hasConfirmed bool
  final ParticipantAttendanceStatus attendanceStatus;
  final DateTime? confirmedAt;
  final DateTime? respondedAt;

  MeetingParticipant({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    this.isRequired = true,
    this.attendanceStatus = ParticipantAttendanceStatus.pending,
    this.confirmedAt,
    this.respondedAt,
  });

  /// Backward-compat: hasConfirmed = attendanceStatus is accepted
  bool get hasConfirmed => attendanceStatus == ParticipantAttendanceStatus.accepted;

  factory MeetingParticipant.fromMap(Map<String, dynamic> map) {
    // Backward-compat: old docs may have hasConfirmed bool instead of attendanceStatus
    ParticipantAttendanceStatus status;
    if (map['attendanceStatus'] != null) {
      status = ParticipantAttendanceStatusX.fromString(map['attendanceStatus'] as String?);
    } else if (map['hasConfirmed'] == true) {
      status = ParticipantAttendanceStatus.accepted;
      print('[MEETING][FROM_MAP] Fallback hasConfirmed=true -> status=$status for userId=${map['userId']}');
    } else {
      status = ParticipantAttendanceStatus.pending;
      print('[MEETING][FROM_MAP] Fallback hasConfirmed=${map['hasConfirmed']} -> status=$status for userId=${map['userId']}');
    }

    return MeetingParticipant(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      role: map['role'] ?? 'participant',
      isRequired: map['isRequired'] ?? true,
      attendanceStatus: status,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
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
      'attendanceStatus': attendanceStatus.value,
      'hasConfirmed': hasConfirmed, // keep for Firestore rules & backward compat
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// Copy with updated fields
  MeetingParticipant copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? role,
    bool? isRequired,
    ParticipantAttendanceStatus? attendanceStatus,
    DateTime? confirmedAt,
    DateTime? respondedAt,
  }) {
    return MeetingParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      isRequired: isRequired ?? this.isRequired,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
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
  final String? roomId; // ID phòng họp từ Firestore (required for physical meetings)
  final String? roomName; // Snapshot tên phòng để hiển thị nhanh
  final String? physicalLocation; // Legacy field, giữ cho backward compatibility
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
  final DateTime? expiresAt; // TTL for pending meetings - auto-expire if not approved
  final String? departmentId;
  final String? departmentName;
  final String? teamId;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly
  final DateTime? recurringEndDate;

  // Settings
  final bool allowJoinBeforeHost;
  final bool muteOnEntry;
  final bool recordMeeting;
  final bool requirePassword;

  final MeetingScope scope;
  final MeetingApprovalStatus approvalStatus;
  final MeetingApprovalLevel approvalLevel;
  final String? approvalReason;
  final String? targetDepartmentId;
  final String? targetTeamId;
  final String? approvedBy;
  final String? rejectedBy;
  final DateTime? rejectedAt;
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
    this.roomId,
    this.roomName,
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
    this.expiresAt,
    this.departmentId,
    this.departmentName,
    this.teamId,
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
    this.approvalLevel = MeetingApprovalLevel.team,
    this.approvalReason,
    this.targetDepartmentId,
    this.targetTeamId,
    this.approvedBy,
    this.rejectedBy,
    this.rejectedAt,
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
      roomId: map['roomId'],
      roomName: map['roomName'],
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
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      departmentId: map['departmentId'],
      departmentName: map['departmentName'],
      teamId: map['teamId'],
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
      approvalLevel: MeetingApprovalLevel.values.firstWhere(
        (level) =>
            level.toString() ==
            'MeetingApprovalLevel.${map['approvalLevel'] ?? 'team'}',
        orElse: () => MeetingApprovalLevel.team,
      ),
      approvalReason: map['approvalReason'],
      targetDepartmentId: map['targetDepartmentId'],
      targetTeamId: map['targetTeamId'],
      approvedBy: map['approvedBy'],
      rejectedBy: map['rejectedBy'],
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
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
      'roomId': roomId,
      'roomName': roomName,
      'physicalLocation': physicalLocation,
      'virtualMeetingLink': virtualMeetingLink,
      'virtualMeetingPassword': virtualMeetingPassword,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'participants': participants.map((p) => p.toMap()).toList(),
      'participantIds': participants.map((p) => p.userId).toList(),
      'secretaryId': participants.where((p) => p.role == 'secretary').map((p) => p.userId).firstOrNull,
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
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'teamId': teamId,
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
      'approvalLevel': approvalLevel.toString().split('.').last,
      'approvalReason': approvalReason,
      'targetDepartmentId': targetDepartmentId,
      'targetTeamId': targetTeamId,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
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
    String? roomId,
    String? roomName,
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
    DateTime? expiresAt,
    String? departmentId,
    String? departmentName,
    String? teamId,
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
    MeetingApprovalLevel? approvalLevel,
    String? approvalReason,
    String? targetDepartmentId,
    String? targetTeamId,
    String? approvedBy,
    String? rejectedBy,
    DateTime? rejectedAt,
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
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
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
      expiresAt: expiresAt ?? this.expiresAt,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      teamId: teamId ?? this.teamId,
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
      approvalLevel: approvalLevel ?? this.approvalLevel,
      approvalReason: approvalReason ?? this.approvalReason,
      targetDepartmentId: targetDepartmentId ?? this.targetDepartmentId,
      targetTeamId: targetTeamId ?? this.targetTeamId,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
    );
  }

  // Helper methods
  bool get isPending => status == MeetingStatus.pending;
  bool get isApproved => status == MeetingStatus.approved;
  bool get isRejected => status == MeetingStatus.rejected;
  bool get isExpired => status == MeetingStatus.expired;
  
  /// Check if a pending meeting has exceeded its TTL
  bool get isPendingExpired {
    if (status != MeetingStatus.pending) return false;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Check if this meeting actively blocks a room (approved OR pending not expired)
  bool get blocksRoom {
    if (status == MeetingStatus.approved) return true;
    if (status == MeetingStatus.pending && !isPendingExpired) return true;
    return false;
  }
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
      DateTime.now().isAfter(startTime.subtract(const Duration(minutes: 15)));
  bool get isOngoing =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get isPast => DateTime.now().isAfter(endTime);

  int get participantCount => participants.length;
  int get confirmedCount => participants.where((p) => p.hasConfirmed).length;
  double get confirmationRate =>
      participantCount > 0 ? confirmedCount / participantCount : 0.0;
}

// Task Model for task management
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final String assigneeRole;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'completed'
  final double progress; // 0-100
  final DateTime deadline;
  final DateTime createdAt;
  final String? fromDecisionId;
  final String meetingId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeRole,
    required this.priority,
    required this.status,
    required this.progress,
    required this.deadline,
    required this.createdAt,
    this.fromDecisionId,
    required this.meetingId,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assigneeId: map['assigneeId'] ?? '',
      assigneeName: map['assigneeName'] ?? '',
      assigneeRole: map['assigneeRole'] ?? '',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      progress: (map['progress'] ?? 0.0).toDouble(),
      deadline: map['deadline'] != null
          ? (map['deadline'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fromDecisionId: map['fromDecisionId'],
      meetingId: map['meetingId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeRole': assigneeRole,
      'priority': priority,
      'status': status,
      'progress': progress,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'fromDecisionId': fromDecisionId,
      'meetingId': meetingId,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    String? assigneeRole,
    String? priority,
    String? status,
    double? progress,
    DateTime? deadline,
    DateTime? createdAt,
    String? fromDecisionId,
    String? meetingId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeRole: assigneeRole ?? this.assigneeRole,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      fromDecisionId: fromDecisionId ?? this.fromDecisionId,
      meetingId: meetingId ?? this.meetingId,
    );
  }
}

