import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_booking_provider.dart';
import '../providers/notification_provider.dart';
import 'booking_reminder_service.dart';

/// Widget that wraps the app and manages lifecycle events for booking reminders
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  BookingReminderService? _reminderService;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderService?.dispose();
    super.dispose();
  }

  void _initializeService() {
    final bookingProvider = context.read<RoomBookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    _reminderService = BookingReminderService(
      bookingProvider: bookingProvider,
      notificationProvider: notificationProvider,
    );

    // Listen to auth changes
    final authProvider = context.read<AuthProvider>();
    authProvider.addListener(_onAuthChanged);
    
    // Start service if already logged in
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userModel?.id;

    if (userId != null && userId != _lastUserId) {
      // User logged in or changed
      _lastUserId = userId;
      _reminderService?.start(userId);
    } else if (userId == null && _lastUserId != null) {
      _lastUserId = null;
      _reminderService?.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _reminderService?.onAppResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily get BookingReminderService from context
extension BookingReminderServiceExtension on BuildContext {
  /// Trigger a manual check for booking reminders and auto-release
  Future<void> checkBookingReminders() async {
    final bookingProvider = read<RoomBookingProvider>();
    final authProvider = read<AuthProvider>();
    final userId = authProvider.userModel?.id;
    
    if (userId != null) {
      // Auto-release expired bookings
      await bookingProvider.autoReleaseExpiredBookings();
      
      // Check for reminders
      await bookingProvider.getBookingsNeedingReminder(userId);
    }
  }
}
