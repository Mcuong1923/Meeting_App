import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Theme mode
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Color scheme presets
enum ColorScheme {
  blue,
  green,
  purple,
  orange,
  red,
  teal,
  indigo,
  pink,
  custom,
}

/// Font family options
enum FontFamily {
  roboto,
  openSans,
  lato,
  montserrat,
  nunito,
  poppins,
  inter,
  system,
}

/// App language
enum AppLanguage {
  vietnamese,
  english,
}

/// Notification settings
class NotificationSettings {
  final bool enabled;
  final bool meetingReminders;
  final bool meetingUpdates;
  final bool fileNotifications;
  final bool systemNotifications;
  final bool emailNotifications;
  final bool pushNotifications;
  final int reminderMinutes;

  NotificationSettings({
    this.enabled = true,
    this.meetingReminders = true,
    this.meetingUpdates = true,
    this.fileNotifications = true,
    this.systemNotifications = true,
    this.emailNotifications = false,
    this.pushNotifications = true,
    this.reminderMinutes = 15,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] ?? true,
      meetingReminders: map['meetingReminders'] ?? true,
      meetingUpdates: map['meetingUpdates'] ?? true,
      fileNotifications: map['fileNotifications'] ?? true,
      systemNotifications: map['systemNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      reminderMinutes: map['reminderMinutes'] ?? 15,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'meetingReminders': meetingReminders,
      'meetingUpdates': meetingUpdates,
      'fileNotifications': fileNotifications,
      'systemNotifications': systemNotifications,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'reminderMinutes': reminderMinutes,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? meetingReminders,
    bool? meetingUpdates,
    bool? fileNotifications,
    bool? systemNotifications,
    bool? emailNotifications,
    bool? pushNotifications,
    int? reminderMinutes,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      meetingReminders: meetingReminders ?? this.meetingReminders,
      meetingUpdates: meetingUpdates ?? this.meetingUpdates,
      fileNotifications: fileNotifications ?? this.fileNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}

/// Privacy settings
class PrivacySettings {
  final bool shareProfile;
  final bool shareActivity;
  final bool allowSearch;
  final bool showOnlineStatus;
  final bool allowDirectMessages;
  final bool shareCalendar;

  PrivacySettings({
    this.shareProfile = true,
    this.shareActivity = false,
    this.allowSearch = true,
    this.showOnlineStatus = true,
    this.allowDirectMessages = true,
    this.shareCalendar = false,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      shareProfile: map['shareProfile'] ?? true,
      shareActivity: map['shareActivity'] ?? false,
      allowSearch: map['allowSearch'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      allowDirectMessages: map['allowDirectMessages'] ?? true,
      shareCalendar: map['shareCalendar'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shareProfile': shareProfile,
      'shareActivity': shareActivity,
      'allowSearch': allowSearch,
      'showOnlineStatus': showOnlineStatus,
      'allowDirectMessages': allowDirectMessages,
      'shareCalendar': shareCalendar,
    };
  }

  PrivacySettings copyWith({
    bool? shareProfile,
    bool? shareActivity,
    bool? allowSearch,
    bool? showOnlineStatus,
    bool? allowDirectMessages,
    bool? shareCalendar,
  }) {
    return PrivacySettings(
      shareProfile: shareProfile ?? this.shareProfile,
      shareActivity: shareActivity ?? this.shareActivity,
      allowSearch: allowSearch ?? this.allowSearch,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      shareCalendar: shareCalendar ?? this.shareCalendar,
    );
  }
}

/// App settings model
class AppSettings {
  final String id;
  final String userId;
  final AppThemeMode themeMode;
  final ColorScheme colorScheme;
  final Color? customPrimaryColor;
  final Color? customAccentColor;
  final FontFamily fontFamily;
  final double fontSize;
  final AppLanguage language;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final bool compactMode;
  final bool showAvatars;
  final bool enableAnimations;
  final bool enableSounds;
  final bool enableVibration;
  final bool autoSave;
  final bool darkModeScheduled;
  final TimeOfDay? darkModeStartTime;
  final TimeOfDay? darkModeEndTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppSettings({
    required this.id,
    required this.userId,
    this.themeMode = AppThemeMode.system,
    this.colorScheme = ColorScheme.blue,
    this.customPrimaryColor,
    this.customAccentColor,
    this.fontFamily = FontFamily.roboto,
    this.fontSize = 14.0,
    this.language = AppLanguage.vietnamese,
    required this.notificationSettings,
    required this.privacySettings,
    this.compactMode = false,
    this.showAvatars = true,
    this.enableAnimations = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.autoSave = true,
    this.darkModeScheduled = false,
    this.darkModeStartTime,
    this.darkModeEndTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map, String id) {
    return AppSettings(
      id: id,
      userId: map['userId'] ?? '',
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.toString().split('.').last == map['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      colorScheme: ColorScheme.values.firstWhere(
        (scheme) => scheme.toString().split('.').last == map['colorScheme'],
        orElse: () => ColorScheme.blue,
      ),
      customPrimaryColor: map['customPrimaryColor'] != null
          ? Color(map['customPrimaryColor'])
          : null,
      customAccentColor: map['customAccentColor'] != null
          ? Color(map['customAccentColor'])
          : null,
      fontFamily: FontFamily.values.firstWhere(
        (font) => font.toString().split('.').last == map['fontFamily'],
        orElse: () => FontFamily.roboto,
      ),
      fontSize: map['fontSize']?.toDouble() ?? 14.0,
      language: AppLanguage.values.firstWhere(
        (lang) => lang.toString().split('.').last == map['language'],
        orElse: () => AppLanguage.vietnamese,
      ),
      notificationSettings:
          NotificationSettings.fromMap(map['notificationSettings'] ?? {}),
      privacySettings: PrivacySettings.fromMap(map['privacySettings'] ?? {}),
      compactMode: map['compactMode'] ?? false,
      showAvatars: map['showAvatars'] ?? true,
      enableAnimations: map['enableAnimations'] ?? true,
      enableSounds: map['enableSounds'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      autoSave: map['autoSave'] ?? true,
      darkModeScheduled: map['darkModeScheduled'] ?? false,
      darkModeStartTime: map['darkModeStartTime'] != null
          ? TimeOfDay(
              hour: map['darkModeStartTime']['hour'],
              minute: map['darkModeStartTime']['minute'])
          : null,
      darkModeEndTime: map['darkModeEndTime'] != null
          ? TimeOfDay(
              hour: map['darkModeEndTime']['hour'],
              minute: map['darkModeEndTime']['minute'])
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'themeMode': themeMode.toString().split('.').last,
      'colorScheme': colorScheme.toString().split('.').last,
      'customPrimaryColor': customPrimaryColor?.value,
      'customAccentColor': customAccentColor?.value,
      'fontFamily': fontFamily.toString().split('.').last,
      'fontSize': fontSize,
      'language': language.toString().split('.').last,
      'notificationSettings': notificationSettings.toMap(),
      'privacySettings': privacySettings.toMap(),
      'compactMode': compactMode,
      'showAvatars': showAvatars,
      'enableAnimations': enableAnimations,
      'enableSounds': enableSounds,
      'enableVibration': enableVibration,
      'autoSave': autoSave,
      'darkModeScheduled': darkModeScheduled,
      'darkModeStartTime': darkModeStartTime != null
          ? {
              'hour': darkModeStartTime!.hour,
              'minute': darkModeStartTime!.minute
            }
          : null,
      'darkModeEndTime': darkModeEndTime != null
          ? {'hour': darkModeEndTime!.hour, 'minute': darkModeEndTime!.minute}
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppSettings copyWith({
    String? id,
    String? userId,
    AppThemeMode? themeMode,
    ColorScheme? colorScheme,
    Color? customPrimaryColor,
    Color? customAccentColor,
    FontFamily? fontFamily,
    double? fontSize,
    AppLanguage? language,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    bool? compactMode,
    bool? showAvatars,
    bool? enableAnimations,
    bool? enableSounds,
    bool? enableVibration,
    bool? autoSave,
    bool? darkModeScheduled,
    TimeOfDay? darkModeStartTime,
    TimeOfDay? darkModeEndTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customAccentColor: customAccentColor ?? this.customAccentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      compactMode: compactMode ?? this.compactMode,
      showAvatars: showAvatars ?? this.showAvatars,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableSounds: enableSounds ?? this.enableSounds,
      enableVibration: enableVibration ?? this.enableVibration,
      autoSave: autoSave ?? this.autoSave,
      darkModeScheduled: darkModeScheduled ?? this.darkModeScheduled,
      darkModeStartTime: darkModeStartTime ?? this.darkModeStartTime,
      darkModeEndTime: darkModeEndTime ?? this.darkModeEndTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get themeModeDisplayName {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'Sáng';
      case AppThemeMode.dark:
        return 'Tối';
      case AppThemeMode.system:
        return 'Theo hệ thống';
    }
  }

  String get colorSchemeDisplayName {
    switch (colorScheme) {
      case ColorScheme.blue:
        return 'Xanh dương';
      case ColorScheme.green:
        return 'Xanh lá';
      case ColorScheme.purple:
        return 'Tím';
      case ColorScheme.orange:
        return 'Cam';
      case ColorScheme.red:
        return 'Đỏ';
      case ColorScheme.teal:
        return 'Xanh ngọc';
      case ColorScheme.indigo:
        return 'Chàm';
      case ColorScheme.pink:
        return 'Hồng';
      case ColorScheme.custom:
        return 'Tùy chỉnh';
    }
  }

  String get fontFamilyDisplayName {
    switch (fontFamily) {
      case FontFamily.roboto:
        return 'Roboto';
      case FontFamily.openSans:
        return 'Open Sans';
      case FontFamily.lato:
        return 'Lato';
      case FontFamily.montserrat:
        return 'Montserrat';
      case FontFamily.nunito:
        return 'Nunito';
      case FontFamily.poppins:
        return 'Poppins';
      case FontFamily.inter:
        return 'Inter';
      case FontFamily.system:
        return 'Hệ thống';
    }
  }

  String get languageDisplayName {
    switch (language) {
      case AppLanguage.vietnamese:
        return 'Tiếng Việt';
      case AppLanguage.english:
        return 'English';
    }
  }

  /// Get primary color for current color scheme
  Color getPrimaryColor() {
    if (colorScheme == ColorScheme.custom && customPrimaryColor != null) {
      return customPrimaryColor!;
    }

    switch (colorScheme) {
      case ColorScheme.blue:
        return Colors.blue;
      case ColorScheme.green:
        return Colors.green;
      case ColorScheme.purple:
        return Colors.purple;
      case ColorScheme.orange:
        return Colors.orange;
      case ColorScheme.red:
        return Colors.red;
      case ColorScheme.teal:
        return Colors.teal;
      case ColorScheme.indigo:
        return Colors.indigo;
      case ColorScheme.pink:
        return Colors.pink;
      case ColorScheme.custom:
        return customPrimaryColor ?? Colors.blue;
    }
  }

  /// Get accent color for current color scheme
  Color getAccentColor() {
    if (colorScheme == ColorScheme.custom && customAccentColor != null) {
      return customAccentColor!;
    }

    switch (colorScheme) {
      case ColorScheme.blue:
        return Colors.blueAccent;
      case ColorScheme.green:
        return Colors.greenAccent;
      case ColorScheme.purple:
        return Colors.purpleAccent;
      case ColorScheme.orange:
        return Colors.orangeAccent;
      case ColorScheme.red:
        return Colors.redAccent;
      case ColorScheme.teal:
        return Colors.tealAccent;
      case ColorScheme.indigo:
        return Colors.indigoAccent;
      case ColorScheme.pink:
        return Colors.pinkAccent;
      case ColorScheme.custom:
        return customAccentColor ?? Colors.blueAccent;
    }
  }

  /// Get font family string
  String? getFontFamilyString() {
    switch (fontFamily) {
      case FontFamily.roboto:
        return 'Roboto';
      case FontFamily.openSans:
        return 'Open Sans';
      case FontFamily.lato:
        return 'Lato';
      case FontFamily.montserrat:
        return 'Montserrat';
      case FontFamily.nunito:
        return 'Nunito';
      case FontFamily.poppins:
        return 'Poppins';
      case FontFamily.inter:
        return 'Inter';
      case FontFamily.system:
        return null; // Use system default
    }
  }

  /// Check if dark mode should be active based on schedule
  bool shouldUseDarkMode() {
    if (!darkModeScheduled ||
        darkModeStartTime == null ||
        darkModeEndTime == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = darkModeStartTime!;
    final end = darkModeEndTime!;

    // Handle overnight schedule (e.g., 22:00 to 06:00)
    if (start.hour > end.hour) {
      return (now.hour >= start.hour || now.hour < end.hour) ||
          (now.hour == start.hour && now.minute >= start.minute) ||
          (now.hour == end.hour && now.minute < end.minute);
    }

    // Handle same-day schedule (e.g., 20:00 to 23:00)
    return (now.hour > start.hour && now.hour < end.hour) ||
        (now.hour == start.hour && now.minute >= start.minute) ||
        (now.hour == end.hour && now.minute < end.minute);
  }
}

/// Default app settings
class DefaultAppSettings {
  static AppSettings create(String userId) {
    return AppSettings(
      id: '',
      userId: userId,
      themeMode: AppThemeMode.system,
      colorScheme: ColorScheme.blue,
      fontFamily: FontFamily.roboto,
      fontSize: 14.0,
      language: AppLanguage.vietnamese,
      notificationSettings: NotificationSettings(),
      privacySettings: PrivacySettings(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
