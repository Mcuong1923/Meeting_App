import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/providers/theme_provider.dart';
import 'package:metting_app/components/color_picker_dialog.dart';
import 'package:metting_app/screens/room_management_screen.dart';
import 'package:metting_app/screens/room_setup_screen.dart';
import 'package:metting_app/screens/welcome/welcome_screen.dart';
import 'package:metting_app/screens/role_approval_screen.dart';
import 'package:metting_app/screens/edit_profile_screen.dart';
import 'package:metting_app/models/user_role.dart';
import 'package:metting_app/models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotification = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF000000)
          : const Color(0xFFF8F9FA), // Lighter background
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ACCOUNT Section
          _buildSectionHeader('Tài Khoản'),
          const SizedBox(height: 12),
          _buildCompactAccountRow(authProvider),
          
          const SizedBox(height: 24),
          // SETTINGS Section
          _buildSectionHeader('Cài đặt hệ thống'),
          const SizedBox(height: 12),

          // Ngôn ngữ
          _buildSettingItem(
            icon: Icons.language,
            iconColor: const Color(0xFF3B82F6),
            iconBgColor: const Color(0xFFDBEAFE),
            title: 'Ngôn Ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng đang phát triển')),
            ),
          ),
          const SizedBox(height: 12),

          // Màu Chủ Đề
          _buildSettingItem(
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: const Color(0xFFEDE9FE),
            title: 'Màu Chủ Đề',
            subtitle: 'Tùy chỉnh màu sắc ứng dụng',
            onTap: () => _showColorPicker(context, themeProvider),
          ),
          const SizedBox(height: 12),

          // Thông báo
          _buildToggleItem(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBgColor: const Color(0xFFFEF3C7),
            title: 'Thông báo',
            subtitle: 'Nhận thông báo về cuộc họp',
            value: _pushNotification,
            onChanged: (value) => setState(() => _pushNotification = value),
          ),
          const SizedBox(height: 12),

          // Quản trị (chỉ hiện với admin/director)
          if (authProvider.userModel?.isAdmin == true) ...[
            _buildSettingItem(
              icon: Icons.meeting_room_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFD1FAE5),
              title: 'Quản lý phòng họp',
              subtitle: 'Thiết lập tiện ích & bảo trì',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WillPopScope(
                      onWillPop: () async {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/home', (route) => false);
                        return false;
                      },
                      child: const RoomManagementScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.auto_fix_high_rounded,
              iconColor: const Color(0xFF6366F1),
              iconBgColor: const Color(0xFFE0E7FF),
              title: 'Setup phòng họp',
              subtitle: 'Cấu hình và tạo phòng mặc định',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WillPopScope(
                      onWillPop: () async {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/home', (route) => false);
                        return false;
                      },
                      child: const RoomSetupScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          if (authProvider.userModel?.isDirector == true &&
              authProvider.userModel?.isAdmin != true) ...[
            _buildSettingItem(
              icon: Icons.manage_accounts_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBgColor: const Color(0xFFDBEAFE),
              title: 'Quản lý vai trò',
              subtitle: 'Phê duyệt và quản lý nhân tài khoản',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WillPopScope(
                      onWillPop: () async {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/home', (route) => false);
                        return false;
                      },
                      child: const RoleApprovalScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // Đổi mật khẩu -> Bảo mật
          _buildSettingItem(
            icon: Icons.security_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBgColor: const Color(0xFFFEE2E2),
            title: 'Bảo mật',
            subtitle: 'Mật khẩu và xác thực 2 lớp',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng đang phát triển')),
            ),
          ),
          const SizedBox(height: 12),

          // Thông tin ứng dụng
          _buildSettingItem(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF6B7280),
            iconBgColor: const Color(0xFFF3F4F6),
            title: 'Thông tin ứng dụng',
            subtitle: 'Phiên bản và thông tin chi tiết',
            onTap: () => _showAppInfo(),
          ),
          const SizedBox(height: 12),

          // Đăng xuất
          _buildSettingItem(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBgColor: const Color(0xFFFEE2E2),
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản hiện tại',
            onTap: () => _confirmLogout(authProvider),
            isDestructive: true,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.isDarkMode ? Colors.white10 : const Color(0xFFF3F4F6),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? iconColor.withOpacity(0.2) : iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDestructive
                    ? const Color(0xFFEF4444)
                    : (themeProvider.isDarkMode
                        ? Colors.white
                        : const Color(0xFF111827)),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : const Color(0xFF6B7280),
              ),
            ),
            trailing: !isDestructive
                ? Icon(
                    Icons.chevron_right_rounded,
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : const Color(0xFF9CA3AF),
                    size: 22,
                  )
                : null,
            onTap: onTap,
          ),
        );
      },
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.isDarkMode ? Colors.white10 : const Color(0xFFF3F4F6),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? iconColor.withOpacity(0.2) : iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : const Color(0xFF6B7280),
              ),
            ),
            trailing: Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF3B82F6),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: themeProvider.isDarkMode
                    ? const Color(0xFF39393D)
                    : const Color(0xFFE5E7EB),
                trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactAccountRow(app_auth.AuthProvider authProvider) {
    final userModel = authProvider.userModel;
    final themeProvider = Provider.of<ThemeProvider>(context);

    String displayRole;
    String displayDepartment;

    if (userModel?.isRoleApproved == true) {
      displayRole = _getRoleDisplayName(userModel!.role);
      displayDepartment = _getDepartmentDisplayName(userModel);
    } else {
      displayRole = 'Guest';
      displayDepartment = 'Chưa xác định';
    }

    final subtitle = '$displayRole • $displayDepartment';

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.isDarkMode ? Colors.white10 : const Color(0xFFF3F4F6),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF60A5FA).withOpacity(0.5),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=${authProvider.userEmail ?? 'default'}',
                ),
                backgroundColor: const Color(0xFFE0E7FF),
              ),
            ),
            if (_shouldShowApprovalBadge(userModel))
              Positioned(
                bottom: -4,
                right: -4,
                child: _buildApprovalBadge(userModel),
              ),
          ],
        ),
        title: Text(
          userModel?.displayName ?? 'Người dùng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: themeProvider.isDarkMode
                  ? Colors.white70
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: themeProvider.isDarkMode ? Colors.white70 : const Color(0xFF9CA3AF),
          size: 24,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  bool _shouldShowApprovalBadge(UserModel? userModel) {
    if (userModel == null) return false;
    return userModel.isRoleApproved == true || userModel.role == UserRole.admin;
  }

  Widget _buildApprovalBadge(UserModel? userModel) {
    if (userModel == null) return const SizedBox.shrink();

    Color badgeColor;
    if (userModel.role == UserRole.admin || userModel.isRoleApproved == true) {
      badgeColor = const Color(0xFFF59E0B); // Amber/Gold for tick
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.check,
        size: 12,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white60 : const Color(0xFF9CA3AF),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }


  Widget _buildInitialsAvatar(String name, ColorScheme colorScheme) {
    final initials = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        currentColor: themeProvider.primaryColor,
        onColorSelected: (color) {
          themeProvider.setPrimaryColor(color);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã cập nhật màu chủ đề!'),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF2E7BE9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.meeting_room, color: Colors.white, size: 32),
      ),
      applicationName: 'Meeting App',
      applicationVersion: '1.0.0',
      children: const [
        Text('Ứng dụng đặt và quản lý cuộc họp.\n© 2024 Phenikaa.'),
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
