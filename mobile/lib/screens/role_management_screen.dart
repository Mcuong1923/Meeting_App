import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final users = await authProvider.getAllUsers();

      if (mounted) {
        setState(() {
          _users = users ?? []; // Đảm bảo không null
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _users = []; // Reset về mảng rỗng
          _isLoading = false;
          _errorMessage = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách người dùng: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadUsers,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý vai trò'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Hiển thị lỗi nếu có
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Hiển thị danh sách rỗng
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có người dùng nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hoặc bạn không có quyền truy cập danh sách người dùng.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    // Hiển thị danh sách người dùng
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          // Kiểm tra index hợp lệ
          if (index < 0 || index >= _users.length) {
            return const SizedBox.shrink();
          }

          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildUserAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafeDisplayName(user),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSafeEmail(user),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPopupMenu(user),
              ],
            ),
            const SizedBox(height: 12),
            _buildUserStatus(user),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    final displayName = _getSafeDisplayName(user);
    final avatarText =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CircleAvatar(
      backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
          ? NetworkImage(user.photoURL!)
          : null,
      backgroundColor: Colors.blue[100],
      child: user.photoURL == null || user.photoURL!.isEmpty
          ? Text(
              avatarText,
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildPopupMenu(UserModel user) {
    return PopupMenuButton<String>(
      onSelected: (String action) => _handleUserAction(user, action),
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        // Nếu user chưa được duyệt và có vai trò chờ duyệt
        if (!user.isRoleApproved && user.pendingRole != null) {
          items.add(
            PopupMenuItem(
              value: 'approve',
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text('Duyệt vai trò'),
                ],
              ),
            ),
          );
          items.add(
            PopupMenuItem(
              value: 'reject',
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text('Từ chối'),
                ],
              ),
            ),
          );
          items.add(const PopupMenuDivider());
        }

        // Thêm các vai trò để thay đổi
        items.addAll(
          UserRole.values.map((role) {
            return PopupMenuItem(
              value: 'change_${role.name}',
              child: Row(
                children: [
                  Icon(
                    _getRoleIcon(role),
                    color: _getRoleColor(role),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Đổi thành ${_getRoleName(role)}')),
                  if (user.role == role)
                    const Icon(Icons.check, color: Colors.green, size: 20),
                ],
              ),
            );
          }).toList(),
        );

        return items;
      },
      icon: const Icon(Icons.more_vert),
      tooltip: 'Thao tác',
    );
  }

  Widget _buildUserStatus(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị vai trò hiện tại
        Row(
          children: [
            const Icon(Icons.badge, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Vai trò hiện tại:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _buildRoleChip(user.role),
          ],
        ),

        // Hiển thị trạng thái duyệt
        if (!user.isRoleApproved && user.pendingRole != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.pending, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Chờ duyệt:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              _buildPendingRoleChip(user.pendingRole!.name),
            ],
          ),
        ],

        // Hiển thị phòng ban nếu đã được duyệt
        if (user.isRoleApproved && user.departmentName?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Phòng ban:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  user.departmentName!,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Hiển thị phòng ban chờ duyệt
        if (!user.isRoleApproved && user.pendingDepartment != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Phòng ban chờ duyệt:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  user.pendingDepartment!,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Hiển thị trạng thái tổng quát
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              user.isRoleApproved ? Icons.check_circle : Icons.schedule,
              size: 16,
              color: user.isRoleApproved ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              user.isRoleApproved ? 'Đã được duyệt' : 'Chờ duyệt vai trò',
              style: TextStyle(
                fontSize: 12,
                color: user.isRoleApproved ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChip(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getRoleName(role),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPendingRoleChip(String pendingRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        _getPendingRoleName(pendingRole),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper methods để đảm bảo an toàn
  String _getSafeDisplayName(UserModel user) {
    if (user.displayName.isNotEmpty) {
      return user.displayName;
    }
    if (user.email.isNotEmpty) {
      return user.email.split('@')[0]; // Lấy phần trước @ của email
    }
    return 'Người dùng';
  }

  String _getSafeEmail(UserModel user) {
    return user.email.isNotEmpty ? user.email : 'Không có email';
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.director:
        return 'Director';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
      case UserRole.guest:
        return 'Guest';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.director:
        return Colors.orange;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.employee:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.director:
        return Icons.manage_accounts;
      case UserRole.manager:
        return Icons.people;
      case UserRole.employee:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
    }
  }

  String _getPendingRoleName(String pendingRole) {
    switch (pendingRole.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'director':
        return 'Director';
      case 'manager':
        return 'Manager';
      case 'employee':
        return 'Employee';
      case 'guest':
        return 'Guest';
      default:
        return pendingRole;
    }
  }

  Future<void> _handleUserAction(UserModel user, String action) async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      switch (action) {
        case 'approve':
          await _approveUserRole(user, authProvider);
          break;
        case 'reject':
          await _rejectUserRole(user, authProvider);
          break;
        default:
          if (action.startsWith('change_')) {
            final roleName = action.substring(7); // Bỏ "change_"
            final newRole = UserRole.values.firstWhere(
              (role) => role.name == roleName,
              orElse: () => UserRole.guest,
            );
            await _changeUserRole(user, newRole);
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thực hiện thao tác: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveUserRole(
      UserModel user, AuthProvider authProvider) async {
    if (!mounted || user.pendingRole == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt vai trò'),
        content: Text(
          'Bạn có chắc chắn muốn duyệt vai trò ${_getRoleName(user.pendingRole!)} '
          'cho ${_getSafeDisplayName(user)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await authProvider.approveUserRole(user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã duyệt vai trò ${_getRoleName(user.pendingRole!)} cho ${_getSafeDisplayName(user)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUsers();
    }
  }

  Future<void> _rejectUserRole(
      UserModel user, AuthProvider authProvider) async {
    if (!mounted || user.pendingRole == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: Text(
          'Bạn có chắc chắn muốn từ chối vai trò ${_getRoleName(user.pendingRole!)} '
          'cho ${_getSafeDisplayName(user)}?\n\nNgười dùng sẽ vẫn giữ vai trò Guest.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await authProvider.rejectUserRole(user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã từ chối vai trò cho ${_getSafeDisplayName(user)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadUsers();
    }
  }

  Future<void> _changeUserRole(UserModel user, UserRole newRole) async {
    if (!mounted) return;

    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thay đổi'),
        content: Text(
          'Bạn có chắc chắn muốn thay đổi vai trò của ${_getSafeDisplayName(user)} '
          'từ ${_getRoleName(user.role)} thành ${_getRoleName(newRole)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.changeUserRole(user.id, newRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thay đổi vai trò của ${_getSafeDisplayName(user)} thành ${_getRoleName(newRole)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload user list
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thay đổi vai trò: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _changeUserRole(user, newRole),
            ),
          ),
        );
      }
    }
  }
}
