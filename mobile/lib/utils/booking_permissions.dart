import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/room_model.dart';
import '../models/room_booking_model.dart';

/// Business rules constants
class BookingRules {
  // Duration limits
  static const int minBookingDurationMinutes = 15;
  static const int maxBookingDurationMinutes = 480; // 8 hours
  static const int minAdvanceBookingMinutes = 15;
  static const int maxAdvanceBookingDays = 30;
  
  // Working hours
  static const int workingHoursStart = 7; // 7:00 AM
  static const int workingHoursEnd = 22; // 10:00 PM
  
  // Recurring
  static const int maxRecurringWeeks = 12;
  
  // Quick Booking - Anti-abuse rules
  static const int maxQuickBookingsPerDay = 3;  // Daily quota
  static const int reminderMinutesBefore = 15;  // Send reminder 15 min before
  static const int autoReleaseMinutesAfterStart = 10;  // Auto-release if not converted
  static const int violationThreshold = 2;  // Violations before restricted
  static const int violationPeriodDays = 7;  // Rolling 7 days window
  static const int restrictedUnlockHours = 24;  // Auto-unlock after 24h
  
  // Duration chips for quick booking (in minutes)
  static const List<int> quickBookingDurations = [30, 60, 90, 120];
  static const int defaultQuickBookingDuration = 60;
  
  // Quota by role
  static int getMaxQuickBookingsPerDay(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 999; // Unlimited
      case UserRole.director:
        return 10;
      case UserRole.manager:
        return 5;
      default:
        return maxQuickBookingsPerDay;
    }
  }
  
  // Max advance days by role
  static int getMaxAdvanceBookingDays(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 60;
      case UserRole.director:
        return 30;
      case UserRole.manager:
        return 14;
      default:
        return 7;
    }
  }
  
  // Max duration by role (in minutes)
  static int getMaxBookingDuration(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 480; // 8 hours
      case UserRole.director:
        return 240; // 4 hours
      case UserRole.manager:
        return 180; // 3 hours
      default:
        return 120; // 2 hours
    }
  }
}

/// User booking statistics for anti-abuse
class UserBookingStats {
  final String userId;
  final int quickBookingsToday;
  final int violationsLast7Days;
  final bool isRestricted;
  final DateTime? restrictedAt;
  final DateTime? lastViolationAt;

  UserBookingStats({
    required this.userId,
    this.quickBookingsToday = 0,
    this.violationsLast7Days = 0,
    this.isRestricted = false,
    this.restrictedAt,
    this.lastViolationAt,
  });

  /// Check if user can create quick booking
  bool canCreateQuickBooking(UserRole role) {
    final maxBookings = BookingRules.getMaxQuickBookingsPerDay(role);
    return quickBookingsToday < maxBookings;
  }

  /// Remaining quick bookings for today
  int remainingQuickBookings(UserRole role) {
    final maxBookings = BookingRules.getMaxQuickBookingsPerDay(role);
    return (maxBookings - quickBookingsToday).clamp(0, maxBookings);
  }

  /// Check if restriction should be auto-unlocked
  bool shouldAutoUnlock() {
    if (!isRestricted || restrictedAt == null) return false;
    final unlockTime = restrictedAt!.add(
      const Duration(hours: BookingRules.restrictedUnlockHours)
    );
    return DateTime.now().isAfter(unlockTime);
  }

  factory UserBookingStats.fromMap(Map<String, dynamic> map) {
    return UserBookingStats(
      userId: map['userId'] ?? '',
      quickBookingsToday: map['quickBookingsToday'] ?? 0,
      violationsLast7Days: map['violationsLast7Days'] ?? 0,
      isRestricted: map['isRestricted'] ?? false,
      restrictedAt: map['restrictedAt']?.toDate(),
      lastViolationAt: map['lastViolationAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'quickBookingsToday': quickBookingsToday,
      'violationsLast7Days': violationsLast7Days,
      'isRestricted': isRestricted,
      'restrictedAt': restrictedAt,
      'lastViolationAt': lastViolationAt,
    };
  }
}

/// Helper class for booking permissions
class BookingPermissions {
  /// Check if user can view booking details
  static bool canViewBookingDetails(UserModel user, RoomBooking booking) {
    // Admin can view all
    if (user.role == UserRole.admin) return true;
    
    // Owner can view own booking
    if (booking.createdBy == user.id) return true;
    
    // Director can view all in their department
    if (user.role == UserRole.director) return true;
    
    // Manager can view team bookings
    if (user.role == UserRole.manager && 
        _sameTeamOrDepartment(user, booking)) {
      return true;
    }
    
    return false;
  }

  /// Check if user can create booking for others
  static bool canCreateBookingForOthers(UserModel user) {
    return user.role == UserRole.admin || 
           user.role == UserRole.director || 
           user.role == UserRole.manager;
  }

  /// Check if user can book VIP/restricted rooms
  static bool canBookVipRoom(UserModel user) {
    return user.role == UserRole.admin || 
           user.role == UserRole.director;
  }

  /// Check if user can book outside working hours
  static bool canBookOutsideWorkingHours(UserModel user) {
    return user.role == UserRole.admin || 
           user.role == UserRole.director;
  }

  /// Check if user can create recurring bookings
  static bool canCreateRecurringBooking(UserModel user) {
    return user.role == UserRole.admin || 
           user.role == UserRole.director || 
           user.role == UserRole.manager;
  }

  /// Check if user can edit a booking
  static bool canEditBooking(UserModel user, RoomBooking booking) {
    // Admin can edit all
    if (user.role == UserRole.admin) return true;
    
    // Owner can edit own pending booking
    if (booking.createdBy == user.id && 
        booking.status == BookingStatus.pending) {
      return true;
    }
    
    // Director can edit department bookings
    if (user.role == UserRole.director) return true;
    
    // Manager can edit team's pending bookings
    if (user.role == UserRole.manager && 
        _sameTeamOrDepartment(user, booking) &&
        booking.status == BookingStatus.pending) {
      return true;
    }
    
    return false;
  }

  /// Check if user can cancel a booking
  static bool canCancelBooking(UserModel user, RoomBooking booking) {
    // Admin can cancel all
    if (user.role == UserRole.admin) return true;
    
    // Owner can cancel own booking
    if (booking.createdBy == user.id) return true;
    
    // Director can cancel department bookings
    if (user.role == UserRole.director) return true;
    
    return false;
  }

  /// Check if user can approve bookings
  static bool canApproveBooking(UserModel user) {
    return user.role == UserRole.admin || 
           user.role == UserRole.director;
  }

  /// Check if user can override booking conflicts
  static bool canOverrideConflict(UserModel user) {
    return user.role == UserRole.admin;
  }

  /// Check if booking time is within working hours
  static bool isWithinWorkingHours(DateTime startTime, DateTime endTime) {
    return startTime.hour >= BookingRules.workingHoursStart &&
           endTime.hour <= BookingRules.workingHoursEnd;
  }

  /// Validate booking creation
  static BookingValidationResult validateBooking({
    required UserModel user,
    required RoomModel room,
    required DateTime startTime,
    required DateTime endTime,
    bool isRecurring = false,
  }) {
    final now = DateTime.now();
    final durationMinutes = endTime.difference(startTime).inMinutes;

    // Check duration
    if (durationMinutes < BookingRules.minBookingDurationMinutes) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Thời lượng tối thiểu là ${BookingRules.minBookingDurationMinutes} phút',
      );
    }

    if (durationMinutes > BookingRules.maxBookingDurationMinutes) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Thời lượng tối đa là ${BookingRules.maxBookingDurationMinutes ~/ 60} giờ',
      );
    }

    // Check advance booking
    if (startTime.isBefore(now.add(const Duration(minutes: BookingRules.minAdvanceBookingMinutes)))) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Phải đặt trước ít nhất ${BookingRules.minAdvanceBookingMinutes} phút',
      );
    }

    if (startTime.isAfter(now.add(const Duration(days: BookingRules.maxAdvanceBookingDays)))) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Chỉ được đặt trước tối đa ${BookingRules.maxAdvanceBookingDays} ngày',
      );
    }

    // Check working hours
    if (!isWithinWorkingHours(startTime, endTime) && 
        !canBookOutsideWorkingHours(user)) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Chỉ được đặt trong giờ hành chính (${BookingRules.workingHoursStart}:00 - ${BookingRules.workingHoursEnd}:00)',
      );
    }

    // Check recurring permission
    if (isRecurring && !canCreateRecurringBooking(user)) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Bạn không có quyền tạo booking lặp lại',
      );
    }

    // Check room status
    if (room.status == RoomStatus.maintenance) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Phòng đang bảo trì',
      );
    }

    if (room.status == RoomStatus.disabled) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Phòng đã bị tạm ngưng',
      );
    }

    return BookingValidationResult(isValid: true);
  }

  /// Check if user is in same team or department as booking creator
  static bool _sameTeamOrDepartment(UserModel user, RoomBooking booking) {
    // Check department
    if (user.departmentId != null && 
        booking.createdByDepartmentId == user.departmentId) {
      return true;
    }
    
    // Check team (if booking creator is in user's team)
    // This would require additional data, simplified for now
    return false;
  }
}

/// Result of booking validation
class BookingValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool requiresAdminApproval;

  BookingValidationResult({
    required this.isValid,
    this.errorMessage,
    this.requiresAdminApproval = false,
  });
}

/// Quick booking specific validation result
class QuickBookingValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool requiresAdminApproval;
  final int remainingQuota;
  final bool isRestricted;

  QuickBookingValidationResult({
    required this.isValid,
    this.errorMessage,
    this.requiresAdminApproval = false,
    this.remainingQuota = 0,
    this.isRestricted = false,
  });
}

/// Extension methods for quick booking validation
extension QuickBookingPermissions on BookingPermissions {
  /// Validate quick booking creation
  static QuickBookingValidationResult validateQuickBooking({
    required UserModel user,
    required RoomModel room,
    required DateTime startTime,
    required DateTime endTime,
    required UserBookingStats stats,
  }) {
    // Check if user is restricted
    if (stats.isRestricted && !stats.shouldAutoUnlock()) {
      return QuickBookingValidationResult(
        isValid: true, // Can still book but needs approval
        requiresAdminApproval: true,
        isRestricted: true,
        remainingQuota: stats.remainingQuickBookings(user.role),
        errorMessage: 'Bạn đang bị hạn chế. Booking cần admin duyệt.',
      );
    }

    // Check daily quota
    if (!stats.canCreateQuickBooking(user.role)) {
      return QuickBookingValidationResult(
        isValid: false,
        errorMessage: 'Bạn đã đạt giới hạn ${BookingRules.getMaxQuickBookingsPerDay(user.role)} lượt đặt nhanh/ngày.',
        remainingQuota: 0,
      );
    }

    // Check duration limit by role
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final maxDuration = BookingRules.getMaxBookingDuration(user.role);
    if (durationMinutes > maxDuration) {
      return QuickBookingValidationResult(
        isValid: false,
        errorMessage: 'Thời lượng tối đa cho vai trò của bạn là ${maxDuration ~/ 60} giờ.',
        remainingQuota: stats.remainingQuickBookings(user.role),
      );
    }

    // Check advance booking limit by role
    final maxAdvanceDays = BookingRules.getMaxAdvanceBookingDays(user.role);
    if (startTime.isAfter(DateTime.now().add(Duration(days: maxAdvanceDays)))) {
      return QuickBookingValidationResult(
        isValid: false,
        errorMessage: 'Bạn chỉ được đặt trước tối đa $maxAdvanceDays ngày.',
        remainingQuota: stats.remainingQuickBookings(user.role),
      );
    }

    // Use standard validation for other rules
    final standardValidation = BookingPermissions.validateBooking(
      user: user,
      room: room,
      startTime: startTime,
      endTime: endTime,
    );

    if (!standardValidation.isValid) {
      return QuickBookingValidationResult(
        isValid: false,
        errorMessage: standardValidation.errorMessage,
        remainingQuota: stats.remainingQuickBookings(user.role),
      );
    }

    return QuickBookingValidationResult(
      isValid: true,
      remainingQuota: stats.remainingQuickBookings(user.role) - 1, // After this booking
    );
  }

  /// Check if quick booking should be auto-released
  static bool shouldAutoRelease(RoomBooking booking) {
    if (!booking.isQuickBooking) return false;
    if (!booking.requiresMeeting) return false;
    if (booking.meetingId != null) return false;
    if (booking.status != BookingStatus.reserved) return false;
    
    return booking.isOverdueForConversion;
  }

  /// Check if reminder should be sent for booking
  static bool shouldSendReminder(RoomBooking booking) {
    return booking.shouldSendReminder;
  }

  /// Get violation count message
  static String getViolationWarning(UserBookingStats stats) {
    if (stats.violationsLast7Days == 0) return '';
    
    final remaining = BookingRules.violationThreshold - stats.violationsLast7Days;
    if (remaining <= 0) {
      return 'Bạn đang bị hạn chế do ${stats.violationsLast7Days} lần vi phạm.';
    }
    return 'Cảnh báo: Còn $remaining lần vi phạm nữa sẽ bị hạn chế đặt phòng.';
  }
}
