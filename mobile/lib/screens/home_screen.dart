import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/providers/meeting_provider.dart';
import 'package:metting_app/providers/analytics_provider_simple.dart';
import 'package:metting_app/models/user_role.dart';
import 'package:metting_app/models/meeting_model.dart';
import 'package:metting_app/screens/login_screen.dart';
import 'package:metting_app/constants.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:iconly/iconly.dart';
import 'meeting_list_screen.dart';
import 'room_management_screen.dart';
import 'meeting_create_screen.dart';
import 'settings_screen.dart';

import 'package:metting_app/components/menu_item.dart';
import 'admin_dashboard_screen.dart';
import 'package:metting_app/providers/notification_provider.dart';
import 'calendar_screen.dart';
import 'package:intl/intl.dart';
import 'minutes_archive_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ZoomDrawerController zoomDrawerController = ZoomDrawerController();

  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    zoomDrawerController.close?.call();
  }

  @override
  void initState() {
    super.initState();
    // Kiểm tra xem user có cần chọn vai trò không
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleSelection();
      _loadNotifications();
      _loadAllData();
    });
  }

  void _checkRoleSelection() {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    if (authProvider.needsRoleSelection) {
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }

  /// Lắng nghe được gọi khi AuthProvider notify (userModel đã load xong)
  // _onAuthChanged hiện không còn được sử dụng, giữ lại comment nếu cần tái dùng trong tương lai.

  void _loadNotifications() {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    print('🔄 Home: _loadNotifications called');
    print(
        '🔄 Home: AuthProvider user model is null: ${authProvider.userModel == null}');

    if (authProvider.userModel != null) {
      final user = authProvider.userModel!;
      print(
          '👤 Home: Current user id=${user.id}, role=${user.role}, departmentId=${user.departmentId}, teamId=${user.teamId}');
      print(
          '🔄 Home: Loading notifications for user ${user.id}');
      print('🔄 Home: User display name: ${user.displayName}');
      notificationProvider.loadNotifications(user.id);
    } else {
      print('⚠️ Home: No user model found, cannot load notifications');
    }
  }

  void _loadAllData() {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);
    final analyticsProvider =
        Provider.of<SimpleAnalyticsProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      final user = authProvider.userModel!;
      print(
          '🏠 Home._loadAllData for user id=${user.id}, role=${user.role}, departmentId=${user.departmentId}, teamId=${user.teamId}');

      // Load meeting data (scoped by role in MeetingProvider)
      meetingProvider.loadMeetings(user);

      // Load analytics data ONLY for admins (global dashboard)
      if (user.role == UserRole.admin) {
        print(
            '📊 Home: User is admin, loading global analytics from analytics_events');
        analyticsProvider.loadAnalytics();
      } else {
        print(
            '📊 Home: Skipping analytics_events queries for non-admin role ${user.role}');
      }

      print('✅ Home: Started loading scoped data');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer lắng nghe AuthProvider để redirect khi userModel thay đổi
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, _) {
        // Redirect ngay khi phát hiện user pending (userModel có thể load muộn)
        if (authProvider.needsRoleSelection) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/role-selection');
            }
          });
        }

        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return WillPopScope(
          onWillPop: () async {
            // Prevent back button from exiting the app/going to login
            // Instead, do nothing or show exit confirmation
            return false;
          },
          child: ZoomDrawer(
            controller: zoomDrawerController,
            menuBackgroundColor: isDark ? colorScheme.surface : Colors.white,
            shadowLayer1Color:
                isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
            shadowLayer2Color: isDark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.7)
                : const Color(0xFFE6E6E6).withOpacity(0.3),
            borderRadius: 32.0,
            showShadow: true,
            style: DrawerStyle.defaultStyle,
            angle: -12.0,
            drawerShadowsBackgroundColor:
                isDark ? Colors.black38 : Colors.grey.shade300,
            slideWidth: MediaQuery.of(context).size.width * 0.7,
            menuScreen: _buildMenuScreen(context),
            mainScreen: _buildMainScreen(context),
          ),
        );
      },
    );
  }

  Widget _buildMenuScreen(BuildContext context) {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor.withOpacity(0.05),
            kAccentColor.withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Avatar và thông tin user
              Consumer<app_auth.AuthProvider>(
                builder: (context, authProvider, child) {
                  final userModel = authProvider.userModel;
                  final displayName = userModel?.displayName ?? 'Người dùng';
                  final email = userModel?.email ?? 'user@example.com';
                  final role = userModel?.role ?? UserRole.employee;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?u=${userModel?.email ?? 'default'}',
                            ),
                            backgroundColor: colorScheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // Menu items với chức năng quản lý
              // Menu items với chức năng quản lý
              Expanded(
                child: Consumer<app_auth.AuthProvider>(
                  builder: (context, authProvider, child) {
                    final userModel = authProvider.userModel;
                    final userRole = userModel?.role;
                    final hasSystemManagementAccess =
                        userRole == UserRole.admin ||
                        userRole == UserRole.director ||
                        userRole == UserRole.manager;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          MenuItem(
                            title: 'Tạo Cuộc Họp',
                            icon: IconlyBold.plus,
                            isSelected: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MeetingCreateScreen(),
                                ),
                              );
                              zoomDrawerController.close?.call();
                            },
                          ),
                          Divider(
                            color: Colors.grey.shade300,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                            height: 24, // Combine height with SizedBox functionality
                          ),
                          
                          MenuItem(
                            title: 'Lịch cuộc họp',
                            icon: IconlyBold.calendar,
                            isSelected: _selectedIndex == 2,
                            onTap: () {
                              _onMenuItemTapped(2);
                            },
                          ),
                          Divider(
                            color: Colors.grey.shade300,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                            height: 24,
                          ),
                          
                          MenuItem(
                            title: 'Biên bản cuộc họp',
                            icon: IconlyBold.document,
                            isSelected: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MinutesArchiveScreen(),
                                ),
                              );
                              zoomDrawerController.close?.call();
                            },
                          ),

                          // Quản lý hệ thống:
                          // - Admin: full quyền trong dashboard
                          // - Director/Manager: chỉ thấy các mục được giới hạn bởi backend/rules
                          if (hasSystemManagementAccess) ...[
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                color: colorScheme.outline.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MenuItem(
                              title: 'Quản lý hệ thống',
                              icon: Icons.settings_outlined,
                              isSelected: false,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminDashboardScreen(),
                                  ),
                                );
                                zoomDrawerController.close?.call();
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Logout button
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: MenuItem(
                  title: 'Đăng Xuất',
                  icon: IconlyBold.logout,
                  isSelected: false,
                  onTap: () async {
                    try {
                      await authProvider.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đăng xuất thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi đăng xuất: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context) {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    final List<String> titles = [
      'Trang Chủ',
      'Cuộc Họp',
      'Lịch',
      'Phòng Họp',
      'Cài Đặt'
    ];

    final List<Widget> body = [
      // Dùng trực tiếp userModel (đã cache) thay vì gọi Firestore lại
      Builder(
        builder: (context) {
          final userModel = authProvider.userModel;
          final displayName = userModel?.displayName?.trim().isNotEmpty == true
              ? userModel!.displayName
              : (userModel?.email.split('@').first ?? 'Người dùng');
          return _buildMainContent(displayName);
        },
      ),
      const MeetingListScreen(),
      const CalendarScreen(),
      const RoomManagementScreen(),
      const SettingsScreen(),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: kScaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              IconlyBold.category,
              color: kPrimaryColor,
              size: 20,
            ),
          ),
          onPressed: () => zoomDrawerController.toggle?.call(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kPrimaryColor,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(IconlyLight.home),
            selectedIcon: Icon(IconlyBold.home),
            label: 'Trang Chủ',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.video),
            selectedIcon: Icon(IconlyBold.video),
            label: 'Cuộc Họp',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.calendar),
            selectedIcon: Icon(IconlyBold.calendar),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.work),
            selectedIcon: Icon(IconlyBold.work),
            label: 'Phòng Họp',
          ),
          NavigationDestination(
            icon: Icon(IconlyLight.setting),
            selectedIcon: Icon(IconlyBold.setting),
            label: 'Cài Đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(String displayName) {
    // Responsive scale based on iPhone 11 (375px width)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final horizontalPadding = (16 * scale).clamp(12.0, 24.0);
    final verticalSpacing = (24 * scale).clamp(16.0, 32.0);
    
    // Safe area bottom padding for devices with gesture navigation
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top padding
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16 * scale,
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildUpcomingMeetingCard(displayName),
          ),
        ),
        
        // Dashboard section
        SliverPadding(
          padding: EdgeInsets.only(
            top: verticalSpacing,
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildDashboardSection(),
          ),
        ),
        
        // Recent meetings section
        SliverPadding(
          padding: EdgeInsets.only(
            top: verticalSpacing,
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: bottomPadding + 16, // Safe area + extra padding
          ),
          sliver: SliverToBoxAdapter(
            child: _buildRecentMeetingsSection(),
          ),
        ),
      ],
    );
  }

  // Helper function to get Vietnamese role name
  String _getVietnameseRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.director:
        return 'Giám đốc';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.employee:
        return 'Nhân viên';
      case UserRole.guest:
        return 'Khách';
      default:
        return 'Nhân viên';
    }
  }

  Widget _buildUpcomingMeetingCard(String displayName) {
    // Responsive scale based on iPhone 11 (375px width)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        final userModel = authProvider.userModel;

        // Handle display name - lấy từ email nếu displayName trống
        String actualDisplayName = displayName;
        if (userModel != null) {
          if (userModel.displayName.trim().isNotEmpty) {
            actualDisplayName = userModel.displayName;
          } else if (userModel.email.isNotEmpty) {
            // Lấy tên từ email (phần trước @)
            actualDisplayName = userModel.email.split('@').first;
          }
        }

        // Handle department and role
        String departmentAndRole = '';
        if (userModel != null) {
          // Nếu chưa được duyệt thì hiển thị "Khách"
          if (!userModel.isRoleApproved) {
            departmentAndRole = 'Khách';
          } else {
            final roleName = _getVietnameseRoleName(userModel.role);
            final departmentName = userModel.departmentName?.trim();

            // Nếu có phòng ban thì hiển thị "Phòng ban • Vai trò", nếu không thì chỉ "Vai trò"
            if (departmentName != null && departmentName.isNotEmpty) {
              departmentAndRole = '$departmentName • $roleName';
            } else {
              departmentAndRole = roleName;
            }
          }
        } else {
          departmentAndRole = 'Khách';
        }

        // Responsive values
        final cardPadding = (20 * scale).clamp(16.0, 24.0);
        final avatarRadius = (30 * scale).clamp(24.0, 36.0);
        final nameFontSize = (20 * scale).clamp(16.0, 24.0);
        final roleFontSize = (14 * scale).clamp(12.0, 16.0);
        
        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: kAccentColor, // A nice blue/purple color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kAccentColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section: User info and video call icon
              Row(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?u=${userModel?.email ?? 'default'}'),
                  ),
                  SizedBox(width: 15 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actualDisplayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5 * scale),
                        Text(
                          departmentAndRole,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: roleFontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 15 * scale),
                  Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam_outlined,
                      color: kAccentColor,
                      size: (24 * scale).clamp(20.0, 28.0),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15 * scale),
              const Divider(color: Colors.white24),
              SizedBox(height: 15 * scale),

              // Middle section: Date and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM, EEEE', 'vi_VN')
                                .format(DateTime.now()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_outlined,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20 * scale),

              // Bottom section: Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to create meeting screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MeetingCreateScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14 * scale),
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cuộc Họp Mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (14 * scale).clamp(12.0, 16.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15 * scale),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to meeting list screen
                        setState(() {
                          _selectedIndex = 1; // Switch to meeting list tab
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kAccentColor,
                        padding: EdgeInsets.symmetric(vertical: 14 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cuộc Họp Gần Đây',
                        style: TextStyle(
                          fontSize: (14 * scale).clamp(12.0, 16.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardSection() {
    // Responsive scale
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        // Calculate real statistics from meetings
        final meetings = meetingProvider.meetings;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Today's meetings
        final todayMeetings = meetings.where((meeting) {
          final meetingDate = DateTime(
            meeting.startTime.year,
            meeting.startTime.month,
            meeting.startTime.day,
          );
          return meetingDate.isAtSameMomentAs(today);
        }).toList();

        // Upcoming meetings (next 7 days)
        final upcomingMeetings = meetings.where((meeting) {
          return meeting.startTime.isAfter(now) &&
              meeting.startTime.isBefore(now.add(const Duration(days: 7))) &&
              meeting.isApproved;
        }).toList();

        // Completed meetings
        final completedMeetings = meetings.where((meeting) {
          return meeting.isCompleted;
        }).toList();

        // Total participants (unique count from all meetings)
        final Set<String> uniqueParticipants = {};
        for (var meeting in meetings) {
          for (var participant in meeting.participants) {
            uniqueParticipants.add(participant.userId);
          }
        }

        final cardData = [
          {
            'icon': Icons.calendar_today_outlined,
            'title': 'Hôm nay',
            'value': todayMeetings.length.toString(),
            'subtitle': 'cuộc họp',
            'color': Colors.blue,
            'iconBackground': Colors.blue.withOpacity(0.1),
            'onTap': () => _navigateToTodayMeetings(),
          },
          {
            'icon': Icons.upcoming_outlined,
            'title': 'Sắp tới',
            'value': upcomingMeetings.length.toString(),
            'subtitle': 'cuộc họp',
            'color': Colors.orange,
            'iconBackground': Colors.orange.withOpacity(0.1),
            'onTap': () => _navigateToUpcomingMeetings(),
          },
          {
            'icon': Icons.check_circle_outline,
            'title': 'Hoàn thành',
            'value': completedMeetings.length.toString(),
            'subtitle': 'cuộc họp',
            'color': Colors.green,
            'iconBackground': Colors.green.withOpacity(0.1),
            'onTap': () => _navigateToCompletedMeetings(),
          },
          {
            'icon': Icons.people_outline,
            'title': 'Tổng tham gia',
            'value': uniqueParticipants.length.toString(),
            'subtitle': 'người',
            'color': Colors.purple,
            'iconBackground': Colors.purple.withOpacity(0.1),
            'onTap': () => _navigateToParticipantsAnalytics(),
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng quan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryLightColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month,
                          size: 16, color: kPrimaryColor),
                      SizedBox(width: 4),
                      Text(
                        'Tháng này',
                        style: TextStyle(
                          fontSize: 12,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (meetingProvider.isLoading)
              SizedBox(
                height: 160,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              SizedBox(
                height: (160 * scale).clamp(140.0, 180.0), // Responsive height
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cardData.length,
                  clipBehavior: Clip.none, // To prevent shadow clipping
                  itemBuilder: (context, index) {
                    final card = cardData[index];
                    // Calculate width to show ~3 items with responsive scaling
                    final cardWidth = (screenWidth / 3.5).clamp(95.0, 130.0);
                    final cardMargin = (12 * scale).clamp(8.0, 16.0);

                    return Container(
                      width: cardWidth,
                      // Add left margin for all cards except the first
                      margin: EdgeInsets.only(left: index == 0 ? 0 : cardMargin),
                      child: _DashboardCard(
                        icon: card['icon'] as IconData,
                        title: card['title'] as String,
                        value: card['value'] as String,
                        subtitle: card['subtitle'] as String,
                        color: card['color'] as Color,
                        iconBackground: card['iconBackground'] as Color,
                        onTap: card['onTap'] as VoidCallback,
                        scale: scale,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecentMeetingsSection() {
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cuộc họp gần đây',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF7B61FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Danh sách cuộc họp gần đây từ database
            if (meetingProvider.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (meetingProvider.meetings.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có cuộc họp nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meetingProvider.meetings.length > 3
                    ? 3
                    : meetingProvider.meetings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meeting = meetingProvider.meetings[index];
                  return _buildMeetingCard(meeting);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting) {
    final isCompleted = meeting.isCompleted;
    final isUpcoming = meeting.isUpcoming;
    final isOngoing = meeting.isOngoing;

    String statusText = 'Đã hoàn thành';
    if (isOngoing) {
      statusText = 'Đang diễn ra';
    } else if (isUpcoming) {
      statusText = 'Sắp diễn ra';
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? Colors.grey.shade200
              : kPrimaryLightColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _navigateToMeetingDetail(meeting.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey.shade100
                      : (isOngoing
                          ? Colors.green.withOpacity(0.1)
                          : kPrimaryColor.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : (isOngoing ? Icons.video_call : Icons.videocam),
                  color: isCompleted
                      ? Colors.grey
                      : (isOngoing ? Colors.green : kPrimaryColor),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Meeting info - use Expanded to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meeting.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.grey : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge inline with title
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey.withOpacity(0.1)
                                : (isOngoing
                                    ? Colors.green.withOpacity(0.1)
                                    : kPrimaryColor.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: isCompleted
                                  ? Colors.grey
                                  : (isOngoing ? Colors.green : kPrimaryColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Time row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)} • ${DateFormat('dd/MM').format(meeting.startTime)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location and participants row
                    Row(
                      children: [
                        Icon(
                          meeting.isVirtual
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            meeting.isVirtual
                                ? 'P...'
                                : (meeting.physicalLocation ?? 'P...'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.people_outline,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meeting.participantCount} người',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToTodayMeetings() {
    setState(() {
      _selectedIndex = 1; // Switch to meeting list tab
    });
    // Show snackbar to indicate filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hiển thị cuộc họp hôm nay'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToUpcomingMeetings() {
    setState(() {
      _selectedIndex = 1; // Switch to meeting list tab
    });
    // Show snackbar to indicate filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hiển thị cuộc họp sắp tới'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToCompletedMeetings() {
    setState(() {
      _selectedIndex = 1; // Switch to meeting list tab
    });
    // Show snackbar to indicate filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hiển thị cuộc họp đã hoàn thành'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToParticipantsAnalytics() {
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);
    final meetings = meetingProvider.meetings;

    // Calculate real statistics
    final Set<String> uniqueParticipants = {};
    int totalParticipants = 0;
    int confirmedParticipants = 0;

    for (var meeting in meetings) {
      for (var participant in meeting.participants) {
        uniqueParticipants.add(participant.userId);
        totalParticipants++;
        if (participant.hasConfirmed) {
          confirmedParticipants++;
        }
      }
    }

    final avgParticipants =
        meetings.isNotEmpty ? (totalParticipants / meetings.length).round() : 0;
    final confirmationRate = totalParticipants > 0
        ? ((confirmedParticipants / totalParticipants) * 100).round()
        : 0;

    // Show analytics dialog with real data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thống kê tham gia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Tổng số người tham gia: ${uniqueParticipants.length}'),
            const SizedBox(height: 8),
            Text('👥 Trung bình mỗi cuộc họp: $avgParticipants người'),
            const SizedBox(height: 8),
            Text('📈 Tổng số cuộc họp: ${meetings.length}'),
            const SizedBox(height: 8),
            Text('⭐ Tỷ lệ xác nhận: $confirmationRate%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to detailed analytics (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng thống kê chi tiết đang phát triển'),
                ),
              );
            },
            child: const Text('Xem chi tiết'),
          ),
        ],
      ),
    );
  }

  void _navigateToMeetingDetail(String meetingId) {
    // For demo, check if meeting detail screen exists
    try {
      Navigator.pushNamed(
        context,
        '/meeting-detail',
        arguments: meetingId,
      );
    } catch (e) {
      // Fallback if meeting detail screen not properly set up
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chi tiết cuộc họp'),
          content: Text('Đang mở chi tiết cuộc họp: $meetingId'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 1; // Switch to meeting list tab
                });
              },
              child: const Text('Xem danh sách'),
            ),
          ],
        ),
      );
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color iconBackground;
  final VoidCallback onTap;
  final double scale;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.iconBackground,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizes with clamp for min/max bounds
    final iconSize = (22 * scale).clamp(18.0, 26.0);
    final iconContainerSize = (40 * scale).clamp(32.0, 48.0);
    final valueFontSize = (26 * scale).clamp(20.0, 32.0);
    final titleFontSize = (13 * scale).clamp(11.0, 15.0);
    final subtitleFontSize = (11 * scale).clamp(9.0, 13.0);
    final padding = (12 * scale).clamp(8.0, 16.0);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
