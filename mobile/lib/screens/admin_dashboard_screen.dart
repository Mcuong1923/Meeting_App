import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/constants.dart';
import 'package:iconly/iconly.dart';
import 'role_management_screen.dart';
import 'setup_super_admin_screen.dart';
import 'room_management_screen.dart';
import 'room_setup_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final userModel = authProvider.userModel;
    final isAdmin = userModel?.isAdmin == true;
    final isDirector = userModel?.isDirector == true;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý hệ thống',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kAccentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Quản trị viên' : 'Giám đốc',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quản lý và điều hành hệ thống',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quản lý người dùng và vai trò
            _buildSectionTitle('Quản lý người dùng'),
            const SizedBox(height: 12),
            if (isAdmin || isDirector) ...[
              _buildFeatureCard(
                context,
                title: 'Quản lý vai trò',
                subtitle: 'Phân quyền và quản lý vai trò người dùng',
                icon: Icons.admin_panel_settings,
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (isAdmin) ...[
              _buildFeatureCard(
                context,
                title: 'Phê duyệt vai trò',
                subtitle: 'Duyệt yêu cầu thay đổi vai trò',
                icon: Icons.approval,
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/role-approval');
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                title: 'Thiết lập Admin',
                subtitle: 'Cấu hình và quản lý tài khoản Admin',
                icon: Icons.settings,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetupSuperAdminScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quản lý phòng họp
              _buildSectionTitle('Quản lý phòng họp'),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                title: 'Quản lý phòng họp',
                subtitle: 'Quản lý phòng, tiện ích và bảo trì',
                icon: Icons.meeting_room,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoomManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                title: 'Setup phòng họp',
                subtitle: 'Cấu hình và tạo phòng mặc định',
                icon: Icons.auto_fix_high,
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoomSetupScreen(),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Thống kê và báo cáo
            _buildSectionTitle('Thống kê và báo cáo'),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              title: 'Thống kê sử dụng',
              subtitle: 'Xem báo cáo và thống kê hệ thống',
              icon: Icons.analytics,
              color: Colors.blue,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              title: 'Nhật ký hoạt động',
              subtitle: 'Theo dõi hoạt động của người dùng',
              icon: Icons.history,
              color: Colors.teal,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
