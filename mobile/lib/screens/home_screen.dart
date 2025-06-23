import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/screens/login_screen.dart';
import 'package:metting_app/constants.dart';
import 'meeting_list_screen.dart';

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
  Widget _navIcon(IconData icon, int index) {
    final selected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDCEEFF) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black87, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    // Danh sách tiêu đề theo tab
    final List<String> titles = [
      'Trang Chủ',
      'Cuộc Họp',
      'Phòng Họp',
      'Cài Đặt'
    ];

    return Scaffold(
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
        backgroundColor: const Color(0xFFA6A6FA),
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
      body: _selectedIndex == 1
          ? const MeetingListScreen()
          : _selectedIndex == 2
              ? const Center(
                  child: Text('Phòng họp', style: TextStyle(fontSize: 20)))
              : _selectedIndex == 3
                  ? const Center(
                      child: Text('Cài đặt', style: TextStyle(fontSize: 20)))
                  : FutureBuilder<Map<String, dynamic>?>(
                      future: authProvider.getUserData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child:
                                  Text('Đã xảy ra lỗi: \\${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                              child:
                                  Text('Không tìm thấy dữ liệu người dùng.'));
                        }
                        final userData = snapshot.data!;
                        final displayName = userData['displayName'] as String?;
                        return _buildMainContent(displayName ?? 'Người dùng');
                      },
                    ),
      bottomNavigationBar: Container(
  margin: const EdgeInsets.all(12),        // khoảng cách với mép màn hình
  decoration: BoxDecoration(
    color: const Color(0xFFE9EBF2),        // nền xám rất nhạt
    borderRadius: BorderRadius.circular(24),
  ),
  child: BottomNavigationBar(
    backgroundColor: Colors.transparent,   // để hiển thị màu Container
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    currentIndex: _selectedIndex,
    onTap: _onItemTapped,
    selectedItemColor: Colors.black87,
    unselectedItemColor: Colors.black54,
    showUnselectedLabels: true,
    selectedFontSize: 12,
    unselectedFontSize: 12,
    items: [
      BottomNavigationBarItem(
              icon: _navIcon(Icons.home_rounded, 0),      // icon có vòng tròn khi chọn
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(Icons.meeting_room_outlined, 1),
              label: 'Cuộc họp',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(Icons.apartment_rounded, 2),
              label: 'Phòng họp',
            ),
            BottomNavigationBarItem(
              icon: _navIcon(Icons.settings_rounded, 3),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(String displayName) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        color: kBackgroundPink,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chào mừng và nút tạo cuộc họp
              Card(
                elevation: 2,
                color: kPrimaryLightColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào mừng trở lại, $displayName! 👋',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                          'Hãy bắt đầu ngày mới với việc quản lý cuộc họp hiệu quả',
                          style: TextStyle(color: kPrimaryColor)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                splashColor: kPrimaryColor.withOpacity(0.2),
                                highlightColor: kPrimaryColor.withOpacity(0.1),
                                onTap: () {},
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text('Tạo cuộc họp mới',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                splashColor: kPrimaryColor.withOpacity(0.2),
                                highlightColor: kPrimaryColor.withOpacity(0.1),
                                onTap: () {},
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.list_alt,
                                      color: kPrimaryColor),
                                  label: const Text('Xem tất cả cuộc họp',
                                      style: TextStyle(color: kPrimaryColor)),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    side:
                                        const BorderSide(color: kPrimaryColor),
                                    foregroundColor: kPrimaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 4 ô dashboard
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  _DashboardCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'CUỘC HỌP HÔM NAY',
                    value: '0',
                    color: kPrimaryColor,
                  ),
                  _DashboardCard(
                    icon: Icons.access_time,
                    title: 'CUỘC HỌP SẮP TỚI',
                    value: '0',
                    color: kPrimaryColor,
                  ),
                  _DashboardCard(
                    icon: Icons.check_circle,
                    title: 'ĐÃ HOÀN THÀNH',
                    value: '1',
                    color: kPrimaryColor,
                  ),
                  _DashboardCard(
                    icon: Icons.group,
                    title: 'TỔNG THAM GIA',
                    value: '1',
                    color: kPrimaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                color: kPrimaryLightColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Cuộc họp gần đây',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: const [
                            Icon(Icons.calendar_today_outlined,
                                size: 64, color: Colors.black26),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có cuộc họp nào.',
                              style: TextStyle(
                                color: Colors.black38,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hãy tạo cuộc họp đầu tiên của bạn!',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
  final Color color;
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    double iconSize = icon == Icons.access_time ? 40 : 36;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: kPrimaryColor.withOpacity(0.15),
        highlightColor: kPrimaryColor.withOpacity(0.07),
        onTap: () {}, // TODO: Thêm chức năng khi nhấn nếu cần
        child: Card(
          elevation: 3,
          color: kPrimaryLightColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: color),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
