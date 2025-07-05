import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại analytics event
enum AnalyticsEventType {
  meetingCreated,
  meetingJoined,
  meetingCancelled,
  meetingCompleted,
  userLogin,
  userLogout,
  fileUploaded,
  fileDownloaded,
  notificationSent,
  notificationRead,
  roomBooked,
  roomCancelled,
  profileUpdated,
  roleChanged,
  searchPerformed,
  settingsChanged,
}

/// Thời gian báo cáo
enum ReportPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

/// Loại biểu đồ
enum ChartType {
  line,
  bar,
  pie,
  area,
  scatter,
  doughnut,
}

/// Analytics Event Model
class AnalyticsEvent {
  final String id;
  final AnalyticsEventType type;
  final String userId;
  final String? userName;
  final String? targetId; // meetingId, fileId, etc.
  final String? targetType; // meeting, file, etc.
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? sessionId;
  final String? deviceInfo;
  final String? appVersion;

  AnalyticsEvent({
    required this.id,
    required this.type,
    required this.userId,
    this.userName,
    this.targetId,
    this.targetType,
    this.properties = const {},
    required this.timestamp,
    this.sessionId,
    this.deviceInfo,
    this.appVersion,
  });

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map, String id) {
    return AnalyticsEvent(
      id: id,
      type: AnalyticsEventType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => AnalyticsEventType.userLogin,
      ),
      userId: map['userId'] ?? '',
      userName: map['userName'],
      targetId: map['targetId'],
      targetType: map['targetType'],
      properties: Map<String, dynamic>.from(map['properties'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      sessionId: map['sessionId'],
      deviceInfo: map['deviceInfo'],
      appVersion: map['appVersion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'userId': userId,
      'userName': userName,
      'targetId': targetId,
      'targetType': targetType,
      'properties': properties,
      'timestamp': Timestamp.fromDate(timestamp),
      'sessionId': sessionId,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case AnalyticsEventType.meetingCreated:
        return 'Tạo cuộc họp';
      case AnalyticsEventType.meetingJoined:
        return 'Tham gia cuộc họp';
      case AnalyticsEventType.meetingCancelled:
        return 'Hủy cuộc họp';
      case AnalyticsEventType.meetingCompleted:
        return 'Hoàn thành cuộc họp';
      case AnalyticsEventType.userLogin:
        return 'Đăng nhập';
      case AnalyticsEventType.userLogout:
        return 'Đăng xuất';
      case AnalyticsEventType.fileUploaded:
        return 'Tải lên file';
      case AnalyticsEventType.fileDownloaded:
        return 'Tải xuống file';
      case AnalyticsEventType.notificationSent:
        return 'Gửi thông báo';
      case AnalyticsEventType.notificationRead:
        return 'Đọc thông báo';
      case AnalyticsEventType.roomBooked:
        return 'Đặt phòng';
      case AnalyticsEventType.roomCancelled:
        return 'Hủy phòng';
      case AnalyticsEventType.profileUpdated:
        return 'Cập nhật hồ sơ';
      case AnalyticsEventType.roleChanged:
        return 'Thay đổi vai trò';
      case AnalyticsEventType.searchPerformed:
        return 'Tìm kiếm';
      case AnalyticsEventType.settingsChanged:
        return 'Thay đổi cài đặt';
    }
  }
}

/// Meeting Analytics Model
class MeetingAnalytics {
  final int totalMeetings;
  final int completedMeetings;
  final int cancelledMeetings;
  final int upcomingMeetings;
  final double averageDuration; // minutes
  final double completionRate; // percentage
  final int totalParticipants;
  final double averageParticipants;
  final Map<String, int> meetingsByStatus;
  final Map<String, int> meetingsByType;
  final Map<String, int> meetingsByRoom;
  final List<DailyMeetingStats> dailyStats;

  MeetingAnalytics({
    required this.totalMeetings,
    required this.completedMeetings,
    required this.cancelledMeetings,
    required this.upcomingMeetings,
    required this.averageDuration,
    required this.completionRate,
    required this.totalParticipants,
    required this.averageParticipants,
    required this.meetingsByStatus,
    required this.meetingsByType,
    required this.meetingsByRoom,
    required this.dailyStats,
  });
}

/// User Analytics Model
class UserAnalytics {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByDepartment;
  final List<UserActivityStats> activityStats;
  final double averageSessionDuration;
  final int totalSessions;

  UserAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.usersByRole,
    required this.usersByDepartment,
    required this.activityStats,
    required this.averageSessionDuration,
    required this.totalSessions,
  });
}

/// File Analytics Model
class FileAnalytics {
  final int totalFiles;
  final int totalDownloads;
  final int totalUploads;
  final int totalSize; // bytes
  final Map<String, int> filesByType;
  final Map<String, int> filesByUser;
  final List<FileUsageStats> usageStats;
  final double averageFileSize;

  FileAnalytics({
    required this.totalFiles,
    required this.totalDownloads,
    required this.totalUploads,
    required this.totalSize,
    required this.filesByType,
    required this.filesByUser,
    required this.usageStats,
    required this.averageFileSize,
  });
}

/// Daily Meeting Stats
class DailyMeetingStats {
  final DateTime date;
  final int totalMeetings;
  final int completedMeetings;
  final int cancelledMeetings;
  final double averageDuration;
  final int totalParticipants;

  DailyMeetingStats({
    required this.date,
    required this.totalMeetings,
    required this.completedMeetings,
    required this.cancelledMeetings,
    required this.averageDuration,
    required this.totalParticipants,
  });
}

/// User Activity Stats
class UserActivityStats {
  final DateTime date;
  final int activeUsers;
  final int newUsers;
  final int totalSessions;
  final double averageSessionDuration;

  UserActivityStats({
    required this.date,
    required this.activeUsers,
    required this.newUsers,
    required this.totalSessions,
    required this.averageSessionDuration,
  });
}

/// File Usage Stats
class FileUsageStats {
  final DateTime date;
  final int uploads;
  final int downloads;
  final int totalSize;

  FileUsageStats({
    required this.date,
    required this.uploads,
    required this.downloads,
    required this.totalSize,
  });
}

/// Chart Data Point
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;
  final Map<String, dynamic>? metadata;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
    this.metadata,
  });
}

/// Chart Configuration
class ChartConfig {
  final ChartType type;
  final String title;
  final String? subtitle;
  final String xAxisLabel;
  final String yAxisLabel;
  final List<ChartDataPoint> data;
  final Map<String, dynamic>? options;

  ChartConfig({
    required this.type,
    required this.title,
    this.subtitle,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.data,
    this.options,
  });
}

/// Dashboard Widget Model
class DashboardWidget {
  final String id;
  final String title;
  final String type; // chart, metric, table, etc.
  final Map<String, dynamic> config;
  final int order;
  final bool isVisible;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    required this.config,
    required this.order,
    this.isVisible = true,
  });

  factory DashboardWidget.fromMap(Map<String, dynamic> map, String id) {
    return DashboardWidget(
      id: id,
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      config: Map<String, dynamic>.from(map['config'] ?? {}),
      order: map['order'] ?? 0,
      isVisible: map['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'config': config,
      'order': order,
      'isVisible': isVisible,
    };
  }
}

/// Report Model
class ReportModel {
  final String id;
  final String title;
  final String? description;
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final String creatorId;
  final String creatorName;
  final List<String> metrics;
  final Map<String, dynamic> filters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isScheduled;
  final String? schedulePattern; // cron pattern
  final List<String> recipients;

  ReportModel({
    required this.id,
    required this.title,
    this.description,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.creatorId,
    required this.creatorName,
    required this.metrics,
    required this.filters,
    required this.createdAt,
    required this.updatedAt,
    this.isScheduled = false,
    this.schedulePattern,
    this.recipients = const [],
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      period: ReportPeriod.values.firstWhere(
        (period) => period.toString().split('.').last == map['period'],
        orElse: () => ReportPeriod.monthly,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      metrics: List<String>.from(map['metrics'] ?? []),
      filters: Map<String, dynamic>.from(map['filters'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isScheduled: map['isScheduled'] ?? false,
      schedulePattern: map['schedulePattern'],
      recipients: List<String>.from(map['recipients'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'period': period.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'creatorId': creatorId,
      'creatorName': creatorName,
      'metrics': metrics,
      'filters': filters,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isScheduled': isScheduled,
      'schedulePattern': schedulePattern,
      'recipients': recipients,
    };
  }

  String get periodDisplayName {
    switch (period) {
      case ReportPeriod.daily:
        return 'Hàng ngày';
      case ReportPeriod.weekly:
        return 'Hàng tuần';
      case ReportPeriod.monthly:
        return 'Hàng tháng';
      case ReportPeriod.quarterly:
        return 'Hàng quý';
      case ReportPeriod.yearly:
        return 'Hàng năm';
      case ReportPeriod.custom:
        return 'Tùy chỉnh';
    }
  }
}

/// Metric Card Model
class MetricCard {
  final String title;
  final String value;
  final String? subtitle;
  final String? trend; // up, down, stable
  final double? trendValue;
  final String? icon;
  final String? color;

  MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.trendValue,
    this.icon,
    this.color,
  });
}

/// Analytics Filter
class AnalyticsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? userIds;
  final List<String>? departments;
  final List<String>? roles;
  final List<AnalyticsEventType>? eventTypes;
  final Map<String, dynamic>? customFilters;

  AnalyticsFilter({
    this.startDate,
    this.endDate,
    this.userIds,
    this.departments,
    this.roles,
    this.eventTypes,
    this.customFilters,
  });
}
