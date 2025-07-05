import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleAnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _meetingStats = {};
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _fileStats = {};
  List<Map<String, dynamic>> _recentEvents = [];

  bool _isLoading = false;
  String _error = '';

  // Getters
  Map<String, dynamic> get meetingStats => _meetingStats;
  Map<String, dynamic> get userStats => _userStats;
  Map<String, dynamic> get fileStats => _fileStats;
  List<Map<String, dynamic>> get recentEvents => _recentEvents;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Track event
  Future<void> trackEvent(
    String eventType,
    String userId, {
    String? userName,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? properties,
  }) async {
    try {
      Map<String, dynamic> eventData = {
        'type': eventType,
        'userId': userId,
        'userName': userName,
        'targetId': targetId,
        'targetType': targetType,
        'properties': properties ?? {},
        'timestamp': Timestamp.fromDate(DateTime.now()),
      };

      DocumentReference docRef =
          await _firestore.collection('analytics_events').add(eventData);

      // Add to recent events
      eventData['id'] = docRef.id;
      _recentEvents.insert(0, eventData);
      if (_recentEvents.length > 50) {
        _recentEvents = _recentEvents.take(50).toList();
      }

      notifyListeners();
      print('✅ Tracked event: $eventType');
    } catch (e) {
      print('❌ Error tracking event: $e');
    }
  }

  /// Load analytics data
  Future<void> loadAnalytics({
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
        _loadMeetingStats(startDate, endDate),
        _loadUserStats(startDate, endDate),
        _loadFileStats(startDate, endDate),
        _loadRecentEvents(),
      ]);

      notifyListeners();
      print('✅ Loaded analytics data');
    } catch (e) {
      print('❌ Error loading analytics: $e');
      _setError('Lỗi tải dữ liệu analytics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load meeting stats
  Future<void> _loadMeetingStats(DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<Map<String, dynamic>> meetings = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      int totalMeetings = meetings.length;
      int completedMeetings =
          meetings.where((m) => m['status'] == 'completed').length;
      int cancelledMeetings =
          meetings.where((m) => m['status'] == 'cancelled').length;
      int upcomingMeetings =
          meetings.where((m) => m['status'] == 'scheduled').length;

      double completionRate =
          totalMeetings > 0 ? (completedMeetings / totalMeetings) * 100 : 0;

      _meetingStats = {
        'totalMeetings': totalMeetings,
        'completedMeetings': completedMeetings,
        'cancelledMeetings': cancelledMeetings,
        'upcomingMeetings': upcomingMeetings,
        'completionRate': completionRate,
      };
    } catch (e) {
      print('❌ Error loading meeting stats: $e');
      _meetingStats = {};
    }
  }

  /// Load user stats
  Future<void> _loadUserStats(DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot totalUsersSnapshot =
          await _firestore.collection('users').get();
      int totalUsers = totalUsersSnapshot.docs.length;

      QuerySnapshot newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int newUsers = newUsersSnapshot.docs.length;

      // Count users by role
      Map<String, int> usersByRole = {};
      for (var doc in totalUsersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'user';
        usersByRole[role] = (usersByRole[role] ?? 0) + 1;
      }

      _userStats = {
        'totalUsers': totalUsers,
        'newUsers': newUsers,
        'usersByRole': usersByRole,
      };
    } catch (e) {
      print('❌ Error loading user stats: $e');
      _userStats = {};
    }
  }

  /// Load file stats
  Future<void> _loadFileStats(DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('files')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<Map<String, dynamic>> files = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      int totalFiles = files.length;
      int totalDownloads = files.fold<int>(
          0, (sum, file) => sum + ((file['downloadCount'] ?? 0) as int));
      int totalSize =
          files.fold<int>(0, (sum, file) => sum + ((file['size'] ?? 0) as int));

      // Count files by type
      Map<String, int> filesByType = {};
      for (var file in files) {
        String type = file['type'] ?? 'other';
        filesByType[type] = (filesByType[type] ?? 0) + 1;
      }

      _fileStats = {
        'totalFiles': totalFiles,
        'totalDownloads': totalDownloads,
        'totalSize': totalSize,
        'filesByType': filesByType,
      };
    } catch (e) {
      print('❌ Error loading file stats: $e');
      _fileStats = {};
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
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('❌ Error loading recent events: $e');
      _recentEvents = [];
    }
  }

  /// Get dashboard metrics
  List<Map<String, dynamic>> getDashboardMetrics() {
    List<Map<String, dynamic>> metrics = [];

    if (_meetingStats.isNotEmpty) {
      metrics.addAll([
        {
          'title': 'Tổng cuộc họp',
          'value': _meetingStats['totalMeetings'].toString(),
          'subtitle': 'Trong 30 ngày qua',
          'icon': 'meeting',
          'color': 'blue',
        },
        {
          'title': 'Tỷ lệ hoàn thành',
          'value': '${_meetingStats['completionRate'].toStringAsFixed(1)}%',
          'subtitle': 'Cuộc họp hoàn thành',
          'icon': 'check',
          'color': 'green',
        },
      ]);
    }

    if (_userStats.isNotEmpty) {
      metrics.addAll([
        {
          'title': 'Tổng người dùng',
          'value': _userStats['totalUsers'].toString(),
          'subtitle': 'Đã đăng ký',
          'icon': 'users',
          'color': 'purple',
        },
        {
          'title': 'Người dùng mới',
          'value': _userStats['newUsers'].toString(),
          'subtitle': 'Trong 30 ngày',
          'icon': 'user-plus',
          'color': 'teal',
        },
      ]);
    }

    if (_fileStats.isNotEmpty) {
      metrics.addAll([
        {
          'title': 'Tổng file',
          'value': _fileStats['totalFiles'].toString(),
          'subtitle': 'Đã tải lên',
          'icon': 'file',
          'color': 'indigo',
        },
        {
          'title': 'Lượt tải xuống',
          'value': _fileStats['totalDownloads'].toString(),
          'subtitle': 'Tổng cộng',
          'icon': 'download',
          'color': 'pink',
        },
      ]);
    }

    return metrics;
  }

  /// Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
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
      print('❌ SimpleAnalyticsProvider Error: $error');
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
