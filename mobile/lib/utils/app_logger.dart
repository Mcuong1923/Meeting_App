import 'package:flutter/foundation.dart';

class AppLogger {
  // Chỉ in log thông thường ở chế độ debug
  static void d(String message, {String tag = 'APP_DEBUG'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  // Log information, vẫn ưu tiên chỉ ở debug mode
  static void i(String message, {String tag = 'INFO'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  // Log error: Always log, ngay cả release (để có thể catch crashlytics, sentry...)
  static void e(String message, {dynamic error, StackTrace? stackTrace, String tag = 'ERROR'}) {
    debugPrint('[$tag] $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }

  /// Helper to mask sensitive strings like FCM Tokens, API Keys
  static String maskSensitive(String? data, {int visibleEndChars = 4}) {
    if (data == null || data.isEmpty) return 'null/empty';
    if (data.length <= visibleEndChars) return '*' * data.length;
    
    final maskedLength = data.length - visibleEndChars;
    final maskedPrefix = '*' * maskedLength;
    final visibleSuffix = data.substring(maskedLength);
    
    return '$maskedPrefix$visibleSuffix';
  }

  // Hàm in ra token với mask
  static void logToken(String tag, String? token) {
    if (kDebugMode) {
      debugPrint('[$tag] Token: ${maskSensitive(token)}');
    }
  }
}
