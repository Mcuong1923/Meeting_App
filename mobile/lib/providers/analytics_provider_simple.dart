import 'dart:async';

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

  // Realtime subscriptions
  StreamSubscription<QuerySnapshot>? _meetingStatsSub;

  // Cache pending meetings (TTL 30 giây — tránh query lại mỗi stream emit)
  List<Map<String, dynamic>>? _cachedPendingMeetings;
  DateTime? _pendingCacheTime;
  static const _pendingCacheTtl = Duration(seconds: 30);

  // Cached previous-period stats for trend calculation
  Map<String, dynamic>? _previousMeetingStats;
  DateTime? _previousStartDate;
  DateTime? _previousEndDate;

  // Getters
  Map<String, dynamic> get meetingStats => _meetingStats;
  Map<String, dynamic> get userStats => _userStats;
  Map<String, dynamic> get fileStats => _fileStats;
  List<Map<String, dynamic>> get recentEvents => _recentEvents;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Start realtime meeting statistics stream (for admin dashboard)
  ///
  /// The stats include:
  /// - totalMeetings
  /// - completedMeetings
  /// - cancelledMeetings
  /// - upcomingMeetings
  /// - completionRate
  /// - averageDurationMinutes
  /// - averageParticipants
  /// - statusCounts (map)
  /// - typeCounts (map)
  /// - locationTypeCounts (map: online/offline/hybrid)
  /// - topOrganizers (list of {creatorId, creatorName, meetingCount})
  Future<void> startRealtimeMeetingStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Cancel previous subscription if any
    await _meetingStatsSub?.cancel();

    // Preload previous-period stats once (used for trends)
    await _loadPreviousPeriodMeetingStats(
      startDate: startDate,
      endDate: endDate,
    );

    _meetingStatsSub = _firestore
        .collection('meetings')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .listen(
      (snapshot) async {
        try {
          final meetingsInRange = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          // Lấy pending meetings — dùng cache nếu còn hạn (30s)
          final now = DateTime.now();
          if (_cachedPendingMeetings == null ||
              _pendingCacheTime == null ||
              now.difference(_pendingCacheTime!) > _pendingCacheTtl) {
            final pendingSnapshot = await _firestore
                .collection('meetings')
                .where('status', whereIn: ['pending', 'MeetingStatus.pending'])
                .get();
            _cachedPendingMeetings = pendingSnapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
            _pendingCacheTime = now;
          }

          // Gộp 2 danh sách, loại trùng theo id
          final seenIds = <String>{};
          final merged = <Map<String, dynamic>>[];
          for (final m in [...meetingsInRange, ..._cachedPendingMeetings!]) {
            final id = m['id'] as String;
            if (seenIds.add(id)) merged.add(m);
          }

          if (merged.isEmpty) {
            _meetingStats = {
              'totalMeetings': 0,
              'completedMeetings': 0,
              'cancelledMeetings': 0,
              'upcomingMeetings': 0,
              'completionRate': 0.0,
              'attendanceRate': 0.0,
              'averageDurationMinutes': 0.0,
              'averageParticipants': 0.0,
              'statusCounts': <String, int>{},
              'typeCounts': <String, int>{},
              'locationTypeCounts': <String, int>{},
              'topOrganizers': <Map<String, dynamic>>[],
              'trends': <String, double>{},
            };
            notifyListeners();
            return;
          }

          final computed = _computeMeetingStats(merged);
          _meetingStats = computed;

          // Add trends if we have previous stats
          if (_previousMeetingStats != null &&
              _previousStartDate == startDate &&
              _previousEndDate == endDate) {
            final trends = _computeTrends(
              current: computed,
              previous: _previousMeetingStats!,
            );
            _meetingStats['trends'] = trends;
          } else {
            _meetingStats['trends'] = <String, double>{};
          }

          notifyListeners();
        } catch (e) {
          print('❌ Error calculating realtime meeting stats: $e');
        }
      },
      onError: (e) {
        print('❌ Realtime meeting stats stream error: $e');
      },
    );
  }

  Future<void> stopRealtimeMeetingStats() async {
    await _meetingStatsSub?.cancel();
    _meetingStatsSub = null;
  }

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

      _meetingStats = _computeMeetingStats(meetings);
    } catch (e) {
      print('❌ Error loading meeting stats: $e');
      _meetingStats = {};
    }
  }

  Future<void> _loadPreviousPeriodMeetingStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final duration = endDate.difference(startDate);
      // Previous period is the same duration immediately preceding current period
      final prevEnd = startDate;
      final prevStart = startDate.subtract(duration);

      _previousStartDate = startDate;
      _previousEndDate = endDate;

      final snapshot = await _firestore
          .collection('meetings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(prevStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(prevEnd))
          .get();

      final meetings = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      _previousMeetingStats = _computeMeetingStats(meetings);
    } catch (e) {
      // Trend is optional; ignore failures
      _previousMeetingStats = null;
    }
  }

  Map<String, dynamic> _computeMeetingStats(List<Map<String, dynamic>> meetings) {
    final now = DateTime.now().toLocal();

    int totalMeetings = meetings.length;
    int completedMeetings = 0;
    int cancelledMeetings = 0;
    int upcomingMeetings = 0;

    double totalDurationMinutes = 0;
    int durationCount = 0;

    int totalParticipants = 0;
    int totalAcceptedParticipants = 0;

    // These maps are used by UI; keep canonical keys
    final Map<String, int> statusCounts = {
      'completed': 0,
      'scheduled': 0,
      'pending': 0,
      'cancelled': 0,
    };
    final Map<String, int> typeCounts = {};
    final Map<String, int> locationTypeCounts = {};
    final Map<String, int> organizerCounts = {};
    final Map<String, String> organizerNames = {};

    for (final meeting in meetings) {
      // Normalize enums stored as either "completed" or "MeetingStatus.completed"
      final rawStatus = meeting['status'];
      final statusStr = _normalizeEnumString(rawStatus, fallback: 'pending');

      // Determine derived status bucket for analytics UI
      final bucket = _deriveStatusBucket(
        status: statusStr,
        startTime: meeting['startTime'],
        endTime: meeting['endTime'],
        now: now,
      );

      statusCounts[bucket] = (statusCounts[bucket] ?? 0) + 1;
      if (bucket == 'completed') completedMeetings++;
      if (bucket == 'cancelled') cancelledMeetings++;
      if (bucket == 'scheduled') upcomingMeetings++;

      // Type
      final type = _normalizeEnumString(meeting['type'], fallback: 'personal');
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;

      // Location type
      final locationType =
          _normalizeEnumString(meeting['locationType'], fallback: 'virtual');
      locationTypeCounts[locationType] =
          (locationTypeCounts[locationType] ?? 0) + 1;

      // Duration
      if (meeting['startTime'] is Timestamp && meeting['endTime'] is Timestamp) {
        final start = (meeting['startTime'] as Timestamp).toDate().toLocal();
        final end = (meeting['endTime'] as Timestamp).toDate().toLocal();
        final diff = end.difference(start).inMinutes;
        if (diff > 0) {
          totalDurationMinutes += diff;
          durationCount++;
        }
      }

      // Participants + attendance
      if (meeting['participants'] is List) {
        final participants = (meeting['participants'] as List).cast<dynamic>();
        totalParticipants += participants.length;
        for (final p in participants) {
          if (p is Map<String, dynamic>) {
            final attendance =
                (p['attendanceStatus'] ?? '').toString().toLowerCase().trim();
            final hasConfirmed = p['hasConfirmed'] == true;
            if (attendance == 'accepted' || hasConfirmed) {
              totalAcceptedParticipants++;
            }
          }
        }
      }

      // Organizers
      final creatorId = (meeting['creatorId'] ?? '').toString();
      final creatorName = (meeting['creatorName'] ?? '').toString();
      if (creatorId.isNotEmpty) {
        organizerCounts[creatorId] = (organizerCounts[creatorId] ?? 0) + 1;
        if (creatorName.isNotEmpty) {
          organizerNames[creatorId] = creatorName;
        }
      }
    }

    final completionRate =
        totalMeetings > 0 ? (completedMeetings / totalMeetings) * 100 : 0.0;

    final attendanceRate = totalParticipants > 0
        ? (totalAcceptedParticipants / totalParticipants) * 100
        : 0.0;

    final averageDurationMinutes =
        durationCount > 0 ? totalDurationMinutes / durationCount : 0.0;

    final averageParticipants =
        totalMeetings > 0 ? totalParticipants / totalMeetings : 0.0;

    // Top organizers
    final topOrganizers = organizerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topOrganizerList = topOrganizers.take(5).map((entry) {
      return {
        'creatorId': entry.key,
        'creatorName': organizerNames[entry.key] ?? 'Không rõ',
        'meetingCount': entry.value,
      };
    }).toList();

    return {
      'totalMeetings': totalMeetings,
      'completedMeetings': completedMeetings,
      'cancelledMeetings': cancelledMeetings,
      'upcomingMeetings': upcomingMeetings,
      'completionRate': completionRate,
      'attendanceRate': attendanceRate,
      'averageDurationMinutes': averageDurationMinutes,
      'averageParticipants': averageParticipants,
      'statusCounts': statusCounts,
      'typeCounts': typeCounts,
      'locationTypeCounts': locationTypeCounts,
      'topOrganizers': topOrganizerList,
    };
  }

  String _normalizeEnumString(dynamic raw, {required String fallback}) {
    if (raw == null) return fallback;
    final s = raw.toString().trim();
    if (s.isEmpty) return fallback;
    // Handle formats like "MeetingStatus.completed" or "MeetingType.team"
    if (s.contains('.')) {
      return s.split('.').last.trim();
    }
    return s;
  }

  String _deriveStatusBucket({
    required String status,
    required dynamic startTime,
    required dynamic endTime,
    required DateTime now,
  }) {
    // MeetingModel enum: pending/approved/rejected/cancelled/completed/expired
    switch (status) {
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'pending':
        return 'pending';
      case 'approved':
        // If the meeting is already in the past but not marked completed yet, bucket as completed
        if (endTime is Timestamp) {
          final end = endTime.toDate().toLocal();
          if (end.isBefore(now)) return 'completed';
        }
        return 'scheduled';
      case 'rejected':
      case 'expired':
        return 'cancelled';
      default:
        // Backward compat: if some docs used "scheduled" already, treat as scheduled
        if (status == 'scheduled') return 'scheduled';
        return 'pending';
    }
  }

  Map<String, double> _computeTrends({
    required Map<String, dynamic> current,
    required Map<String, dynamic> previous,
  }) {
    double trendPct(num cur, num prev) {
      if (prev == 0) {
        if (cur == 0) return 0.0;
        return 100.0;
      }
      return ((cur - prev) / prev) * 100.0;
    }

    final curTotal = (current['totalMeetings'] ?? 0) as int;
    final prevTotal = (previous['totalMeetings'] ?? 0) as int;

    final curAttend = (current['attendanceRate'] ?? 0.0) as double;
    final prevAttend = (previous['attendanceRate'] ?? 0.0) as double;

    final curAvgP = (current['averageParticipants'] ?? 0.0) as double;
    final prevAvgP = (previous['averageParticipants'] ?? 0.0) as double;

    final curAvgDur = (current['averageDurationMinutes'] ?? 0.0) as double;
    final prevAvgDur = (previous['averageDurationMinutes'] ?? 0.0) as double;

    return {
      'totalMeetings': trendPct(curTotal, prevTotal),
      'attendanceRate': trendPct(curAttend, prevAttend),
      'averageParticipants': trendPct(curAvgP, prevAvgP),
      'averageDurationMinutes': trendPct(curAvgDur, prevAvgDur),
    };
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
          0, (acc, file) => acc + ((file['downloadCount'] ?? 0) as int));
      int totalSize =
          files.fold<int>(0, (acc, file) => acc + ((file['size'] ?? 0) as int));

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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
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
    _meetingStatsSub?.cancel();
    super.dispose();
  }
}
