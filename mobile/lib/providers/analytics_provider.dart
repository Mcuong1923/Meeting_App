import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metting_app/models/analytics_model.dart';
import 'package:metting_app/models/meeting_model.dart';
import 'package:metting_app/models/user_model.dart';
import 'package:metting_app/models/file_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Analytics data
  MeetingAnalytics? _meetingAnalytics;
  UserAnalytics? _userAnalytics;
  FileAnalytics? _fileAnalytics;
  List<AnalyticsEvent> _recentEvents = [];
  List<MetricCard> _dashboardMetrics = [];
  List<ChartConfig> _dashboardCharts = [];

  bool _isLoading = false;
  String _error = '';
  String? _currentSessionId;
  String? _deviceInfo;
  String? _appVersion;

  // Getters
  MeetingAnalytics? get meetingAnalytics => _meetingAnalytics;
  UserAnalytics? get userAnalytics => _userAnalytics;
  FileAnalytics? get fileAnalytics => _fileAnalytics;
  List<AnalyticsEvent> get recentEvents => _recentEvents;
  List<MetricCard> get dashboardMetrics => _dashboardMetrics;
  List<ChartConfig> get dashboardCharts => _dashboardCharts;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Initialize analytics
  Future<void> initialize() async {
    try {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Get device info
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      try {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = '${androidInfo.brand} ${androidInfo.model}';
      } catch (e) {
        _deviceInfo = 'Unknown Device';
      }

      // Get app version
      try {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (e) {
        _appVersion = '1.0.0';
      }

      print('✅ Analytics initialized');
    } catch (e) {
      print('❌ Error initializing analytics: $e');
    }
  }

  /// Track event
  Future<void> trackEvent(
    AnalyticsEventType type,
    String userId, {
    String? userName,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? properties,
  }) async {
    try {
      AnalyticsEvent event = AnalyticsEvent(
        id: '',
        type: type,
        userId: userId,
        userName: userName,
        targetId: targetId,
        targetType: targetType,
        properties: properties ?? {},
        timestamp: DateTime.now(),
        sessionId: _currentSessionId,
        deviceInfo: _deviceInfo,
        appVersion: _appVersion,
      );

      DocumentReference docRef =
          await _firestore.collection('analytics_events').add(event.toMap());

      // Add to recent events
      AnalyticsEvent newEvent = AnalyticsEvent(
        id: docRef.id,
        type: event.type,
        userId: event.userId,
        userName: event.userName,
        targetId: event.targetId,
        targetType: event.targetType,
        properties: event.properties,
        timestamp: event.timestamp,
        sessionId: event.sessionId,
        deviceInfo: event.deviceInfo,
        appVersion: event.appVersion,
      );
      _recentEvents.insert(0, newEvent);
      if (_recentEvents.length > 50) {
        _recentEvents = _recentEvents.take(50).toList();
      }

      notifyListeners();
      print('✅ Tracked event: ${type.toString()}');
    } catch (e) {
      print('❌ Error tracking event: $e');
    }
  }

  /// Load dashboard analytics
  Future<void> loadDashboardAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Load all analytics in parallel
      await Future.wait([
        _loadMeetingAnalytics(startDate, endDate),
        _loadUserAnalytics(startDate, endDate),
        _loadFileAnalytics(startDate, endDate),
        _loadRecentEvents(),
      ]);

      // Generate dashboard metrics and charts
      _generateDashboardMetrics();
      _generateDashboardCharts();

      notifyListeners();
      print('✅ Loaded dashboard analytics');
    } catch (e) {
      print('❌ Error loading dashboard analytics: $e');
      _setError('Lỗi tải dữ liệu analytics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load meeting analytics
  Future<void> _loadMeetingAnalytics(
      DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<MeetingModel> meetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Calculate metrics
      int totalMeetings = meetings.length;
      int completedMeetings = meetings
          .where((m) => m.status.toString() == 'MeetingStatus.completed')
          .length;
      int cancelledMeetings = meetings
          .where((m) => m.status.toString() == 'MeetingStatus.cancelled')
          .length;
      int upcomingMeetings = meetings
          .where((m) => m.status.toString() == 'MeetingStatus.scheduled')
          .length;

      double averageDuration = 0;
      int totalParticipants = 0;

      for (MeetingModel meeting in meetings) {
        if (meeting.status.toString() == 'MeetingStatus.completed') {
          Duration duration = meeting.endTime.difference(meeting.startTime);
          averageDuration += duration.inMinutes;
        }
        totalParticipants += meeting.participants.length;
      }

      if (completedMeetings > 0) {
        averageDuration = averageDuration / completedMeetings;
      }

      double completionRate =
          totalMeetings > 0 ? (completedMeetings / totalMeetings) * 100 : 0;

      double averageParticipants =
          totalMeetings > 0 ? totalParticipants / totalMeetings : 0;

      // Group by status, type, room
      Map<String, int> meetingsByStatus = {};
      Map<String, int> meetingsByType = {};
      Map<String, int> meetingsByRoom = {};

      for (MeetingModel meeting in meetings) {
        String status = meeting.status.toString().split('.').last;
        meetingsByStatus[status] = (meetingsByStatus[status] ?? 0) + 1;

        String type = meeting.type ?? 'general';
        meetingsByType[type] = (meetingsByType[type] ?? 0) + 1;

        String room = meeting.roomName ?? 'Unknown';
        meetingsByRoom[room] = (meetingsByRoom[room] ?? 0) + 1;
      }

      // Generate daily stats
      List<DailyMeetingStats> dailyStats =
          _generateDailyMeetingStats(meetings, startDate, endDate);

      _meetingAnalytics = MeetingAnalytics(
        totalMeetings: totalMeetings,
        completedMeetings: completedMeetings,
        cancelledMeetings: cancelledMeetings,
        upcomingMeetings: upcomingMeetings,
        averageDuration: averageDuration,
        completionRate: completionRate,
        totalParticipants: totalParticipants,
        averageParticipants: averageParticipants,
        meetingsByStatus: meetingsByStatus,
        meetingsByType: meetingsByType,
        meetingsByRoom: meetingsByRoom,
        dailyStats: dailyStats,
      );
    } catch (e) {
      print('❌ Error loading meeting analytics: $e');
    }
  }

  /// Load user analytics
  Future<void> _loadUserAnalytics(DateTime startDate, DateTime endDate) async {
    try {
      // Get total users
      QuerySnapshot totalUsersSnapshot =
          await _firestore.collection('users').get();
      int totalUsers = totalUsersSnapshot.docs.length;

      // Get active users (users with events in period)
      QuerySnapshot activeUsersSnapshot = await _firestore
          .collection('analytics_events')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Set<String> activeUserIds = activeUsersSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['userId'] as String)
          .toSet();

      int activeUsers = activeUserIds.length;

      // Get new users in period
      QuerySnapshot newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int newUsers = newUsersSnapshot.docs.length;

      // Group users by role and department
      Map<String, int> usersByRole = {};
      Map<String, int> usersByDepartment = {};

      for (QueryDocumentSnapshot doc in totalUsersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'user';
        String department = userData['department'] ?? 'Unknown';

        usersByRole[role] = (usersByRole[role] ?? 0) + 1;
        usersByDepartment[department] =
            (usersByDepartment[department] ?? 0) + 1;
      }

      // Calculate session stats
      Map<String, List<AnalyticsEvent>> sessionGroups = {};
      for (QueryDocumentSnapshot doc in activeUsersSnapshot.docs) {
        AnalyticsEvent event =
            AnalyticsEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        String sessionKey = '${event.userId}_${event.sessionId}';
        if (!sessionGroups.containsKey(sessionKey)) {
          sessionGroups[sessionKey] = [];
        }
        sessionGroups[sessionKey]!.add(event);
      }

      int totalSessions = sessionGroups.length;
      double averageSessionDuration = 0;

      for (List<AnalyticsEvent> sessionEvents in sessionGroups.values) {
        if (sessionEvents.length > 1) {
          sessionEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          Duration sessionDuration = sessionEvents.last.timestamp
              .difference(sessionEvents.first.timestamp);
          averageSessionDuration += sessionDuration.inMinutes;
        }
      }

      if (totalSessions > 0) {
        averageSessionDuration = averageSessionDuration / totalSessions;
      }

      // Generate activity stats
      List<UserActivityStats> activityStats = _generateUserActivityStats(
          activeUsersSnapshot.docs, startDate, endDate);

      _userAnalytics = UserAnalytics(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        newUsers: newUsers,
        usersByRole: usersByRole,
        usersByDepartment: usersByDepartment,
        activityStats: activityStats,
        averageSessionDuration: averageSessionDuration,
        totalSessions: totalSessions,
      );
    } catch (e) {
      print('❌ Error loading user analytics: $e');
    }
  }

  /// Load file analytics
  Future<void> _loadFileAnalytics(DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('files')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<FileModel> files = snapshot.docs
          .map((doc) =>
              FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      int totalFiles = files.length;
      int totalDownloads =
          files.fold(0, (sum, file) => sum + file.downloadCount);
      int totalUploads = files.length;
      int totalSize = files.fold(0, (sum, file) => sum + file.size);

      // Group by type and user
      Map<String, int> filesByType = {};
      Map<String, int> filesByUser = {};

      for (FileModel file in files) {
        String type = file.type.toString().split('.').last;
        filesByType[type] = (filesByType[type] ?? 0) + 1;

        String user = file.uploaderName;
        filesByUser[user] = (filesByUser[user] ?? 0) + 1;
      }

      double averageFileSize = totalFiles > 0 ? totalSize / totalFiles : 0;

      // Generate usage stats
      List<FileUsageStats> usageStats =
          _generateFileUsageStats(files, startDate, endDate);

      _fileAnalytics = FileAnalytics(
        totalFiles: totalFiles,
        totalDownloads: totalDownloads,
        totalUploads: totalUploads,
        totalSize: totalSize,
        filesByType: filesByType,
        filesByUser: filesByUser,
        usageStats: usageStats,
        averageFileSize: averageFileSize,
      );
    } catch (e) {
      print('❌ Error loading file analytics: $e');
    }
  }

  /// Load recent events
  Future<void> _loadRecentEvents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('analytics_events')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _recentEvents = snapshot.docs
          .map((doc) => AnalyticsEvent.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Error loading recent events: $e');
    }
  }

  /// Generate dashboard metrics
  void _generateDashboardMetrics() {
    _dashboardMetrics.clear();

    if (_meetingAnalytics != null) {
      _dashboardMetrics.addAll([
        MetricCard(
          title: 'Tổng cuộc họp',
          value: _meetingAnalytics!.totalMeetings.toString(),
          subtitle: 'Trong 30 ngày qua',
          icon: 'meeting',
          color: 'blue',
        ),
        MetricCard(
          title: 'Tỷ lệ hoàn thành',
          value: '${_meetingAnalytics!.completionRate.toStringAsFixed(1)}%',
          subtitle: 'Cuộc họp hoàn thành',
          icon: 'check',
          color: 'green',
        ),
        MetricCard(
          title: 'Thời gian trung bình',
          value:
              '${_meetingAnalytics!.averageDuration.toStringAsFixed(0)} phút',
          subtitle: 'Mỗi cuộc họp',
          icon: 'clock',
          color: 'orange',
        ),
      ]);
    }

    if (_userAnalytics != null) {
      _dashboardMetrics.addAll([
        MetricCard(
          title: 'Người dùng hoạt động',
          value: _userAnalytics!.activeUsers.toString(),
          subtitle: 'Trong 30 ngày qua',
          icon: 'users',
          color: 'purple',
        ),
        MetricCard(
          title: 'Người dùng mới',
          value: _userAnalytics!.newUsers.toString(),
          subtitle: 'Đăng ký gần đây',
          icon: 'user-plus',
          color: 'teal',
        ),
      ]);
    }

    if (_fileAnalytics != null) {
      _dashboardMetrics.addAll([
        MetricCard(
          title: 'Tổng file',
          value: _fileAnalytics!.totalFiles.toString(),
          subtitle: 'Đã tải lên',
          icon: 'file',
          color: 'indigo',
        ),
        MetricCard(
          title: 'Lượt tải xuống',
          value: _fileAnalytics!.totalDownloads.toString(),
          subtitle: 'Tổng cộng',
          icon: 'download',
          color: 'pink',
        ),
      ]);
    }
  }

  /// Generate dashboard charts
  void _generateDashboardCharts() {
    _dashboardCharts.clear();

    // Meeting status chart
    if (_meetingAnalytics != null) {
      List<ChartDataPoint> statusData = _meetingAnalytics!
          .meetingsByStatus.entries
          .map((entry) => ChartDataPoint(
              label: _getStatusDisplayName(entry.key),
              value: entry.value.toDouble()))
          .toList();

      _dashboardCharts.add(ChartConfig(
        type: ChartType.pie,
        title: 'Trạng thái cuộc họp',
        xAxisLabel: 'Trạng thái',
        yAxisLabel: 'Số lượng',
        data: statusData,
      ));

      // Daily meetings chart
      List<ChartDataPoint> dailyData = _meetingAnalytics!.dailyStats
          .map((stat) => ChartDataPoint(
              label: '${stat.date.day}/${stat.date.month}',
              value: stat.totalMeetings.toDouble(),
              date: stat.date))
          .toList();

      _dashboardCharts.add(ChartConfig(
        type: ChartType.line,
        title: 'Cuộc họp theo ngày',
        xAxisLabel: 'Ngày',
        yAxisLabel: 'Số cuộc họp',
        data: dailyData,
      ));
    }

    // User roles chart
    if (_userAnalytics != null) {
      List<ChartDataPoint> roleData = _userAnalytics!.usersByRole.entries
          .map((entry) => ChartDataPoint(
              label: _getRoleDisplayName(entry.key),
              value: entry.value.toDouble()))
          .toList();

      _dashboardCharts.add(ChartConfig(
        type: ChartType.doughnut,
        title: 'Người dùng theo vai trò',
        xAxisLabel: 'Vai trò',
        yAxisLabel: 'Số lượng',
        data: roleData,
      ));
    }

    // File types chart
    if (_fileAnalytics != null) {
      List<ChartDataPoint> typeData = _fileAnalytics!.filesByType.entries
          .map((entry) => ChartDataPoint(
              label: _getFileTypeDisplayName(entry.key),
              value: entry.value.toDouble()))
          .toList();

      _dashboardCharts.add(ChartConfig(
        type: ChartType.bar,
        title: 'File theo loại',
        xAxisLabel: 'Loại file',
        yAxisLabel: 'Số lượng',
        data: typeData,
      ));
    }
  }

  /// Generate daily meeting stats
  List<DailyMeetingStats> _generateDailyMeetingStats(
      List<MeetingModel> meetings, DateTime startDate, DateTime endDate) {
    Map<String, DailyMeetingStats> dailyStatsMap = {};

    // Initialize all days
    for (DateTime date = startDate;
        date.isBefore(endDate);
        date = date.add(const Duration(days: 1))) {
      String dateKey = '${date.year}-${date.month}-${date.day}';
      dailyStatsMap[dateKey] = DailyMeetingStats(
        date: date,
        totalMeetings: 0,
        completedMeetings: 0,
        cancelledMeetings: 0,
        averageDuration: 0,
        totalParticipants: 0,
      );
    }

    // Populate with meeting data
    for (MeetingModel meeting in meetings) {
      DateTime meetingDate = meeting.createdAt;
      String dateKey =
          '${meetingDate.year}-${meetingDate.month}-${meetingDate.day}';

      if (dailyStatsMap.containsKey(dateKey)) {
        DailyMeetingStats currentStats = dailyStatsMap[dateKey]!;
        dailyStatsMap[dateKey] = DailyMeetingStats(
          date: currentStats.date,
          totalMeetings: currentStats.totalMeetings + 1,
          completedMeetings: currentStats.completedMeetings +
              (meeting.status == MeetingStatus.completed ? 1 : 0),
          cancelledMeetings: currentStats.cancelledMeetings +
              (meeting.status == MeetingStatus.cancelled ? 1 : 0),
          averageDuration: currentStats.averageDuration,
          totalParticipants:
              currentStats.totalParticipants + meeting.participants.length,
        );
      }
    }

    return dailyStatsMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Generate user activity stats
  List<UserActivityStats> _generateUserActivityStats(
      List<QueryDocumentSnapshot> events,
      DateTime startDate,
      DateTime endDate) {
    Map<String, UserActivityStats> dailyStatsMap = {};

    // Initialize all days
    for (DateTime date = startDate;
        date.isBefore(endDate);
        date = date.add(const Duration(days: 1))) {
      String dateKey = '${date.year}-${date.month}-${date.day}';
      dailyStatsMap[dateKey] = UserActivityStats(
        date: date,
        activeUsers: 0,
        newUsers: 0,
        totalSessions: 0,
        averageSessionDuration: 0,
      );
    }

    // TODO: Implement actual user activity stats calculation

    return dailyStatsMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Generate file usage stats
  List<FileUsageStats> _generateFileUsageStats(
      List<FileModel> files, DateTime startDate, DateTime endDate) {
    Map<String, FileUsageStats> dailyStatsMap = {};

    // Initialize all days
    for (DateTime date = startDate;
        date.isBefore(endDate);
        date = date.add(const Duration(days: 1))) {
      String dateKey = '${date.year}-${date.month}-${date.day}';
      dailyStatsMap[dateKey] = FileUsageStats(
        date: date,
        uploads: 0,
        downloads: 0,
        totalSize: 0,
      );
    }

    // Populate with file data
    for (FileModel file in files) {
      DateTime fileDate = file.createdAt;
      String dateKey = '${fileDate.year}-${fileDate.month}-${fileDate.day}';

      if (dailyStatsMap.containsKey(dateKey)) {
        FileUsageStats currentStats = dailyStatsMap[dateKey]!;
        dailyStatsMap[dateKey] = FileUsageStats(
          date: currentStats.date,
          uploads: currentStats.uploads + 1,
          downloads: currentStats.downloads + file.downloadCount,
          totalSize: currentStats.totalSize + file.size,
        );
      }
    }

    return dailyStatsMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Helper methods for display names
  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'scheduled':
        return 'Đã lên lịch';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'director':
        return 'Giám đốc';
      case 'manager':
        return 'Quản lý';
      case 'employee':
        return 'Nhân viên';
      default:
        return role;
    }
  }

  String _getFileTypeDisplayName(String type) {
    switch (type) {
      case 'document':
        return 'Tài liệu';
      case 'image':
        return 'Hình ảnh';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Âm thanh';
      case 'spreadsheet':
        return 'Bảng tính';
      case 'presentation':
        return 'Thuyết trình';
      default:
        return type;
    }
  }

  /// Get analytics by filter
  Future<Map<String, dynamic>> getAnalyticsByFilter(
      AnalyticsFilter filter) async {
    try {
      Query query = _firestore.collection('analytics_events');

      if (filter.startDate != null) {
        query =
            query.where('timestamp', isGreaterThanOrEqualTo: filter.startDate);
      }
      if (filter.endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: filter.endDate);
      }
      if (filter.userIds != null && filter.userIds!.isNotEmpty) {
        query = query.where('userId', whereIn: filter.userIds);
      }
      if (filter.eventTypes != null && filter.eventTypes!.isNotEmpty) {
        List<String> eventTypeStrings = filter.eventTypes!
            .map((type) => type.toString().split('.').last)
            .toList();
        query = query.where('type', whereIn: eventTypeStrings);
      }

      QuerySnapshot snapshot = await query.get();

      List<AnalyticsEvent> events = snapshot.docs
          .map((doc) => AnalyticsEvent.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Process and return analytics
      return {
        'totalEvents': events.length,
        'events': events,
        'eventsByType': _groupEventsByType(events),
        'eventsByUser': _groupEventsByUser(events),
        'eventsByDate': _groupEventsByDate(events),
      };
    } catch (e) {
      print('❌ Error getting analytics by filter: $e');
      return {};
    }
  }

  /// Group events by type
  Map<String, int> _groupEventsByType(List<AnalyticsEvent> events) {
    Map<String, int> groupedEvents = {};
    for (AnalyticsEvent event in events) {
      String type = event.type.toString().split('.').last;
      groupedEvents[type] = (groupedEvents[type] ?? 0) + 1;
    }
    return groupedEvents;
  }

  /// Group events by user
  Map<String, int> _groupEventsByUser(List<AnalyticsEvent> events) {
    Map<String, int> groupedEvents = {};
    for (AnalyticsEvent event in events) {
      String user = event.userName ?? event.userId;
      groupedEvents[user] = (groupedEvents[user] ?? 0) + 1;
    }
    return groupedEvents;
  }

  /// Group events by date
  Map<String, int> _groupEventsByDate(List<AnalyticsEvent> events) {
    Map<String, int> groupedEvents = {};
    for (AnalyticsEvent event in events) {
      String date =
          '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}';
      groupedEvents[date] = (groupedEvents[date] ?? 0) + 1;
    }
    return groupedEvents;
  }

  /// Export analytics data
  Future<String> exportAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json',
  }) async {
    try {
      // TODO: Implement data export functionality
      return 'Export functionality not implemented yet';
    } catch (e) {
      print('❌ Error exporting analytics data: $e');
      return '';
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    if (error.isNotEmpty) {
      print('❌ AnalyticsProvider Error: $error');
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
