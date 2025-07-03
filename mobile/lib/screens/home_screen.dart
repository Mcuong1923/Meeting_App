import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/screens/login_screen.dart';
import 'package:metting_app/constants.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:hugeicons/hugeicons.dart';
import 'meeting_list_screen.dart';
import 'room_management_screen.dart';
import 'meeting_create_screen.dart';
import 'settings_screen.dart';
import 'package:metting_app/components/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    final List<String> titles = [
      'Trang Chủ',
      'Cuộc Họp',
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
      const RoomManagementScreen(),
      const SettingsScreen(),
    ];

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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: kPrimaryColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Thông báo'),
                  content: const Text('Chưa có thông báo mới.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: kPrimaryColor),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                // TODO: Hiện giao diện cập nhật hồ sơ
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('Cập nhật hồ sơ'),
                    content: Text('Chức năng cập nhật hồ sơ sẽ được bổ sung.'),
                  ),
                );
              } else if (value == 'password') {
                // TODO: Hiện giao diện đổi mật khẩu
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('Đổi mật khẩu'),
                    content: Text('Chức năng đổi mật khẩu sẽ được bổ sung.'),
                  ),
                );
              } else if (value == 'language') {
                // TODO: Hiện giao diện đổi ngôn ngữ
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('Đổi ngôn ngữ'),
                    content: Text('Chức năng đổi ngôn ngữ sẽ được bổ sung.'),
                  ),
                );
              } else if (value == 'logout') {
                try {
                  await authProvider.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
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
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: kPrimaryColor),
                  title: const Text('Cập nhật hồ sơ'),
                ),
              ),
              PopupMenuItem(
                value: 'password',
                child: ListTile(
                  leading: Icon(Icons.lock, color: kPrimaryColor),
                  title: const Text('Đổi mật khẩu'),
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: ListTile(
                  leading: Icon(Icons.language, color: kPrimaryColor),
                  title: const Text('Đổi ngôn ngữ'),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: kPrimaryColor),
                  title: const Text('Đăng xuất'),
                ),
              ),
            ],
            color: const Color(0xFFF6F1FF),
          ),
        ],
      ),
      body: body[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        icons: [
          Icons.home_rounded,
          _selectedIndex == 1
              ? Icons.videocam_rounded
              : Icons.videocam_outlined,
          _selectedIndex == 2
              ? Icons.business_rounded
              : Icons.business_outlined,
          Icons.settings_rounded,
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

  Widget _buildUpcomingMeetingCard(String displayName) {
    // This is the new card based on the user's image.
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
          // Top section: Doctor info and video call icon
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?u=a042581f4e29026704d'), // Placeholder image
              ),
              const SizedBox(width: 15),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mạnh Cường',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Phenikaa',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 2),
                      Text('18 Nov, Monday',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time_filled_outlined,
                      color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 2),
                      Text('8pm - 8:30 pm',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
                  onPressed: () {},
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
                  onPressed: () {},
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
  }

  Widget _buildDashboardSection() {
    final cardData = [
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Hôm nay',
        'value': '2',
        'subtitle': 'cuộc họp',
        'color': Colors.blue,
        'iconBackground': Colors.blue.withOpacity(0.1),
      },
      {
        'icon': Icons.upcoming_outlined,
        'title': 'Sắp tới',
        'value': '5',
        'subtitle': 'cuộc họp',
        'color': Colors.orange,
        'iconBackground': Colors.orange.withOpacity(0.1),
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'Hoàn thành',
        'value': '12',
        'subtitle': 'cuộc họp',
        'color': Colors.green,
        'iconBackground': Colors.green.withOpacity(0.1),
      },
      {
        'icon': Icons.people_outline,
        'title': 'Tổng tham gia',
        'value': '48',
        'subtitle': 'người',
        'color': Colors.purple,
        'iconBackground': Colors.purple.withOpacity(0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryLightColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 16, color: kPrimaryColor),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMeetingsSection() {
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
                  color: const Color(0xFF7B61FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Danh sách cuộc họp gần đây
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3, // Hiển thị 3 cuộc họp gần nhất
          itemBuilder: (context, index) {
            return _buildMeetingCard(index);
          },
        ),
      ],
    );
  }

  Widget _buildMeetingCard(int index) {
    // Data mẫu cho cuộc họp
    final meetings = [
      {
        'title': 'Họp team phát triển',
        'time': '09:00 - 10:00',
        'date': 'Hôm nay',
        'room': 'Phòng họp A',
        'participants': 8,
        'status': 'upcoming',
      },
      {
        'title': 'Review dự án Q4',
        'time': '14:00 - 15:30',
        'date': 'Hôm nay',
        'room': 'Phòng họp B',
        'participants': 12,
        'status': 'upcoming',
      },
      {
        'title': 'Họp khách hàng ABC',
        'time': '10:00 - 11:00',
        'date': 'Hôm qua',
        'room': 'Phòng họp VIP',
        'participants': 5,
        'status': 'completed',
      },
    ];

    if (index >= meetings.length) return const SizedBox();

    final meeting = meetings[index];
    final isCompleted = meeting['status'] == 'completed';

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
            // TODO: Xem chi tiết cuộc họp
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
                        : kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.videocam,
                    color: isCompleted ? Colors.grey : kPrimaryColor,
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
                        meeting['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.grey : Colors.black87,
                        ),
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
                            '${meeting['time']} • ${meeting['date']}',
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
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meeting['room'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
                            '${meeting['participants']} người',
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
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Sắp diễn ra',
                      style: TextStyle(
                        fontSize: 12,
                        color: kPrimaryColor,
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
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color iconBackground;
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.iconBackground,
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
        onTap: () {}, // TODO: Thêm chức năng khi nhấn nếu cần
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
