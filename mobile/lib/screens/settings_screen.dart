import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/screens/settings_screen.dart';

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
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Thông tin cá nhân'),
            subtitle: Text(authProvider.userEmail ?? ''),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
          ),
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
            onTap: () async {
              try {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi đăng xuất: $e')),
                );
              }
            },
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
}
