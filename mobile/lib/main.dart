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
import 'package:metting_app/providers/organization_provider.dart';
import 'package:metting_app/providers/room_booking_provider.dart';
import 'package:metting_app/providers/user_management_provider.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/screens/welcome/welcome_screen.dart';
import 'package:metting_app/screens/role_selection_screen.dart';
import 'package:metting_app/screens/role_approval_screen.dart';
import 'package:metting_app/screens/calendar_screen.dart';
import 'package:metting_app/screens/notification_screen.dart';
import 'package:metting_app/screens/meeting_detail_screen.dart';
import 'package:metting_app/screens/meeting_minutes_editor_screen.dart';
import 'package:metting_app/screens/meeting_minutes_approval_screen.dart';
import 'package:metting_app/screens/meeting_create_screen.dart';
import 'package:metting_app/services/app_lifecycle_service.dart';
import 'package:metting_app/utils/app_logger.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase init log (1 dòng duy nhất)
  AppLogger.d('Firebase ready: ${Firebase.app().options.projectId}', tag: 'CONFIG');

  // Initialize locale data for Vietnamese
  await initializeDateFormatting('vi_VN', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        ChangeNotifierProvider(create: (_) => OrganizationProvider()),
        ChangeNotifierProvider(create: (_) => RoomBookingProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
      ],
      child: Builder(
        builder: (ctx) {
          // Wire AuthProvider.onLogoutCallback → RoomProvider.unsubscribeOccupancy()
          // Làm sau first frame để context có providers sẵn sàng
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authProv = ctx.read<AuthProvider>();
            final roomProv = ctx.read<RoomProvider>();
            authProv.onLogoutCallback = () {
              roomProv.unsubscribeOccupancy();
            };
          });
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return AppLifecycleWrapper(
                child: MaterialApp(
                  navigatorKey: navigatorKey,
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
                    '/meeting/create': (context) => const MeetingCreateScreen(),
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
                        final args = settings.arguments as Map<String, dynamic>;
                        return MaterialPageRoute(
                          builder: (context) => MeetingMinutesEditorScreen(
                            meetingId: args['meetingId'],
                            existingMinutes: args['existingMinutes'],
                          ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
