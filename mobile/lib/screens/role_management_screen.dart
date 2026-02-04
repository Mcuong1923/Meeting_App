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
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Search & Filter state
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

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
          _filteredUsers = _users;
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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quản lý vai trò',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF1A1A1A)),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A1A)),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B7FED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tất cả'
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tất cả'
                  ? 'Không tìm thấy kết quả'
                  : 'Không có người dùng nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF9B7FED),
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    // Filter Bar (Mock)
    return Column(
      children: [
        // Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', isSelected: _selectedFilter == 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip('Director', isSelected: _selectedFilter == 'Director'),
                const SizedBox(width: 8),
                _buildFilterChip('Manager', isSelected: _selectedFilter == 'Manager'),
                const SizedBox(width: 8),
                _buildFilterChip('Chờ duyệt', isSelected: _selectedFilter == 'Chờ duyệt'),
              ],
            ),
          ),
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            color: const Color(0xFF9B7FED),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tìm kiếm người dùng'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên, email, phòng ban...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
              _applyFilters();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _applyFilters();
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    List<UserModel> result = _users;

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((user) {
        final name = user.displayName.toLowerCase();
        final email = user.email.toLowerCase();
        final dept = (user.departmentName ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
               email.contains(_searchQuery) ||
               dept.contains(_searchQuery);
      }).toList();
    }

    // Apply role filter
    if (_selectedFilter != 'Tất cả') {
      if (_selectedFilter == 'Chờ duyệt') {
        result = result.where((user) => !user.isRoleApproved && user.pendingRole != null).toList();
      } else {
        result = result.where((user) => _getRoleName(user.role) == _selectedFilter).toList();
      }
    }

    setState(() {
      _filteredUsers = result;
    });
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Future enhancement: Open detail view
            // For now, trigger menu for quick actions
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Row: Avatar + Name/Email + Action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontSize: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getSafeEmail(user),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildPopupMenu(user),
                  ],
                ),
                
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),
                
                // Info Rows
                _buildInfoRow(
                  'Vai trò:', 
                  _getRoleName(user.role), 
                  valueColor: _getRoleTextColor(user.role),
                  icon: Icons.badge_outlined,
                ),
                
                if (user.departmentName?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Phòng ban:', 
                    user.departmentName!, 
                    valueColor: Colors.blue.shade700,
                    icon: Icons.business_outlined,
                  ),
                ],
                
                // Status Chip Row (if needed - e.g. Pending)
                if (!user.isRoleApproved && user.pendingRole != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Chờ duyệt: ${_getPendingRoleName(user.pendingRole!.name)}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? valueColor, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
           decoration: BoxDecoration(
             color: (valueColor ?? Colors.black).withOpacity(0.05),
             borderRadius: BorderRadius.circular(6),
           ),
           child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    final displayName = _getSafeDisplayName(user);
    final avatarText =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
          ? NetworkImage(user.photoURL!)
          : null,
      backgroundColor: const Color(0xFFF0F1F5),
      child: user.photoURL == null || user.photoURL!.isEmpty
          ? Text(
              avatarText,
              style: const TextStyle(
                color: Color(0xFF9B7FED),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  Widget _buildPopupMenu(UserModel user) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
        color: Colors.white,
        onSelected: (String action) => _handleUserAction(user, action),
        itemBuilder: (context) {
          List<PopupMenuEntry<String>> items = [];

          // Approval actions if pending
          if (!user.isRoleApproved && user.pendingRole != null) {
            items.add(
              PopupMenuItem(
                value: 'approve',
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Duyệt vai trò',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
            items.add(
              PopupMenuItem(
                value: 'reject',
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Từ chối',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
            items.add(PopupMenuDivider(height: 1, thickness: 0.5));
          }

          // Role selection items
          items.addAll(
            UserRole.values.map((role) {
              final isSelected = user.role == role;
              
              return PopupMenuItem(
                value: 'change_${role.name}',
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      _getRoleIconForMenu(role),
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getRoleName(role),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF9B7FED) : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF9B7FED),
                        size: 18,
                      ),
                  ],
                ),
              );
            }).toList(),
          );

          // Delete action
          items.add(PopupMenuDivider(height: 1, thickness: 0.5));
          items.add(
            PopupMenuItem(
              value: 'delete',
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Xóa',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );

          return items;
        },
        icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400, size: 24),
        tooltip: 'Thao tác',
      ),
    );
  }

  IconData _getRoleIconForMenu(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.director:
        return Icons.work_outline_rounded;
      case UserRole.manager:
        return Icons.groups_outlined;
      case UserRole.employee:
        return Icons.person_outline_rounded;
      case UserRole.guest:
        return Icons.person_off_outlined;
    }
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

  // Helper methods
  Color _getRoleTextColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red.shade700;
      case UserRole.director:
        return Colors.orange.shade800;
      case UserRole.manager:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
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
        case 'delete':
          await _deleteUser(user, authProvider);
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B7FED)),
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

  Future<void> _deleteUser(UserModel user, AuthProvider authProvider) async {
    if (!mounted) return;

    // Kiểm tra không cho xóa chính mình
    if (authProvider.userModel?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không thể xóa chính mình!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác nhận xóa thành viên'),
        content: Text(
          'Bạn có chắc chắn muốn xóa thành viên ${_getSafeDisplayName(user)} (${_getSafeEmail(user)})?\n\n'
          'Tất cả dữ liệu của thành viên này sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'XÓA VĨNH VIỄN',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await authProvider.deleteUser(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Đã xóa thành viên ${_getSafeDisplayName(user)}',
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
            content: Text('❌ Lỗi xóa thành viên: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _deleteUser(user, authProvider),
            ),
          ),
        );
      }
    }
  }
}
