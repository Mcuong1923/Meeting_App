import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeColorKey = 'theme_color';
  static const String _isDarkModeKey = 'is_dark_mode';

  Color _primaryColor = const Color(0xFF4A90E2);
  bool _isDarkMode = false;

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ),
        primaryColor: _primaryColor,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryColor;
            }
            return Colors.white;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryColor.withOpacity(0.3);
            }
            return const Color(0xFFE0E0E0);
          }),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ),
        primaryColor: _primaryColor,
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryColor;
            }
            return Colors.white;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryColor.withOpacity(0.3);
            }
            return const Color(0xFF39393D);
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white70),
          labelSmall: TextStyle(color: Colors.white70),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          subtitleTextStyle: TextStyle(color: Colors.white70),
        ),
      );

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_themeColorKey);
    final darkMode = prefs.getBool(_isDarkModeKey) ?? false;

    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    _isDarkMode = darkMode;
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, isDark);
    notifyListeners();
  }

  // Predefined colors for color picker
  static const List<Color> predefinedColors = [
    // Reds & Pinks
    Color(0xFFFF3B30), Color(0xFFFF2D92), Color(0xFFE91E63), Color(0xFFFF006B),
    Color(0xFF9C27B0), Color(0xFFBB86FC),

    // Purples & Blues
    Color(0xFF673AB7), Color(0xFF5856D6), Color(0xFF3F51B5), Color(0xFF2196F3),
    Color(0xFF00BCD4), Color(0xFF0099CC),

    // Cyans & Teals
    Color(0xFF00DDFF), Color(0xFF00C7BE), Color(0xFF009688), Color(0xFF00E676),
    Color(0xFF4CAF50), Color(0xFF8BC34A),

    // Greens
    Color(0xFF4CAF50), Color(0xFF64DD17), Color(0xFF76FF03), Color(0xFFCDDC39),
    Color(0xFFFFEB3B), Color(0xFFFFC107),

    // Yellows & Oranges
    Color(0xFFFFEB3B), Color(0xFFFFD600), Color(0xFFFF9800), Color(0xFFFF8F00),
    Color(0xFFFF5722), Color(0xFFFF6D00),

    // Reds & Browns
    Color(0xFFE91E63), Color(0xFFD32F2F), Color(0xFF8D6E63), Color(0xFF607D8B),
    Color(0xFF9E9E9E),

    // Light Blues
    Color(0xFFE3F2FD), Color(0xFF90CAF9), Color(0xFF42A5F5), Color(0xFF1E88E5),
    Color(0xFF1976D2),

    // Dark Blues
    Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF0A3D91), Color(0xFF003C8F),
  ];
}
