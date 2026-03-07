import 'dart:async';
import '../providers/room_booking_provider.dart';
import '../providers/notification_provider.dart';
import '../models/room_booking_model.dart';
import '../utils/app_logger.dart';

/// Service to handle booking reminders and auto-release
/// This service should be initialized on app start and called on app lifecycle events
class BookingReminderService {
  final RoomBookingProvider _bookingProvider;
  final NotificationProvider _notificationProvider;
  
  Timer? _reminderCheckTimer;
  bool _isRunning = false;
  String? _currentUserId;
  
  BookingReminderService({
    required RoomBookingProvider bookingProvider,
    required NotificationProvider notificationProvider,
  })  : _bookingProvider = bookingProvider,
        _notificationProvider = notificationProvider;

  /// Start the reminder check service
  void start(String userId) {
    _currentUserId = userId;
    _isRunning = true;
    
    // Run immediately on start
    _checkBookingsAndReminders();
    
    // Then run periodically every minute
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkBookingsAndReminders(),
    );
    
    AppLogger.d('Started for user $userId', tag: 'BookingReminder');
  }

  /// Stop the service
  void stop() {
    _isRunning = false;
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = null;
    AppLogger.d('Stopped', tag: 'BookingReminder');
  }

  /// Run checks on app resume
  Future<void> onAppResume() async {
    if (!_isRunning || _currentUserId == null) return;
    
    AppLogger.d('App resumed, running checks...', tag: 'BookingReminder');
    await _checkBookingsAndReminders();
  }

  /// Main check function
  Future<void> _checkBookingsAndReminders() async {
    if (_currentUserId == null) return;
    
    try {
      // 1. Auto-release expired bookings
      final releasedCount = await _bookingProvider.autoReleaseExpiredBookings();
      if (releasedCount > 0) {
        AppLogger.d('Auto-released $releasedCount expired bookings', tag: 'BookingReminder');
      }
      
      // 2. Check for bookings needing reminders
      final bookingsNeedingReminder = await _bookingProvider.getBookingsNeedingReminder(_currentUserId!);
      
      for (final booking in bookingsNeedingReminder) {
        await _sendReminderForBooking(booking);
      }
      
      if (bookingsNeedingReminder.isNotEmpty) {
        AppLogger.d('Sent ${bookingsNeedingReminder.length} reminders', tag: 'BookingReminder');
      }
    } catch (e) {
      AppLogger.e('Booking check error', error: e, tag: 'BookingReminder');
    }
  }

  /// Send reminder for a specific booking
  Future<void> _sendReminderForBooking(RoomBooking booking) async {
    try {
      // Create notification
      await _notificationProvider.createBookingReminder(
        userId: booking.createdBy,
        bookingId: booking.id,
        bookingTitle: booking.title,
        roomName: booking.roomName,
        startTime: booking.startTime,
        endTime: booking.endTime,
      );
      
      // Mark reminder as sent
      await _bookingProvider.markReminderSent(booking.id);
      
      AppLogger.d('Sent reminder for booking ${booking.id}', tag: 'BookingReminder');
    } catch (e) {
      AppLogger.e('Error sending reminder', error: e, tag: 'BookingReminder');
    }
  }

  /// Check a specific booking and send reminder if needed
  Future<void> checkAndSendReminder(RoomBooking booking) async {
    if (booking.shouldSendReminder) {
      await _sendReminderForBooking(booking);
    }
  }

  /// Notify user when their booking is auto-released
  Future<void> notifyBookingReleased(RoomBooking booking) async {
    try {
      await _notificationProvider.createBookingExpiredNotification(
        userId: booking.createdBy,
        bookingTitle: booking.title,
        roomName: booking.roomName,
        startTime: booking.startTime,
      );
      
      AppLogger.d('Notified about released booking ${booking.id}', tag: 'BookingReminder');
    } catch (e) {
      AppLogger.e('Error notifying about released booking', error: e, tag: 'BookingReminder');
    }
  }

  void dispose() {
    stop();
  }
}
