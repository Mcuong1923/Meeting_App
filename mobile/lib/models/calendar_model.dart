import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metting_app/models/meeting_model.dart';
import 'package:metting_app/models/user_role.dart';

/// Loại sự kiện trong lịch
enum CalendarEventType {
  meeting, // Cuộc họp
  reminder, // Nhắc nhở
  maintenance, // Bảo trì
  holiday, // Ngày lễ
  personal, // Cá nhân
  deadline, // Deadline
  other, // Khác
}

/// Mức độ ưu tiên sự kiện
enum CalendarEventPriority {
  low,
  medium,
  high,
  urgent,
}

/// Model sự kiện trong lịch
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final CalendarEventType type;
  final CalendarEventPriority priority;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? meetingId;
  final String? roomId;
  final String creatorId;
  final String creatorName;
  final List<String> participantIds;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime? recurringEndDate;
  final String? color;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.priority = CalendarEventPriority.medium,
    required this.startTime,
    required this.endTime,
    this.location,
    this.meetingId,
    this.roomId,
    required this.creatorId,
    required this.creatorName,
    this.participantIds = const [],
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringEndDate,
    this.color,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map, String id) {
    return CalendarEvent(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      type: CalendarEventType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => CalendarEventType.other,
      ),
      priority: CalendarEventPriority.values.firstWhere(
        (priority) => priority.toString().split('.').last == map['priority'],
        orElse: () => CalendarEventPriority.medium,
      ),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      location: map['location'],
      meetingId: map['meetingId'],
      roomId: map['roomId'],
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      isAllDay: map['isAllDay'] ?? false,
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      recurringEndDate: map['recurringEndDate'] != null
          ? (map['recurringEndDate'] as Timestamp).toDate()
          : null,
      color: map['color'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'meetingId': meetingId,
      'roomId': roomId,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'participantIds': participantIds,
      'isAllDay': isAllDay,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'recurringEndDate': recurringEndDate != null
          ? Timestamp.fromDate(recurringEndDate!)
          : null,
      'color': color,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    CalendarEventType? type,
    CalendarEventPriority? priority,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? meetingId,
    String? roomId,
    String? creatorId,
    String? creatorName,
    List<String>? participantIds,
    bool? isAllDay,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? recurringEndDate,
    String? color,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      meetingId: meetingId ?? this.meetingId,
      roomId: roomId ?? this.roomId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      participantIds: participantIds ?? this.participantIds,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  Duration get duration => endTime.difference(startTime);
  bool get isToday {
    final now = DateTime.now();
    return startTime.day == now.day &&
        startTime.month == now.month &&
        startTime.year == now.year;
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isOngoing {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  bool get isUrgent => priority == CalendarEventPriority.urgent;
  bool get isHigh => priority == CalendarEventPriority.high;

  String get typeDisplayName {
    switch (type) {
      case CalendarEventType.meeting:
        return 'Cuộc họp';
      case CalendarEventType.reminder:
        return 'Nhắc nhở';
      case CalendarEventType.maintenance:
        return 'Bảo trì';
      case CalendarEventType.holiday:
        return 'Ngày lễ';
      case CalendarEventType.personal:
        return 'Cá nhân';
      case CalendarEventType.deadline:
        return 'Deadline';
      case CalendarEventType.other:
        return 'Khác';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case CalendarEventPriority.low:
        return 'Thấp';
      case CalendarEventPriority.medium:
        return 'Trung bình';
      case CalendarEventPriority.high:
        return 'Cao';
      case CalendarEventPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  /// Tạo CalendarEvent từ MeetingModel
  static CalendarEvent fromMeeting(MeetingModel meeting) {
    return CalendarEvent(
      id: 'meeting_${meeting.id}',
      title: meeting.title,
      description: meeting.description,
      type: CalendarEventType.meeting,
      priority: _convertMeetingPriority(meeting.priority),
      startTime: meeting.startTime,
      endTime: meeting.endTime,
      location: meeting.isVirtual ? 'Trực tuyến' : meeting.physicalLocation,
      meetingId: meeting.id,
      creatorId: meeting.creatorId,
      creatorName: meeting.creatorName,
      participantIds: meeting.participants.map((p) => p.userId).toList(),
      color: _getMeetingColor(meeting.status),
      metadata: {
        'meetingType': meeting.type.toString().split('.').last,
        'meetingStatus': meeting.status.toString().split('.').last,
        'locationType': meeting.locationType.toString().split('.').last,
      },
      createdAt: meeting.createdAt,
      updatedAt: meeting.updatedAt,
    );
  }

  static CalendarEventPriority _convertMeetingPriority(
      MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return CalendarEventPriority.low;
      case MeetingPriority.medium:
        return CalendarEventPriority.medium;
      case MeetingPriority.high:
        return CalendarEventPriority.high;
      case MeetingPriority.urgent:
        return CalendarEventPriority.urgent;
    }
  }

  static String _getMeetingColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.pending:
        return '#FFA726'; // Orange
      case MeetingStatus.approved:
        return '#66BB6A'; // Green
      case MeetingStatus.rejected:
        return '#EF5350'; // Red
      case MeetingStatus.cancelled:
        return '#BDBDBD'; // Grey
      case MeetingStatus.completed:
        return '#42A5F5'; // Blue
    }
  }
}

/// Model cho calendar view configuration
class CalendarViewConfig {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final CalendarFormat format;
  final bool weekendsVisible;
  final bool holidaysVisible;
  final Map<String, bool> eventTypesVisible;

  CalendarViewConfig({
    required this.focusedDay,
    this.selectedDay,
    required this.firstDay,
    required this.lastDay,
    this.format = CalendarFormat.month,
    this.weekendsVisible = true,
    this.holidaysVisible = true,
    this.eventTypesVisible = const {},
  });

  CalendarViewConfig copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    DateTime? firstDay,
    DateTime? lastDay,
    CalendarFormat? format,
    bool? weekendsVisible,
    bool? holidaysVisible,
    Map<String, bool>? eventTypesVisible,
  }) {
    return CalendarViewConfig(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      firstDay: firstDay ?? this.firstDay,
      lastDay: lastDay ?? this.lastDay,
      format: format ?? this.format,
      weekendsVisible: weekendsVisible ?? this.weekendsVisible,
      holidaysVisible: holidaysVisible ?? this.holidaysVisible,
      eventTypesVisible: eventTypesVisible ?? this.eventTypesVisible,
    );
  }
}

/// Calendar format enum
enum CalendarFormat {
  month,
  twoWeeks,
  week,
}

/// Time slot cho scheduling
class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? reason; // Lý do không available

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.reason,
  });

  Duration get duration => endTime.difference(startTime);

  bool conflictsWith(TimeSlot other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }
}

/// Conflict detection result
class ScheduleConflict {
  final CalendarEvent event1;
  final CalendarEvent event2;
  final String description;
  final ConflictSeverity severity;

  ScheduleConflict({
    required this.event1,
    required this.event2,
    required this.description,
    required this.severity,
  });
}

enum ConflictSeverity {
  low, // Có thể chấp nhận
  medium, // Cần cân nhắc
  high, // Nên tránh
  critical, // Không thể chấp nhận
}
