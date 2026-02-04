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
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ACCOUNT Section
          _buildSectionHeader('Account'),
          const SizedBox(height: 8),
          _buildCompactAccountRow(authProvider),
          
          // SETTINGS Section
          _buildSectionHeader('Settings'),
          const SizedBox(height: 8),

          // Ngôn ngữ
          _buildSettingItem(
            icon: Icons.language,
            iconColor: const Color(0xFF4A90E2),
            title: 'Ngôn Ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng đang phát triển')),
            ),
          ),
          const SizedBox(height: 12),

          // Màu Chủ Đề
          _buildSettingItem(
            icon: Icons.palette_outlined,
            iconColor: themeProvider.primaryColor,
            title: 'Màu Chủ Đề',
            subtitle: 'Tùy chỉnh màu sắc ứng dụng',
            onTap: () => _showColorPicker(context, themeProvider),
          ),
          const SizedBox(height: 12),

          // Thông báo
          _buildToggleItem(
            icon: Icons.notifications_outlined,
            iconColor: themeProvider.primaryColor,
            title: 'Thông báo',
            subtitle: 'Nhận thông báo về cuộc họp',
            value: _pushNotification,
            onChanged: (value) => setState(() => _pushNotification = value),
          ),
          const SizedBox(height: 12),

          // Quản trị (chỉ hiện với admin/director)
          if (authProvider.userModel?.isAdmin == true) ...[
            _buildSettingItem(
              icon: Icons.meeting_room,
              iconColor: Colors.purple,
              title: 'Quản lý phòng họp',
              subtitle: 'Quản lý phòng, tiện ích và bảo trì',
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
              icon: Icons.auto_fix_high,
              iconColor: Colors.indigo,
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
              icon: Icons.manage_accounts,
              iconColor: Colors.blue,
              title: 'Quản lý vai trò',
              subtitle: 'Phê duyệt và quản lý nhân viên trong phòng ban',
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

          // Đổi mật khẩu
          _buildSettingItem(
            icon: Icons.security_outlined,
            iconColor: const Color(0xFF8E8E93),
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu tài khoản',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng đang phát triển')),
            ),
          ),
          const SizedBox(height: 12),

          // Thông tin ứng dụng
          _buildSettingItem(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF8E8E93),
            title: 'Thông tin ứng dụng',
            subtitle: 'Phiên bản và thông tin chi tiết',
            onTap: () => _showAppInfo(),
          ),
          const SizedBox(height: 12),

          // Đăng xuất
          _buildSettingItem(
            icon: Icons.logout,
            iconColor: Colors.red,
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive
                    ? Colors.red
                    : (themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : const Color(0xFF8E8E93),
              ),
            ),
            trailing: !isDestructive
                ? Icon(
                    Icons.chevron_right,
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : const Color(0xFF8E8E93),
                    size: 20,
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : const Color(0xFF8E8E93),
              ),
            ),
            trailing: Transform.scale(
              scale: 0.9,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: themeProvider.primaryColor,
                activeTrackColor: themeProvider.primaryColor.withOpacity(0.3),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: themeProvider.isDarkMode
                    ? const Color(0xFF39393D)
                    : const Color(0xFFE0E0E0),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine display values
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=${authProvider.userEmail ?? 'default'}',
              ),
              backgroundColor: colorScheme.primaryContainer,
            ),
            // Approval badge overlay (bottom-right)
            if (_shouldShowApprovalBadge(userModel))
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildApprovalBadge(userModel),
              ),
          ],
        ),
        title: Text(
          userModel?.displayName ?? 'Người dùng',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
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
    // Show badge for approved users or global admins
    return userModel.isRoleApproved == true || userModel.role == UserRole.admin;
  }

  Widget _buildApprovalBadge(UserModel? userModel) {
    if (userModel == null) return const SizedBox.shrink();

    Color badgeColor;
    IconData iconData = Icons.check_circle;

    // Gold tick for Global Admin
    if (userModel.role == UserRole.admin) {
      badgeColor = Colors.amber;
    }
    // Green tick for approved users
    else if (userModel.isRoleApproved == true) {
      badgeColor = Colors.green;
    }
    // No badge for pending/unapproved
    else {
      return const SizedBox.shrink();
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(
        iconData,
        size: 14,
        color: badgeColor,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
