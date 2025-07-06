import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/screens/room_management_screen.dart';
import 'package:metting_app/screens/room_setup_screen.dart';
import 'package:metting_app/screens/welcome/welcome_screen.dart';
import 'package:metting_app/screens/role_approval_screen.dart';
import 'package:metting_app/models/user_role.dart';
import 'package:metting_app/models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _pushNotification = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        children: [
          const SizedBox(height: 24),
          _buildSectionTitle('Tài khoản'),
          _buildUserInfoCard(authProvider),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle('Thông báo'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none_outlined),
            title: const Text('Push Notification'),
            value: _pushNotification,
            onChanged: (val) {
              setState(() => _pushNotification = val);
            },
          ),
          const Divider(),
          _buildSectionTitle('Giao diện'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Chế độ tối'),
            value: _isDarkMode,
            onChanged: (val) {
              setState(() => _isDarkMode = val);
              // TODO: Gọi ThemeProvider nếu có
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Ngôn ngữ'),
            subtitle: const Text('Tiếng Việt'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle('Quản trị'),
          if (authProvider.userModel?.isAdmin == true) ...[
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Colors.purple),
              title: const Text('Quản lý phòng họp',
                  style: TextStyle(color: Colors.purple)),
              subtitle: const Text('Quản lý phòng, tiện ích và bảo trì'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoomManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: Colors.indigo),
                title: const Text('Setup phòng họp',
                  style: TextStyle(color: Colors.indigo)),
              subtitle: const Text('Cấu hình và tạo phòng mặc định'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoomSetupScreen(),
                  ),
                );
              },
            ),
          ] else if (authProvider.userModel?.isDirector == true) ...[
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.blue),
              title: const Text('Quản lý vai trò',
                  style: TextStyle(color: Colors.blue)),
              subtitle:
                  const Text('Phê duyệt và quản lý nhân viên trong phòng ban'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleApprovalScreen(),
                  ),
                );
              },
            ),
          ],
          const Divider(),
          _buildSectionTitle('Khác'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Thông tin ứng dụng'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationIcon: const FlutterLogo(),
                applicationName: 'Meeting App',
                applicationVersion: '1.0.0',
                children: const [
                  Text('Ứng dụng đặt và quản lý cuộc họp.\n© 2024 Phenikaa.'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmLogout(authProvider),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(app_auth.AuthProvider authProvider) {
    final userModel = authProvider.userModel;

    // Xác định vai trò hiển thị
    String displayRole;
    String displayDepartment;
    Color roleColor;
    IconData roleIcon;

    if (userModel?.isRoleApproved == true) {
      // Nếu đã được duyệt, hiển thị vai trò thực tế
      displayRole = _getRoleDisplayName(userModel!.role);
      displayDepartment = _getDepartmentDisplayName(userModel);
      roleColor = _getRoleColor(userModel.role);
      roleIcon = _getRoleIcon(userModel.role);
    } else {
      // Nếu chưa được duyệt, hiển thị Guest
      displayRole = 'Guest';
      displayDepartment = 'Chưa xác định';
      roleColor = Colors.grey;
      roleIcon = Icons.person_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với avatar và tên
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: roleColor.withOpacity(0.1),
                child: Icon(
                  roleIcon,
                  color: roleColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel?.displayName ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.userEmail ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thông tin vai trò và phòng ban
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.work_outline,
                  label: 'Vai trò',
                  value: displayRole,
                  valueColor: roleColor,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.business_outlined,
                  label: 'Phòng ban',
                  value: displayDepartment,
                  valueColor: Colors.black87,
                ),
                // Hiển thị thông tin pending nếu có
                if (userModel?.pendingRole != null ||
                    userModel?.pendingDepartment != null) ...[
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pending_outlined,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Đang chờ duyệt:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (userModel?.pendingRole != null)
                          _buildInfoRow(
                            icon: Icons.work_outline,
                            label: 'Vai trò mới',
                            value: _getRoleDisplayName(userModel!.pendingRole!),
                            valueColor: Colors.orange[700]!,
                            fontSize: 12,
                          ),
                        if (userModel?.pendingDepartment != null)
                          _buildInfoRow(
                            icon: Icons.business_outlined,
                            label: 'Phòng ban mới',
                            value: _mapDepartmentIdToDisplayName(
                                userModel!.pendingDepartment!),
                            valueColor: Colors.orange[700]!,
                            fontSize: 12,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nút chỉnh sửa
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Chỉnh sửa thông tin'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    double fontSize = 14,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(UserRole role) {
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
        return 'Không xác định';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.director:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.employee:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.director:
        return Icons.business_center;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.employee:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
      default:
        return Icons.person_outline;
    }
  }

  String _getDepartmentDisplayName(UserModel userModel) {
    // Ưu tiên departmentName nếu có
    if (userModel.departmentName != null &&
        userModel.departmentName!.isNotEmpty) {
      return userModel.departmentName!;
    }

    // Fallback: Map departmentId thành tên hiển thị
    if (userModel.departmentId != null) {
      const departmentMap = {
        'Công nghệ thông tin': 'Công nghệ thông tin',
        'Nhân sự': 'Nhân sự',
        'Marketing': 'Marketing',
        'Kế toán': 'Kế toán',
        'Kinh doanh': 'Kinh doanh',
        'Vận hành': 'Vận hành',
        'Khác': 'Khác',
        'SYSTEM': 'Hệ thống',
        'CNTT': 'Công nghệ thông tin',
        'HR': 'Nhân sự',
        'MARKETING': 'Marketing',
        'ACCOUNTING': 'Kế toán',
        'BUSINESS': 'Kinh doanh',
        'OPERATIONS': 'Vận hành',
      };

      return departmentMap[userModel.departmentId] ?? userModel.departmentId!;
    }

    return 'Chưa xác định';
  }

  String _mapDepartmentIdToDisplayName(String departmentId) {
    const departmentMap = {
      'Công nghệ thông tin': 'Công nghệ thông tin',
      'Nhân sự': 'Nhân sự',
      'Marketing': 'Marketing',
      'Kế toán': 'Kế toán',
      'Kinh doanh': 'Kinh doanh',
      'Vận hành': 'Vận hành',
      'Khác': 'Khác',
      'SYSTEM': 'Hệ thống',
      'CNTT': 'Công nghệ thông tin',
      'HR': 'Nhân sự',
      'MARKETING': 'Marketing',
      'ACCOUNTING': 'Kế toán',
      'BUSINESS': 'Kinh doanh',
      'OPERATIONS': 'Vận hành',
    };

    return departmentMap[departmentId] ?? departmentId;
  }

  // Xác nhận đăng xuất
  Future<void> _confirmLogout(app_auth.AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Hiển thị loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await authProvider.logout();

        if (!mounted) return;

        // Đóng loading dialog
        Navigator.of(context).pop();

        // Navigate về welcome screen và clear toàn bộ stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;

        // Đóng loading dialog nếu có lỗi
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
