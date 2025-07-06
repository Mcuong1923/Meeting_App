import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class RoleApprovalScreen extends StatefulWidget {
  const RoleApprovalScreen({Key? key}) : super(key: key);

  @override
  State<RoleApprovalScreen> createState() => _RoleApprovalScreenState();
}

class _RoleApprovalScreenState extends State<RoleApprovalScreen>
    with SingleTickerProviderStateMixin {
  List<UserModel> _pendingUsers = [];
  List<UserModel> _departmentUsers = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Kiểm tra authentication state
      if (!authProvider.isAuthenticated) {
        throw Exception('Bạn chưa đăng nhập');
      }

      // Kiểm tra permissions
      if (authProvider.userModel == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      if (!authProvider.userModel!.isAdmin &&
          !authProvider.userModel!.isDirector) {
        throw Exception('Bạn không có quyền truy cập chức năng này');
      }

      // Load pending users
      _pendingUsers = await authProvider.getPendingUsers();

      // Load department users (nếu là Director)
      if (authProvider.userModel?.isDirector == true) {
        _departmentUsers = await authProvider.getUsersInDepartment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
      print('❌ RoleApprovalScreen _loadData error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDirector = authProvider.userModel?.isDirector == true;
    final userDepartment = authProvider.userModel?.departmentName ??
        authProvider.userModel?.departmentId ??
        'Chưa xác định';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý vai trò'),
            if (isDirector) ...[
              Text(
                'Phòng ban: $userDepartment',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: isDirector
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Chờ duyệt', icon: Icon(Icons.pending_actions)),
                  Tab(text: 'Quản lý PB', icon: Icon(Icons.people)),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isDirector
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingUsersList(),
                    _buildDepartmentUsersList(),
                  ],
                )
              : _buildPendingUsersList(),
    );
  }

  Widget _buildPendingUsersList() {
    if (_pendingUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào chờ phê duyệt',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        return _buildPendingUserCard(user);
      },
    );
  }

  Widget _buildDepartmentUsersList() {
    if (_departmentUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có nhân viên nào trong phòng ban',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _departmentUsers.length,
      itemBuilder: (context, index) {
        final user = _departmentUsers[index];
        return _buildDepartmentUserCard(user);
      },
    );
  }

  Widget _buildDepartmentUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin user
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleName(user.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Thông tin chi tiết
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getRoleIcon(user.role),
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('Vai trò: ${_getRoleName(user.role)}'),
                    ],
                  ),
                  if (user.departmentName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Phòng ban: ${user.departmentName}'),
                      ],
                    ),
                  ],
                  if (user.isActive) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Đang hoạt động'),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nút hành động (chỉ cho Director)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeUserRole(user),
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa vai trò'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteUser(user),
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin user
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Thông tin yêu cầu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yêu cầu phê duyệt:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getRoleIcon(user.pendingRole!),
                        size: 20,
                        color: _getRoleColor(user.pendingRole!),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vai trò: ${_getRoleName(user.pendingRole!)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (user.pendingDepartment != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phòng ban: ${user.pendingDepartment}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nút hành động
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveUser(user),
                    icon: const Icon(Icons.check),
                    label: const Text('Phê duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectUser(user),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      default:
        return 'Unknown';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.orange;
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
        return Icons.manage_accounts;
      case UserRole.director:
        return Icons.business_center;
      case UserRole.manager:
        return Icons.people;
      case UserRole.employee:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
      default:
        return Icons.help;
    }
  }

  Future<void> _approveUser(UserModel user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.approveUserRole(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Đã phê duyệt vai trò ${_getRoleName(user.pendingRole!)} cho ${user.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Reload danh sách
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phê duyệt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    // Hiển thị dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: Text(
            'Bạn có chắc chắn muốn từ chối yêu cầu vai trò ${_getRoleName(user.pendingRole!)} của ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.rejectUserRole(user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Đã từ chối yêu cầu vai trò của ${user.displayName}'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadData(); // Reload danh sách
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi từ chối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeUserRole(UserModel user) async {
    // Hiển thị dialog chọn role mới
    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thay đổi vai trò cho ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values
              .where((role) =>
                  role != UserRole.admin) // Director không thể tạo Admin
              .map((role) => ListTile(
                    leading: Icon(_getRoleIcon(role)),
                    title: Text(_getRoleName(role)),
                    onTap: () => Navigator.of(context).pop(role),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.changeUserRoleInDepartment(user.id, newRole);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã thay đổi vai trò của ${user.displayName} thành ${_getRoleName(newRole)}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Reload danh sách
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi thay đổi vai trò: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    // Hiển thị dialog xác nhận xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa nhân viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa nhân viên ${user.displayName}?'),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
            Text('Vai trò: ${_getRoleName(user.role)}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.deleteUserInDepartment(user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa nhân viên ${user.displayName}'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadData(); // Reload danh sách
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa nhân viên: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
