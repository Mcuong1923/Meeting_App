import re
import sys

file_path = r'd:\study\MEETING_APP\mobile\lib\screens\role_management_screen.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
except FileNotFoundError:
    print(f"Error: {file_path} not found.")
    sys.exit(1)

# Split content at markers
start_marker = r'  // ── Build '
end_marker = r'//  _ActionSheet — full bottom sheet with grouped actions'

if start_marker not in content:
    print("Start marker not found.")
    sys.exit(1)
if end_marker not in content:
    print("End marker not found.")
    sys.exit(1)

parts_before = content.split(start_marker, 1)
before = parts_before[0]

# Now split the second part using the second marker
# But wait, we want to split by the line containing "_ActionSheet —" and ALSO the line of ==== before it.
# A regex is better.
pattern = re.compile(r'  // ── Build ──────────────────────────────────────────────────────────────.*?(?=\r?\n// ═══════════════════════════════════════════════════════════════════════════\r?\n//  _ActionSheet — full bottom sheet with grouped actions)', re.DOTALL)

if not pattern.search(content):
    print("Pattern not found!")
    sys.exit(1)

replacement = r"""  // ── Action Handlers for UserCard ───────────────────────────────────────
  Future<void> _approveUser(UserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Duyệt yêu cầu'),
        content: Text(
            'Duyệt yêu cầu của ${u.displayName.isNotEmpty ? u.displayName : u.email}?\n\n'
            'Vai trò: ${u.requestedRole != null ? _roleName(u.requestedRole!) : "?"}\n'
            'Phòng ban: ${u.requestedDepartmentId ?? "?"}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Duyệt')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<UserManagementProvider>().approveUser(u.id);
        if (mounted) context.read<UserManagementProvider>().loadUsers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _rejectUser(UserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: Text(
            'Từ chối yêu cầu của ${u.displayName.isNotEmpty ? u.displayName : u.email}?\n\n'
            'Tài khoản sẽ bị vô hiệu hoá.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Từ chối')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<UserManagementProvider>().rejectUser(u.id);
        if (mounted) context.read<UserManagementProvider>().loadUsers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  String _roleName(UserRole r) {
    switch (r) {
      case UserRole.admin: return 'Admin';
      case UserRole.director: return 'Director';
      case UserRole.manager: return 'Manager';
      case UserRole.employee: return 'Employee';
      case UserRole.guest: return 'Guest';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Consumer<UserManagementProvider>(
        builder: (_, ump, __) {
          if (ump.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B61F6)),
            );
          }
          if (ump.error != null) {
            return _errorState(ump.error!);
          }
          final list = _filtered(ump.users);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              _buildFilterBar(ump.users),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'DANH SÁCH NGƯỜI DÙNG',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: const Color(0xFF2B61F6),
                        onRefresh: () => ump.loadUsers(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _UserCard(
                            user: list[i],
                            onAction: _openActions,
                            onApprove: () => _approveUser(list[i]),
                            onReject: () => _rejectUser(list[i]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF131313)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Quản lý vai trò người dùng',
        style: TextStyle(
            color: Color(0xFF131313), fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.autorenew_rounded, color: Color(0xFF2B61F6)),
          onPressed: () => context.read<UserManagementProvider>().loadUsers(),
          tooltip: 'Tải lại',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, email, phòng ban...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF2B61F6), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(List<UserModel> all) {
    final pendingCount = all.where(_isPending).length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12, left: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final count = f == 'Chờ duyệt' ? pendingCount : null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: f,
                badge: count,
                isSelected: _selectedFilter == f,
                onTap: () => setState(() => _selectedFilter = f),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tất cả'
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tất cả'
                  ? 'Không tìm thấy kết quả'
                  : 'Chưa có người dùng',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<UserManagementProvider>().loadUsers(),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2B61F6)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action Bottom Sheet ───────────────────────────────────────────────
  void _openActions(UserModel user) {
    final actor = context.read<AuthProvider>().userModel;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        user: user,
        actor: actor,
        onDone: () => context.read<UserManagementProvider>().loadUsers(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _FilterChip
// ═══════════════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? badge;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isPendingChip = label == 'Chờ duyệt';
    final displayText = (isPendingChip && badge != null && badge! > 0)
        ? 'Chờ duyệt ($badge)'
        : label;

    Color bgColor;
    Color textColor;
    BorderSide border;

    if (isSelected) {
      if (isPendingChip) {
        bgColor = const Color(0xFFFFF7ED); // Very light orange
        textColor = const Color(0xFFDD6B20); // Orange
        border = const BorderSide(color: Color(0xFFEE9D64));
      } else {
        bgColor = const Color(0xFF2B61F6); // Blue
        textColor = Colors.white;
        border = const BorderSide(color: Color(0xFF2B61F6));
      }
    } else {
      if (isPendingChip) {
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFDD6B20);
        border = BorderSide(color: Colors.orange.shade200);
      } else {
        bgColor = Colors.white;
        textColor = const Color(0xFF4A5568);
        border = BorderSide(color: Colors.grey.shade300);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.fromBorderSide(border),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _UserCard
// ═══════════════════════════════════════════════════════════════════════════
class _UserCard extends StatelessWidget {
  final UserModel user;
  final void Function(UserModel) onAction;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _UserCard({
    required this.user,
    required this.onAction,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = user.status == 'pending' ||
        (!user.isRoleApproved && user.requestedRole != null) ||
        user.requestedDepartmentId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPending
            ? Border.all(color: Colors.orange.shade200, width: 1)
            : Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(user: user, isPending: isPending),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _name(user),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF131313),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPending)
                            _PendingBadge()
                          else
                            _RoleBadge(role: user.role),
                          if (!isPending) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
                                onPressed: () => onAction(user),
                                splashRadius: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              const Text(
                'YÊU CẦU CHỜ DUYỆT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A92A6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoColumn('Vai trò', user.requestedRole != null ? _roleName(user.requestedRole!) : _roleName(user.role)),
                  ),
                  Expanded(
                    child: _buildInfoColumn('Phòng ban', user.requestedDepartmentId ?? user.departmentName ?? 'Chưa có'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoColumn('Team', _teamLabel(user.requestedTeamId ?? user.teamId)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2B61F6), // Blue
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Duyệt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A5568),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _name(UserModel u) =>
      u.displayName.isNotEmpty ? u.displayName : u.email.split('@').first;

  String _teamLabel(String? teamId) {
    if (teamId == null || teamId.isEmpty) return 'Chưa có';
    if (teamId.endsWith('__general')) return 'Chung';
    final parts = teamId.split('__');
    return parts.length > 1 ? parts.last : teamId;
  }

  String _roleName(UserRole r) {
    switch (r) {
      case UserRole.admin: return 'Admin';
      case UserRole.director: return 'Director';
      case UserRole.manager: return 'Manager';
      case UserRole.employee: return 'Employee';
      case UserRole.guest: return 'Guest';
    }
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF131313),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _Avatar
// ═══════════════════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  final UserModel user;
  final bool isPending;

  const _Avatar({required this.user, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join()
        : '?';

    Color bgColor;
    Color textColor;

    if (isPending) {
      bgColor = const Color(0xFFE0E7FF); // Light blue
      textColor = const Color(0xFF2B61F6); // Blue
    } else {
      bgColor = const Color(0xFFF3F4F6); // Light grey
      textColor = const Color(0xFF4B5563); // Dark grey
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: bgColor,
      backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
      child: user.photoURL == null
          ? Text(initials,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 16))
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _RoleBadge & _PendingBadge
// ═══════════════════════════════════════════════════════════════════════════
class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _c(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(role),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _label(UserRole r) {
    switch (r) {
      case UserRole.admin: return 'Admin';
      case UserRole.director: return 'Director';
      case UserRole.manager: return 'Manager';
      case UserRole.employee: return 'Employee';
      case UserRole.guest: return 'Guest';
    }
  }

  Color _c(UserRole r) {
    switch (r) {
      case UserRole.admin: return const Color(0xFF2B61F6);
      case UserRole.director: return const Color(0xFF8B5CF6);
      case UserRole.manager: return const Color(0xFFF59E0B);
      case UserRole.employee: return const Color(0xFF10B981);
      case UserRole.guest: return const Color(0xFF6B7280);
    }
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Chờ duyệt',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE65100),
        ),
      ),
    );
  }
}

"""

new_content = pattern.sub(replacement, content)
if new_content == content:
    print("Content did not change!")
    sys.exit(1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)
print("File updated successfully.")
