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
import 'package:metting_app/screens/splash_screen.dart';
import 'package:metting_app/screens/home_screen.dart';
import 'package:metting_app/screens/login_screen.dart';
import 'package:metting_app/screens/welcome/welcome_screen.dart';
import 'package:metting_app/screens/role_selection_screen.dart';
import 'package:metting_app/screens/role_approval_screen.dart';
import 'package:metting_app/utils/create_super_admin.dart';
import 'package:metting_app/utils/migrate_roles.dart';
import 'package:metting_app/utils/room_setup_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Tự động tạo Super Admin thô nếu chưa có và fix role format
  try {
    final hasSuperAdmin = await CreateSuperAdmin.hasSuperAdmin();
    if (!hasSuperAdmin) {
      await CreateSuperAdmin.createSuperAdminNow();
    } else {
      print('✅ Super Admin đã tồn tại, bỏ qua việc tạo mới');
    }

    // Migrate roles: superAdmin->admin, admin->director
    await MigrateRoles.migrateAllRoles();

    // Kiểm tra role sau khi migrate
    await MigrateRoles.checkRolesAfterMigration();

    // Auto setup phòng họp nếu chưa có (chỉ khi có admin)
    print('🏗️ Kiểm tra setup phòng họp...');
    final isRoomsSetup = await RoomSetupHelper.isRoomsSetupCompleted();
    if (!isRoomsSetup) {
      print('⏳ Chưa có phòng nào, sẽ setup sau khi có Admin đăng nhập');
    } else {
      print('✅ Phòng họp đã được setup');
    }
  } catch (e) {
    print('⚠️ Không thể kiểm tra/tạo Super Admin: $e');
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => SimpleFileProvider()),
        ChangeNotifierProvider(create: (_) => SimpleAnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'Meeting Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/role-approval': (context) => const RoleApprovalScreen(),
        },
      ),
    );
  }
}
