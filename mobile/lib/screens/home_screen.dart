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
import 'setup_super_admin_screen.dart';
import 'package:metting_app/components/menu_item.dart';
import 'admin_dashboard_screen.dart';
import 'notification_screen.dart';
import 'package:metting_app/providers/notification_provider.dart';
import 'calendar_screen.dart';
import 'package:intl/intl.dart';

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

  void _loadNotifications() {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    print('🔄 Home: _loadNotifications called');
    print(
        '🔄 Home: AuthProvider user model is null: ${authProvider.userModel == null}');

    if (authProvider.userModel != null) {
      print(
          '🔄 Home: Loading notifications for user ${authProvider.userModel!.id}');
      print(
          '🔄 Home: User display name: ${authProvider.userModel!.displayName}');
      notificationProvider.loadNotifications(authProvider.userModel!.id);
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
      // Load meeting data
      meetingProvider.loadMeetings(authProvider.userModel!);

      // Load analytics data
      analyticsProvider.loadAnalytics();

      print('✅ Home: Started loading all data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ZoomDrawer(
      controller: zoomDrawerController,
      menuBackgroundColor: isDark ? colorScheme.surface : Colors.white,
      shadowLayer1Color:
          isDark ? colorScheme.surfaceVariant : const Color(0xFFF5F5F5),
      shadowLayer2Color: isDark
          ? colorScheme.surfaceVariant.withOpacity(0.7)
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
              Expanded(
                child: Consumer<app_auth.AuthProvider>(
                  builder: (context, authProvider, child) {
                    final userModel = authProvider.userModel;
                    final isAdmin = userModel?.isAdmin == true;
                    final isDirector = userModel?.isDirector == true;

                    return Column(
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
                        // Chỉ hiển thị cho Admin và Director
                        if (isAdmin || isDirector) ...[
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              color: colorScheme.outline.withOpacity(0.2),
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          MenuItem(
                            title: 'Quản lý hệ thống',
                            icon: Icons.admin_panel_settings_outlined,
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
                        const Spacer(),
                        MenuItem(
                          title: 'Giới Thiệu',
                          icon: Icons.info_rounded,
                          isSelected: false,
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Meeting App',
                              applicationVersion: '1.0.0',
                              applicationIcon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  IconlyBold.video,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              children: [
                                const Text(
                                  'Ứng dụng quản lý cuộc họp hiện đại với giao diện đẹp và tính năng đầy đủ.',
                                ),
                              ],
                            );
                            zoomDrawerController.close?.call();
                          },
                        ),
                      ],
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
      FutureBuilder<Map<String, dynamic>?>(
        future: authProvider.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: \\${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Text('Không tìm thấy dữ liệu người dùng.'));
          }
          final userData = snapshot.data!;
          final displayName = userData['displayName'] as String?;
          return _buildMainContent(displayName ?? 'Người dùng');
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
            child: Icon(
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chào mừng và nút tạo cuộc họp
            _buildUpcomingMeetingCard(displayName),
            const SizedBox(height: 24),
            // 4 ô dashboard có thể lướt ngang
            _buildDashboardSection(),
            const SizedBox(height: 24),
            // Phần cuộc họp gần đây
            _buildRecentMeetingsSection(),
          ],
        ),
      ),
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

        return Container(
          padding: const EdgeInsets.all(20),
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
                    radius: 30,
                    backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?u=${userModel?.email ?? 'default'}'),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actualDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          departmentAndRole,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam_outlined,
                      color: kAccentColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(color: Colors.white24),
              const SizedBox(height: 15),

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
              const SizedBox(height: 20),

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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cuộc Họp Mới',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cuộc Họp Gần Đây'),
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
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        // Calculate real statistics from meetings
        final meetings = meetingProvider.meetings;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

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
              Container(
                height: 160,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              SizedBox(
                height: 160, // Adjusted height
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cardData.length,
                  clipBehavior: Clip.none, // To prevent shadow clipping
                  itemBuilder: (context, index) {
                    final card = cardData[index];
                    // Calculate width to show ~3 items
                    final screenWidth = MediaQuery.of(context).size.width;
                    final cardWidth = screenWidth / 3.5;

                    return Container(
                      width: cardWidth,
                      // Add left margin for all cards except the first
                      margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
                      child: _DashboardCard(
                        icon: card['icon'] as IconData,
                        title: card['title'] as String,
                        value: card['value'] as String,
                        subtitle: card['subtitle'] as String,
                        color: card['color'] as Color,
                        iconBackground: card['iconBackground'] as Color,
                        onTap: card['onTap'] as VoidCallback,
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meetingProvider.meetings.length > 3
                    ? 3
                    : meetingProvider.meetings.length,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
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
            // Navigate to meeting detail screen
            _navigateToMeetingDetail(meeting.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Meeting info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.grey : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)} • ${DateFormat('dd/MM').format(meeting.startTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            meeting.isVirtual
                                ? Icons.video_call_outlined
                                : Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meeting.isVirtual
                                  ? 'Trực tuyến'
                                  : (meeting.physicalLocation ??
                                      'Chưa có địa điểm'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${meeting.participantCount} người',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicator
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOngoing
                          ? Colors.green.withOpacity(0.1)
                          : kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOngoing ? Colors.green : kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
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

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
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
                      fontSize: 26,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
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
