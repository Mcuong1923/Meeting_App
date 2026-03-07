import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại booking
enum BookingType {
  quickBooking,    // Đặt nhanh - cần chuyển thành meeting
  meetingBooking,  // Đặt từ meeting
}

/// Trạng thái booking phòng họp
enum BookingStatus {
  reserved,         // Đã giữ chỗ (quick booking)
  pending,          // Chờ duyệt
  approved,         // Đã duyệt
  rejected,         // Từ chối
  cancelled,        // Đã hủy
  completed,        // Hoàn thành
  converted,        // Đã chuyển thành meeting
  releasedBySystem, // Tự động giải phóng (không chuyển thành meeting)
}

/// Trạng thái duyệt cho restricted users
enum ApprovalStatus {
  none,             // Không cần duyệt
  pendingApproval,  // Đang chờ admin duyệt (restricted user)
  adminApproved,    // Admin đã duyệt
  adminRejected,    // Admin từ chối
}

/// Lý do bị giải phóng
enum ReleaseReason {
  notConvertedToMeeting, // Không chuyển thành meeting trong 10 phút
  cancelledByUser,       // User tự hủy
  cancelledByAdmin,      // Admin hủy
  bookingExpired,        // Hết hạn
}

/// Loại recurring
enum RecurringType {
  daily,
  weekly,
  monthly,
}

/// Pattern cho recurring booking
class RecurringPattern {
  final RecurringType type;
  final int interval; // every N days/weeks/months
  final List<int>? daysOfWeek; // for weekly: [1,3,5] = Mon, Wed, Fri
  final DateTime endDate;

  RecurringPattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    required this.endDate,
  });

  factory RecurringPattern.fromMap(Map<String, dynamic> map) {
    return RecurringPattern(
      type: RecurringType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => RecurringType.weekly,
      ),
      interval: map['interval'] ?? 1,
      daysOfWeek: map['daysOfWeek'] != null 
          ? List<int>.from(map['daysOfWeek']) 
          : null,
      endDate: (map['endDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endDate': Timestamp.fromDate(endDate),
    };
  }
}

/// Model cho booking phòng họp
class RoomBooking {
  final String id;
  final String roomId;
  final String roomName;
  final String? meetingId; // Link to meeting if exists
  
  // Booking type
  final BookingType type;
  final bool requiresMeeting; // Quick booking requires conversion to meeting
  
  // Time
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  
  // Booking info
  final String title;
  final String? description;
  final String createdBy; // userId
  final String createdByName;
  final String? createdByDepartmentId;
  final DateTime createdAt;
  
  // Status
  final BookingStatus status;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? cancellationReason;
  
  // Quick booking specific
  final ApprovalStatus approvalStatus; // For restricted users
  final ReleaseReason? releaseReason;
  final DateTime? convertedAt; // When converted to meeting
  final bool reminderSent; // 15-min reminder sent
  final DateTime? reminderSentAt;
  
  // Recurring
  final bool isRecurring;
  final String? recurringGroupId;
  final RecurringPattern? recurringPattern;
  
  // Participants
  final List<String> participantIds;
  final List<String> participantNames;

  RoomBooking({
    required this.id,
    required this.roomId,
    required this.roomName,
    this.meetingId,
    this.type = BookingType.meetingBooking,
    this.requiresMeeting = false,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdByName,
    this.createdByDepartmentId,
    required this.createdAt,
    this.status = BookingStatus.pending,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.cancellationReason,
    this.approvalStatus = ApprovalStatus.none,
    this.releaseReason,
    this.convertedAt,
    this.reminderSent = false,
    this.reminderSentAt,
    this.isRecurring = false,
    this.recurringGroupId,
    this.recurringPattern,
    this.participantIds = const [],
    this.participantNames = const [],
  });

  /// Duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;
  
  /// Check if booking is in the past
  bool get isPast => endTime.isBefore(DateTime.now());
  
  /// Check if booking is happening now
  bool get isOngoing {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }
  
  /// Check if booking is in the future
  bool get isFuture => startTime.isAfter(DateTime.now());
  
  /// Check if booking requires approval
  bool get requiresApproval => status == BookingStatus.pending;
  
  /// Check if this is a quick booking
  bool get isQuickBooking => type == BookingType.quickBooking;
  
  /// Check if quick booking needs to be converted to meeting
  bool get needsConversion => 
      isQuickBooking && 
      requiresMeeting && 
      meetingId == null &&
      status == BookingStatus.reserved;
  
  /// Check if quick booking is overdue (past start + 10 minutes without conversion)
  bool get isOverdueForConversion {
    if (!needsConversion) return false;
    final now = DateTime.now();
    final deadline = startTime.add(const Duration(minutes: 10));
    return now.isAfter(deadline);
  }
  
  /// Check if reminder should be sent (15 minutes before start)
  bool get shouldSendReminder {
    if (!needsConversion || reminderSent) return false;
    final now = DateTime.now();
    final reminderTime = startTime.subtract(const Duration(minutes: 15));
    return now.isAfter(reminderTime) && now.isBefore(startTime);
  }
  
  /// Minutes until start
  int get minutesUntilStart {
    final diff = startTime.difference(DateTime.now());
    return diff.inMinutes;
  }
  
  /// Minutes until auto-release deadline
  int get minutesUntilAutoRelease {
    final deadline = startTime.add(const Duration(minutes: 10));
    final diff = deadline.difference(DateTime.now());
    return diff.inMinutes;
  }
  
  /// Check if booking is active (can block room)
  bool get isActive => 
      status == BookingStatus.reserved ||
      status == BookingStatus.pending ||
      status == BookingStatus.approved;
  
  /// Check if restricted user's booking is pending admin approval
  bool get isPendingAdminApproval => 
      approvalStatus == ApprovalStatus.pendingApproval;
  
  /// Status display text
  String get statusText {
    switch (status) {
      case BookingStatus.reserved:
        return 'Đã giữ chỗ';
      case BookingStatus.pending:
        return 'Chờ duyệt';
      case BookingStatus.approved:
        return 'Đã duyệt';
      case BookingStatus.rejected:
        return 'Từ chối';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.converted:
        return 'Đã tạo cuộc họp';
      case BookingStatus.releasedBySystem:
        return 'Đã giải phóng';
    }
  }
  
  /// Approval status display text
  String get approvalStatusText {
    switch (approvalStatus) {
      case ApprovalStatus.none:
        return '';
      case ApprovalStatus.pendingApproval:
        return 'Chờ admin duyệt';
      case ApprovalStatus.adminApproved:
        return 'Admin đã duyệt';
      case ApprovalStatus.adminRejected:
        return 'Admin từ chối';
    }
  }

  factory RoomBooking.fromMap(Map<String, dynamic> map, String id) {
    return RoomBooking(
      id: id,
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      meetingId: map['meetingId'],
      type: BookingType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => BookingType.meetingBooking,
      ),
      requiresMeeting: map['requiresMeeting'] ?? false,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      isAllDay: map['isAllDay'] ?? false,
      title: map['title'] ?? '',
      description: map['description'],
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdByDepartmentId: map['createdByDepartmentId'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],
      approvedAt: map['approvedAt'] != null 
          ? (map['approvedAt'] as Timestamp).toDate() 
          : null,
      rejectionReason: map['rejectionReason'],
      cancellationReason: map['cancellationReason'],
      approvalStatus: ApprovalStatus.values.firstWhere(
        (s) => s.name == map['approvalStatus'],
        orElse: () => ApprovalStatus.none,
      ),
      releaseReason: map['releaseReason'] != null 
          ? ReleaseReason.values.firstWhere(
              (r) => r.name == map['releaseReason'],
              orElse: () => ReleaseReason.notConvertedToMeeting,
            )
          : null,
      convertedAt: map['convertedAt'] != null 
          ? (map['convertedAt'] as Timestamp).toDate() 
          : null,
      reminderSent: map['reminderSent'] ?? false,
      reminderSentAt: map['reminderSentAt'] != null 
          ? (map['reminderSentAt'] as Timestamp).toDate() 
          : null,
      isRecurring: map['isRecurring'] ?? false,
      recurringGroupId: map['recurringGroupId'],
      recurringPattern: map['recurringPattern'] != null 
          ? RecurringPattern.fromMap(map['recurringPattern']) 
          : null,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: List<String>.from(map['participantNames'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'meetingId': meetingId,
      'type': type.name,
      'requiresMeeting': requiresMeeting,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAllDay': isAllDay,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByDepartmentId': createdByDepartmentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'cancellationReason': cancellationReason,
      'approvalStatus': approvalStatus.name,
      'releaseReason': releaseReason?.name,
      'convertedAt': convertedAt != null ? Timestamp.fromDate(convertedAt!) : null,
      'reminderSent': reminderSent,
      'reminderSentAt': reminderSentAt != null ? Timestamp.fromDate(reminderSentAt!) : null,
      'isRecurring': isRecurring,
      'recurringGroupId': recurringGroupId,
      'recurringPattern': recurringPattern?.toMap(),
      'participantIds': participantIds,
      'participantNames': participantNames,
    };
  }

  RoomBooking copyWith({
    String? id,
    String? roomId,
    String? roomName,
    String? meetingId,
    BookingType? type,
    bool? requiresMeeting,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? title,
    String? description,
    String? createdBy,
    String? createdByName,
    String? createdByDepartmentId,
    DateTime? createdAt,
    BookingStatus? status,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? cancellationReason,
    ApprovalStatus? approvalStatus,
    ReleaseReason? releaseReason,
    DateTime? convertedAt,
    bool? reminderSent,
    DateTime? reminderSentAt,
    bool? isRecurring,
    String? recurringGroupId,
    RecurringPattern? recurringPattern,
    List<String>? participantIds,
    List<String>? participantNames,
  }) {
    return RoomBooking(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      meetingId: meetingId ?? this.meetingId,
      type: type ?? this.type,
      requiresMeeting: requiresMeeting ?? this.requiresMeeting,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByDepartmentId: createdByDepartmentId ?? this.createdByDepartmentId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      releaseReason: releaseReason ?? this.releaseReason,
      convertedAt: convertedAt ?? this.convertedAt,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringGroupId: recurringGroupId ?? this.recurringGroupId,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
    );
  }
}
