import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/constants.dart';
import 'package:iconly/iconly.dart';
import 'role_management_screen.dart';

import 'room_management_screen.dart';
import 'room_setup_screen.dart';
import 'role_approval_screen.dart';

import 'meeting_approval_list_screen.dart';
import 'all_tasks_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final userModel = authProvider.userModel;
    final isAdmin = userModel?.isAdmin == true;
    final isDirector = userModel?.isDirector == true;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý hệ thống',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'Cấu hình và quản trị',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
            size: 20, 
            color: Color(0xFF1A1A1A)
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin || isDirector) ...[
              _buildSectionTitle('Quản lý người dùng'),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                title: 'Quản lý vai trò',
                subtitle: 'Phân quyền và quản lý vai trò người dùng',
                icon: Icons.badge_outlined,
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
                icon: Icons.verified_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleApprovalScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Quản lý cuộc họp'),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                title: 'Phê duyệt cuộc họp',
                subtitle: 'Duyệt yêu cầu tạo cuộc họp',
                icon: Icons.approval_outlined, // Or check_circle_outline
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeetingApprovalListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Quản lý phòng họp'),
              const SizedBox(height: 12),
              
              _buildFeatureCard(
                context,
                title: 'Quản lý phòng họp',
                subtitle: 'Quản lý phòng, tiện ích và bảo trì',
                icon: Icons.meeting_room_outlined,
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
                icon: Icons.settings_suggest_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoomSetupScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Quản lý công việc'),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                title: 'Quản lý công việc',
                subtitle: 'Theo dõi và quản lý công việc',
                icon: Icons.task_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTasksScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Thống kê và báo cáo'),
              const SizedBox(height: 12),
              
              _buildFeatureCard(
                context,
                title: 'Thống kê sử dụng',
                subtitle: 'Xem báo cáo và thống kê hệ thống',
                icon: Icons.analytics_outlined, // Changed to outlined
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
                icon: Icons.history_outlined, // Changed to outlined/simulated
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chức năng đang phát triển')),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // Determine color based on app theme or fixed color
    // Keeping it simple and consistent as requested
    final iconColor = const Color(0xFF57636C); 

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
