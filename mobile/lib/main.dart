import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:metting_app/providers/auth_provider.dart';
import 'package:metting_app/providers/meeting_provider.dart';
import 'package:metting_app/providers/room_provider.dart';
import 'package:metting_app/providers/notification_provider.dart';
import 'package:metting_app/providers/calendar_provider.dart';
import 'package:metting_app/providers/file_provider_simple.dart';
import 'package:metting_app/providers/analytics_provider_simple.dart';
import 'package:metting_app/providers/meeting_minutes_provider.dart';
import 'package:metting_app/providers/theme_provider.dart';
import 'package:metting_app/providers/organization_provider.dart'; // Thêm dòng này
import 'package:metting_app/screens/splash_screen.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/screens/login_screen.dart';
import 'package:metting_app/screens/welcome/welcome_screen.dart';
import 'package:metting_app/screens/role_selection_screen.dart';
import 'package:metting_app/screens/role_approval_screen.dart';
import 'package:metting_app/screens/calendar_screen.dart';
import 'package:metting_app/screens/notification_screen.dart';
import 'package:metting_app/screens/meeting_detail_screen.dart';
import 'package:metting_app/screens/meeting_minutes_editor_screen.dart';
import 'package:metting_app/screens/meeting_minutes_approval_screen.dart';
import 'package:metting_app/utils/migrate_roles.dart';
import 'package:metting_app/utils/room_setup_helper.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize locale data for Vietnamese
  await initializeDateFormatting('vi_VN', null);

  // XÓA TẠO ADMIN TỰ ĐỘNG - ADMIN SẼ ĐƯỢC SETUP THỦ CÔNG
  print('🎯 App started - Manual admin setup mode');

  // XÓA MIGRATE ROLES - KHÔNG TỰ ĐỘNG THAY ĐỔI ROLES NỮA
  print(
      '⚠️ Migrate roles đã bị tắt - bạn control hoàn toàn roles trên Firebase Console');

  // Setup rooms (sẽ được thực hiện khi có admin đăng nhập)
  try {
    bool roomsSetup = await RoomSetupHelper.isRoomsSetupCompleted();
    if (!roomsSetup) {
      print('⚠️ Chưa có phòng họp - sẽ setup khi admin đăng nhập lần đầu');
    } else {
      print('✅ Rooms already setup');
    }
  } catch (e) {
    print('⚠️ Room setup check error: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => SimpleFileProvider()),
        ChangeNotifierProvider(create: (_) => SimpleAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => MeetingMinutesProvider()),
        ChangeNotifierProvider(
            create: (_) => OrganizationProvider()), // Thêm dòng này
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Meeting Management',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const WelcomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/role-selection': (context) => const RoleSelectionScreen(),
              '/role-approval': (context) => const RoleApprovalScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/notifications': (context) => const NotificationScreen(),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/meeting-detail':
                  final meetingId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (context) =>
                        MeetingDetailScreen(meetingId: meetingId),
                  );
                case '/meeting-minutes-editor':
                  final minutesId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (context) =>
                        MeetingMinutesEditorScreen(minutesId: minutesId),
                  );
                case '/meeting-minutes-approval':
                  final minutesId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (context) =>
                        MeetingMinutesApprovalScreen(minutesId: minutesId),
                  );
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }
}
