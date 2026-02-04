import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:metting_app/models/notification_model.dart';
import 'package:metting_app/models/user_model.dart';
import 'package:metting_app/models/meeting_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../main.dart'; // Import for navigatorKey

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _error = '';
  int _unreadCount = 0;
  bool _isInitialized = false;
  String? _currentUserId;

  // Constructor - tự động khởi tạo
  NotificationProvider() {
    _autoInitialize();
  }

  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => n.isUnread).toList();
  bool get isLoading => _isLoading;
  String get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Tự động khởi tạo (gọi từ constructor)
  Future<void> _autoInitialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      _isInitialized = true;
      print('✅ NotificationProvider auto-initialized');
    } catch (e) {
      print('❌ Error auto-initializing notifications: $e');
      _setError('Lỗi khởi tạo thông báo: $e');
    }
  }

  /// Khởi tạo notification system
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      _isInitialized = true;
      print('✅ NotificationProvider initialized');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      _setError('Lỗi khởi tạo thông báo: $e');
    }
  }

  /// Khởi tạo local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Khởi tạo Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM permission granted');

      // Get FCM token
      String? token = await _messaging.getToken();
      print('📱 FCM Token: $token');

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen to background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } else {
      print('❌ FCM permission denied');
    }
  }

  /// Xử lý thông báo khi app đang mở
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  /// Xử lý thông báo khi app đang background
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📨 Background message: ${message.notification?.title}');
    // Handle navigation or other actions
  }

  /// Hiển thị local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'meeting_channel',
      'Meeting Notifications',
      channelDescription: 'Notifications for meeting app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create robust payload
    final payloadMap = {
      'type': message.data['type'] ?? 'general',
      'meetingId': message.data['meetingId'],
      'roomId': message.data['roomId'],
    };
    final payloadString = jsonEncode(payloadMap);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Thông báo',
      message.notification?.body ?? '',
      details,
      payload: payloadString,
    );
  }

  /// Xử lý khi tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final type = data['type'];
        final meetingId = data['meetingId'];
        
        print('🔔 Tap Action - Type: $type, MeetingId: $meetingId');
        
        if (meetingId != null && 
            (type == 'meetingInvitation' || 
             type == 'meetingApproved' || 
             type == 'meetingApproval' ||
             type == 'meetingApprovalResult')) {
          
          print('🚀 Navigating to meeting detail: $meetingId');
          navigatorKey.currentState?.pushNamed(
            '/meeting-detail',
            arguments: meetingId,
          );
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Load notifications cho user hiện tại (auto-detect user)
  Future<void> loadNotificationsForCurrentUser() async {
    try {
      // Get current user from AuthProvider
      // Sẽ được gọi từ UI với context
      print('🔄 Loading notifications for current user...');
    } catch (e) {
      print('❌ Error loading notifications for current user: $e');
    }
  }

  /// Load notifications cho user
  Future<void> loadNotifications(String userId) async {
    try {
      print(
          '🔄 NotificationProvider.loadNotifications called for user: $userId');
      _setLoading(true);
      _setError('');
      _currentUserId = userId; // Set current user ID
      print('🔄 Current user ID set to: $_currentUserId');

      print('🔄 Loading notifications for user: $userId');

      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      _updateUnreadCount();
      print('🔄 Unread count after loading: $_unreadCount');
      notifyListeners();

      print('✅ Loaded ${_notifications.length} notifications for user $userId');
    } catch (e) {
      print('❌ Error loading notifications: $e');
      _setError('Lỗi tải thông báo: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo thông báo mới
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());

      NotificationModel newNotification = notification.copyWith(id: docRef.id);
      _notifications.insert(0, newNotification);
      _updateUnreadCount();
      notifyListeners();

      // Send push notification nếu cần
      await _sendPushNotification(newNotification);

      print('✅ Created notification: ${notification.title}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating notification: $e');
      _setError('Lỗi tạo thông báo: $e');
      return null;
    }
  }

  /// Gửi push notification
  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // TODO: Implement server-side push notification
      // Có thể sử dụng Firebase Functions hoặc server API
      print('📤 Sending push notification: ${notification.title}');
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      int index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications =
          _notifications.where((n) => !n.isRead).toList();

      WriteBatch batch = _firestore.batch();
      for (NotificationModel notification in unreadNotifications) {
        batch.update(
          _firestore.collection('notifications').doc(notification.id),
          {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();

      print('✅ Deleted notification: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
      _setError('Lỗi xóa thông báo: $e');
    }
  }

  /// Tạo thông báo nhắc nhở cuộc họp
  Future<void> createMeetingReminders(MeetingModel meeting) async {
    try {
      // Tạo nhắc nhở cho creator
      await createNotification(NotificationTemplate.meetingReminder(
        userId: meeting.creatorId,
        meetingTitle: meeting.title,
        meetingId: meeting.id,
        meetingTime: meeting.startTime,
        minutesBefore: 15,
      ));

      // Tạo nhắc nhở cho participants
      for (var participant in meeting.participants) {
        await createNotification(NotificationTemplate.meetingReminder(
          userId: participant.userId,
          meetingTitle: meeting.title,
          meetingId: meeting.id,
          meetingTime: meeting.startTime,
          minutesBefore: 15,
        ));
      }

      print('✅ Created meeting reminders for: ${meeting.title}');
    } catch (e) {
      print('❌ Error creating meeting reminders: $e');
    }
  }

  /// Tạo thông báo phê duyệt cuộc họp
  Future<void> createMeetingApprovalNotification(
      MeetingModel meeting, List<UserModel> approvers) async {
    try {
      for (UserModel approver in approvers) {
        await createNotification(NotificationTemplate.meetingApproval(
          userId: approver.id,
          meetingTitle: meeting.title,
          meetingId: meeting.id,
          creatorName: meeting.creatorName,
        ));
      }

      print('✅ Created approval notifications for: ${meeting.title}');
    } catch (e) {
      print('❌ Error creating approval notifications: $e');
    }
  }

  /// Tạo thông báo kết quả phê duyệt
  Future<void> createApprovalResultNotification(
      MeetingModel meeting, bool isApproved, String? notes) async {
    try {
      await createNotification(NotificationTemplate.meetingApprovalResult(
        userId: meeting.creatorId,
        meetingTitle: meeting.title,
        meetingId: meeting.id,
        isApproved: isApproved,
        notes: notes,
      ));

      print('✅ Created approval result notification for: ${meeting.title}');
    } catch (e) {
      print('❌ Error creating approval result notification: $e');
    }
  }

  /// Lọc thông báo theo loại
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Lọc thông báo theo mức độ ưu tiên
  List<NotificationModel> getNotificationsByPriority(
      NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  /// Cập nhật số thông báo chưa đọc
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
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
      print('❌ NotificationProvider Error: $error');
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  /// Listen to real-time notifications
  void listenToNotifications(String userId) {
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _updateUnreadCount();
        notifyListeners();
      },
      onError: (error) {
        print('❌ Error listening to notifications: $error');
        _setError('Lỗi lắng nghe thông báo: $error');
      },
    );
  }

  /// Gửi thông báo cuộc họp theo scope
  Future<void> sendMeetingNotification(MeetingModel meeting) async {
    try {
      print('🔄 NotificationProvider: sendMeetingNotification started');
      print('🔄 Meeting scope: ${meeting.scope}');
      print('🔄 Current user ID: $_currentUserId');

      List<String> targetUserIds = [];
      String targetAudience = '';

      // Xác định đối tượng nhận thông báo
      switch (meeting.scope) {
        case MeetingScope.company:
          print('🔄 Getting company users...');
          targetUserIds = await _getAllCompanyUsers();
          targetAudience = 'company';
          break;
        case MeetingScope.department:
          print(
              '🔄 Getting department users for: ${meeting.targetDepartmentId}');
          if (meeting.targetDepartmentId != null) {
            targetUserIds =
                await _getDepartmentUsers(meeting.targetDepartmentId!);
            targetAudience = 'department:${meeting.targetDepartmentId}';
          }
          break;
        case MeetingScope.team:
          print('🔄 Getting team users for: ${meeting.targetTeamId}');
          if (meeting.targetTeamId != null) {
            targetUserIds = await _getTeamUsers(meeting.targetTeamId!);
            targetAudience = 'team:${meeting.targetTeamId}';
          }
          break;
        case MeetingScope.personal:
          print('🔄 Getting participants...');
          // Chỉ gửi cho participants
          targetUserIds = meeting.participants.map((p) => p.userId).toList();
          targetAudience = 'participants';
          break;
      }

      print('🔄 Target users found: ${targetUserIds.length}');
      print('🔄 Target user IDs: $targetUserIds');

      // Luôn thêm creator vào danh sách nhận thông báo
      if (!targetUserIds.contains(meeting.creatorId)) {
        targetUserIds.add(meeting.creatorId);
        print('🔄 Added creator to target users: ${meeting.creatorId}');
      }

      // Tạo thông báo cho mỗi user
      for (String userId in targetUserIds) {
        print('🔄 Creating notification for user: $userId');
        await _createNotificationForUser(
          userId: userId,
          title: 'Cuộc họp mới: ${meeting.title}',
          message: _generateMeetingMessage(meeting),
          type: NotificationType.meeting,
          meetingId: meeting.id,
          meetingTitle: meeting.title,
          meetingScope: meeting.scope,
          targetAudience: targetAudience,
        );
      }

      print('✅ Sent meeting notifications to ${targetUserIds.length} users');
    } catch (e) {
      print('❌ Error sending meeting notifications: $e');
    }
  }

  Future<List<String>> _getAllCompanyUsers() async {
    try {
      print('🔄 Getting all company users...');
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      List<String> userIds = snapshot.docs.map((doc) => doc.id).toList();
      print('🔄 Found ${userIds.length} company users: $userIds');
      return userIds;
    } catch (e) {
      print('❌ Error getting company users: $e');
      return [];
    }
  }

  Future<List<String>> _getDepartmentUsers(String departmentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('departmentId', isEqualTo: departmentId)
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Error getting department users: $e');
      return [];
    }
  }

  Future<List<String>> _getTeamUsers(String teamId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('teams', arrayContains: teamId)
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Error getting team users: $e');
      return [];
    }
  }

  String _generateMeetingMessage(MeetingModel meeting) {
    String scopeText = '';
    switch (meeting.scope) {
      case MeetingScope.company:
        scopeText = 'toàn công ty';
        break;
      case MeetingScope.department:
        scopeText = 'phòng ban';
        break;
      case MeetingScope.team:
        scopeText = 'team';
        break;
      case MeetingScope.personal:
        scopeText = 'cá nhân';
        break;
    }

    String dateTime = DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime);
    return 'Cuộc họp $scopeText được tổ chức vào $dateTime. Người tạo: ${meeting.creatorName}';
  }

  Future<void> _createNotificationForUser({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? meetingId,
    String? meetingTitle,
    MeetingScope? meetingScope,
    String? targetAudience,
  }) async {
    try {
      print('🔄 _createNotificationForUser for userId: $userId');
      print('🔄 Current user ID: $_currentUserId');
      print('🔄 Is current user: ${userId == _currentUserId}');

      NotificationModel notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        meetingId: meetingId,
        meetingTitle: meetingTitle,
        meetingScope: meetingScope,
        targetAudience: targetAudience,
      );

      print('🔄 Adding notification to Firestore...');
      DocumentReference docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      print('✅ Notification added to Firestore with ID: ${docRef.id}');

      // Update local state ONLY if notification is for current user
      if (userId == _currentUserId) {
        print('🔄 Updating local state for current user...');
        NotificationModel createdNotification =
            notification.copyWith(id: docRef.id);
        _notifications.insert(0, createdNotification);
        print(
            '🔄 Notifications count before update: ${_notifications.length - 1}');
        print('🔄 Notifications count after update: ${_notifications.length}');

        _updateUnreadCount();
        print('🔄 Unread count after update: $_unreadCount');

        notifyListeners();
        print('✅ Updated local state for current user notification: $title');
      } else {
        print(
            'ℹ️ Notification not for current user, skipping local state update');
      }

      print('✅ Created notification for user $userId: $title');
    } catch (e) {
      print('❌ Error creating notification for user $userId: $e');
    }
  }

  /// Dispose
  @override
  void dispose() {
    super.dispose();
  }
}
