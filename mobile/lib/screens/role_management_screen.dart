import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '_edit_name_dialog.dart';
import '../providers/auth_provider.dart';
import '../providers/user_management_provider.dart';
import '../providers/organization_provider.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/team_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  UserManagementScreen (renamed from RoleManagementScreen, backward compat
//  via alias at bottom)
// ═══════════════════════════════════════════════════════════════════════════
class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

  static const _filters = [
    'Tất cả',
    'Chờ duyệt',
    'Admin',
    'Director',
    'Manager',
    'Employee',
    'Guest',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    final ump = context.read<UserManagementProvider>();
    ump.setActor(auth.userModel);
    await ump.loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter logic ───────────────────────────────────────────────────────
  List<UserModel> _filtered(List<UserModel> all) {
    var list = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) {
        return u.displayName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.departmentName ?? '').toLowerCase().contains(q) ||
            (u.teamId ?? '').toLowerCase().contains(q);
      }).toList();
    }
    switch (_selectedFilter) {
      case 'Chờ duyệt':
        list = list.where((u) => _isPending(u)).toList();
        break;
      case 'Admin':
        list = list.where((u) => u.role == UserRole.admin).toList();
        break;
      case 'Director':
        list = list.where((u) => u.role == UserRole.director).toList();
        break;
      case 'Manager':
        list = list.where((u) => u.role == UserRole.manager).toList();
        break;
      case 'Employee':
        list = list.where((u) => u.role == UserRole.employee).toList();
        break;
      case 'Guest':
        list = list.where((u) => u.role == UserRole.guest).toList();
        break;
    }
    return list;
  }

  bool _isPending(UserModel u) =>
      u.status == 'pending' ||
      (!u.isRoleApproved && u.requestedRole != null) ||
      u.requestedDepartmentId != null;

  // ── Action Handlers for UserCard ───────────────────────────────────────
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
        'Quản lý người dùng',
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
          hintText: 'Tìm kiếm theo tên, email hoặc vai trò...',
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
    final hasBadge = badge != null && badge! > 0;
    final displayText = hasBadge ? '$label ($badge)' : label;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B61F6) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + info + status + menu ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(user: user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row + status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _name(user),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF131313),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusDot(status: user.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A92A6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Three dots menu (always visible for non-pending)
                if (!isPending)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Color(0xFF8A92A6), size: 20),
                    onPressed: () => onAction(user),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Tags row ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(label: _roleName(user.role), style: _TagStyle.role),
                if (user.departmentName != null && user.departmentName!.isNotEmpty)
                  _TagChip(label: user.departmentName!.toUpperCase(), style: _TagStyle.outlined),
                if (user.teamId != null && user.teamId!.isNotEmpty)
                  _TagChip(label: _teamLabel(user.teamId!).toUpperCase(), style: _TagStyle.outlined),
              ],
            ),
            // ── Pending actions ──
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2B61F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Duyệt',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A5568),
                        side: const BorderSide(color: Color(0xFFDDE1E7)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Từ chối',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
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

  String _teamLabel(String teamId) {
    if (teamId.endsWith('__general')) return 'Chung';
    final parts = teamId.split('__');
    return parts.length > 1 ? parts.last : teamId;
  }

  String _roleName(UserRole r) {
    switch (r) {
      case UserRole.admin: return 'ADMIN';
      case UserRole.director: return 'DIRECTOR';
      case UserRole.manager: return 'MANAGER';
      case UserRole.employee: return 'EMPLOYEE';
      case UserRole.guest: return 'GUEST';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _TagChip
// ═══════════════════════════════════════════════════════════════════════════
enum _TagStyle { role, outlined }

class _TagChip extends StatelessWidget {
  final String label;
  final _TagStyle style;

  const _TagChip({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    final isRole = style == _TagStyle.role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRole ? const Color(0xFFF0F0F0) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isRole
            ? null
            : Border.all(color: const Color(0xFF2B61F6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isRole ? const Color(0xFF4A5568) : const Color(0xFF2B61F6),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _StatusDot — inline status indicator «• Hoạt động»
// ═══════════════════════════════════════════════════════════════════════════
class _StatusDot extends StatelessWidget {
  final String? status;
  const _StatusDot({this.status});

  @override
  Widget build(BuildContext context) {
    final eff = status ?? 'active';
    Color dotColor;
    String label;
    switch (eff) {
      case 'pending':
        dotColor = const Color(0xFFF59E0B);
        label = 'Chờ duyệt';
        break;
      case 'disabled':
        dotColor = const Color(0xFFEF4444);
        label = 'Bị khoá';
        break;
      default:
        dotColor = const Color(0xFF10B981);
        label = 'Hoạt động';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: dotColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _Avatar — colorful initials based on name hash
// ═══════════════════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  final UserModel user;

  const _Avatar({required this.user});

  static const _palette = [
    Color(0xFF4F6EF7), // blue
    Color(0xFF10B981), // teal
    Color(0xFFEF8C39), // orange
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // purple
    Color(0xFF06B6D4), // cyan
  ];

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.email;
    final colorIdx = name.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
    final bgColor = _palette[colorIdx];

    final initials = user.displayName.isNotEmpty
        ? user.displayName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join()
        : user.email.isNotEmpty
            ? user.email[0].toUpperCase()
            : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: bgColor,
      backgroundImage:
          user.photoURL != null ? NetworkImage(user.photoURL!) : null,
      child: user.photoURL == null
          ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            )
          : null,
    );
  }
}



// ═══════════════════════════════════════════════════════════════════════════
//  _ActionSheet — full bottom sheet with grouped actions
// ═══════════════════════════════════════════════════════════════════════════
class _ActionSheet extends StatefulWidget {
  final UserModel user;
  final UserModel? actor;
  final VoidCallback onDone;

  const _ActionSheet(
      {required this.user, required this.actor, required this.onDone});

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  bool _busy = false;

  UserModel get u => widget.user;
  UserModel? get actor => widget.actor;

  bool get _isPending =>
      u.status == 'pending' ||
      (!u.isRoleApproved && u.requestedRole != null) ||
      u.requestedDepartmentId != null;

  bool get _canEditAdmin => actor?.isAdmin ?? false;
  bool get _isTargetAdmin => u.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: safeBottom),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: const Color(0xFFF5F6FF),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Handle
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Avatar + name section (giống layout màn 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: _Avatar(user: u),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 6, bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B61F6),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      u.displayName.isNotEmpty
                          ? u.displayName
                          : 'Người dùng',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      u.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Nội dung scrollable
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: media.size.height * 0.55,
                ),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isTargetAdmin || _canEditAdmin) ...[
                        _sectionHeader('THÔNG TIN CÁ NHÂN'),
                        const SizedBox(height: 8),
                        _cardWrapper(
                          children: [
                            _actionTile(
                              icon: Icons.badge_outlined,
                              label: 'Sửa họ tên',
                              subtitle: u.displayName.isNotEmpty
                                  ? u.displayName
                                  : 'Người dùng',
                              onTap: () => _editDisplayName(context),
                            ),
                            _dividerThin(),
                            _actionTile(
                              icon: Icons.domain_rounded,
                              label: 'Đổi phòng ban',
                              subtitle: u.departmentName ?? 'Chưa có',
                              enabled: actor?.isAdmin == true,
                              onTap: () => _changeDepartment(context),
                            ),
                            _dividerThin(),
                            _actionTile(
                              icon: Icons.groups_2_rounded,
                              label: 'Đổi team',
                              subtitle: _teamLabel(u.teamId),
                              enabled: u.departmentId != null,
                              onTap: () => _changeTeam(context),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      if (!_isTargetAdmin || _canEditAdmin) ...[
                        _sectionHeader('PHÂN QUYỀN'),
                        const SizedBox(height: 8),
                        _cardWrapper(
                          children: [
                            _actionTile(
                              icon: Icons.manage_accounts_rounded,
                              label: 'Đổi vai trò',
                              subtitle: _roleName(u.role),
                              onTap: () => _changeRole(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      _sectionHeader('TRẠNG THÁI'),
                      const SizedBox(height: 8),
                      _cardWrapper(
                        children: [
                          if (u.status != 'active')
                            _actionTile(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Kích hoạt tài khoản',
                              color: Colors.green.shade700,
                              onTap: () => _setStatus(context, 'active'),
                            ),
                          if (u.status == 'active' && !_isTargetAdmin)
                            _actionTile(
                              icon: Icons.block_rounded,
                              label: 'Vô hiệu hoá',
                              color: Colors.orange.shade700,
                              onTap: () => _setStatus(context, 'disabled'),
                            ),
                          if (u.status == 'active' && _isTargetAdmin)
                            _actionTile(
                              icon: Icons.info_outline_rounded,
                              label: 'Admin đang hoạt động',
                              enabled: false,
                              color: Colors.grey.shade600,
                              subtitle: 'Không thể vô hiệu hoá Admin hiện tại',
                              onTap: () {},
                            ),
                        ],
                      ),

                      if (_isPending) ...[
                        const SizedBox(height: 20),
                        _sectionHeader('XÉT DUYỆT YÊU CẦU'),
                        const SizedBox(height: 8),
                        _cardWrapper(
                          children: [
                            _actionTile(
                              icon: Icons.thumb_up_rounded,
                              label: 'Duyệt yêu cầu',
                              color: Colors.green.shade700,
                              onTap: () => _approve(context),
                            ),
                            _dividerThin(),
                            _actionTile(
                              icon: Icons.thumb_down_rounded,
                              label: 'Từ chối yêu cầu',
                              color: Colors.red.shade600,
                              onTap: () => _reject(context),
                            ),
                          ],
                        ),
                      ],

                      if (!_isTargetAdmin || _canEditAdmin) ...[
                        const SizedBox(height: 20),
                        _sectionHeader('VÙNG NGUY HIỂM'),
                        const SizedBox(height: 8),
                        _cardWrapper(
                          children: [
                            _actionTile(
                              icon: Icons.delete_forever_rounded,
                              label: 'Xoá vĩnh viễn',
                              subtitle: 'Không thể khôi phục',
                              color: Colors.red.shade700,
                              onTap: () => _deleteUser(context),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Nút dưới cùng: Hủy / Lưu thay đổi
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 8 + (safeBottom > 0 ? 4 : 8)),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDone();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          backgroundColor: const Color(0xFF2B61F6),
                        ),
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_busy)
                Container(
                  color: Colors.black12,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _cardWrapper({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _dividerThin() {
    return const Divider(
      height: 1,
      thickness: 0.7,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? color,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    final c = color ?? const Color(0xFF1A1A1A);
    return ListTile(
      enabled: enabled,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: enabled ? c : Colors.grey.shade400),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: enabled ? c : Colors.grey.shade400)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500))
          : null,
      onTap: enabled ? onTap : null,
      dense: true,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _teamLabel(String? teamId) {
    if (teamId == null || teamId.isEmpty) return 'Chưa có';
    if (teamId.endsWith('__general')) return 'Chung (Chưa phân team)';
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

  // ── Core run helpers ───────────────────────────────────────────────────────
  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } catch (e) {
      debugPrint('[USER_EDIT] Firestore error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runAndRefresh(
      UserManagementProvider ump, Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
      debugPrint('[USER_EDIT] Firestore success');
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã cập nhật thành công'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('[USER_EDIT] Firestore error: $e');
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Edit display name ──────────────────────────────────────────────────────
  void _editDisplayName(BuildContext ctx) async {
    debugPrint('[USER_EDIT] updateDisplayName opened uid=${u.id}');
    final ump = ctx.read<UserManagementProvider>();
    final ctrl = TextEditingController(text: u.displayName);

    final result = await showDialog<String>(
      context: ctx,
      // Use EditNameDialog which handles keyboard insets internally
      // without registering cross-overlay MediaQuery dependencies.
      builder: (dCtx) => EditNameDialog(initial: u.displayName),
    );
    ctrl.dispose();

    if (result != null && result.isNotEmpty && mounted) {
      debugPrint('[USER_EDIT] updateDisplayName payload uid=${u.id} name=$result');
      await _runAndRefresh(ump, () => ump.updateDisplayName(u.id, result));
    }
  }

  // ── Change department ──────────────────────────────────────────────────────
  void _changeDepartment(BuildContext ctx) async {
    debugPrint('[USER_EDIT] changeDepartment opened uid=${u.id}');
    final orgProvider = ctx.read<OrganizationProvider>();
    final ump = ctx.read<UserManagementProvider>();

    if (orgProvider.availableDepartments.isEmpty) {
      await orgProvider.loadDepartments();
    }
    if (!mounted) return;

    final depts = orgProvider.availableDepartments;
    if (depts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có dữ liệu phòng ban')));
      }
      return;
    }

    String? selectedDeptId = u.departmentId;

    final result = await showDialog<String>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setD) => AlertDialog(
          title: const Text('Chọn phòng ban'),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 340,
            child: ListView(
              shrinkWrap: true,
              children: depts.map((d) {
                return RadioListTile<String>(
                  value: d.id,
                  groupValue: selectedDeptId,
                  title: Text(d.name),
                  dense: true,
                  activeColor: const Color(0xFF2B61F6),
                  onChanged: (v) => setD(() => selectedDeptId = v),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx2, selectedDeptId),
                child: const Text('Xác nhận')),
          ],
        ),
      ),
    );

    if (result != null && result != u.departmentId && mounted) {
      final deptObj =
          depts.firstWhere((d) => d.id == result, orElse: () => depts.first);
      debugPrint(
          '[USER_EDIT] changeDepartment payload uid=${u.id} deptId=$result name=${deptObj.name}');
      await _runAndRefresh(
          ump, () => ump.updateDepartment(u.id, result, deptObj.name));
    }
  }

  // ── Change team ────────────────────────────────────────────────────────────
  void _changeTeam(BuildContext ctx) async {
    debugPrint('[USER_EDIT] changeTeam opened uid=${u.id} dept=${u.departmentId}');
    if (u.departmentId == null) return;
    final ump = ctx.read<UserManagementProvider>();
    List<TeamModel> teams;
    try {
      teams = await ump.fetchTeamsForDepartment(u.departmentId!);
    } catch (e) {
      debugPrint('[USER_EDIT] fetchTeams error: $e');
      teams = [];
    }
    if (!mounted) return;
    if (teams.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có team trong phòng ban này')));
      }
      return;
    }

    String? selectedTeamId = u.teamId;

    final result = await showDialog<TeamModel>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setD) => AlertDialog(
          title: Text('Chọn team — ${u.departmentName ?? u.departmentId}'),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 340,
            child: ListView(
              shrinkWrap: true,
              children: teams.map((t) {
                return RadioListTile<String>(
                  value: t.id,
                  groupValue: selectedTeamId,
                  title: Text(t.name,
                      style: TextStyle(
                          fontStyle: t.isGeneralTeam
                              ? FontStyle.italic
                              : FontStyle.normal)),
                  subtitle: t.description.isNotEmpty
                      ? Text(t.description,
                          style: const TextStyle(fontSize: 12))
                      : null,
                  dense: true,
                  activeColor: const Color(0xFF2B61F6),
                  onChanged: (v) => setD(() => selectedTeamId = v),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(
                    ctx2,
                    teams.firstWhere((t) => t.id == selectedTeamId,
                        orElse: () => teams.first)),
                child: const Text('Xác nhận')),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      debugPrint(
          '[USER_EDIT] changeTeam payload uid=${u.id} teamId=${result.id} teamName=${result.name}');
      await _runAndRefresh(ump,
          () => ump.updateTeam(u.id, u.departmentId!, result.id, result.name));
    }
  }

  // ── Change role ────────────────────────────────────────────────────────────
  void _changeRole(BuildContext ctx) async {
    debugPrint('[USER_EDIT] changeRole opened uid=${u.id}');
    final ump = ctx.read<UserManagementProvider>();
    UserRole selected = u.role;

    final allowedRoles = actor?.isAdmin == true
        ? UserRole.values
        : actor?.isDirector == true
            ? [UserRole.manager, UserRole.employee, UserRole.guest]
            : [UserRole.employee, UserRole.guest];

    final result = await showDialog<UserRole>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setD) => AlertDialog(
          title: const Text('Chọn vai trò'),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allowedRoles.map((r) {
                return RadioListTile<UserRole>(
                  value: r,
                  groupValue: selected,
                  title: Text(_roleName(r)),
                  dense: true,
                  activeColor: const Color(0xFF2B61F6),
                  onChanged: (v) => setD(() => selected = v!),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx2, selected),
                child: const Text('Xác nhận')),
          ],
        ),
      ),
    );

    if (result != null && result != u.role && mounted) {
      debugPrint(
          '[USER_EDIT] changeRole payload uid=${u.id} newRole=${result.name}');
      await _runAndRefresh(ump, () => ump.updateRole(u.id, result));
    }
  }

  // ── Toggle status ──────────────────────────────────────────────────────────
  Future<void> _setStatus(BuildContext ctx, String status) async {
    final ump = ctx.read<UserManagementProvider>();
    debugPrint('[USER_EDIT] setStatus payload uid=${u.id} status=$status');
    await _runAndRefresh(ump, () => ump.updateStatus(u.id, status));
  }

  // ── Approve ────────────────────────────────────────────────────────────────
  Future<void> _approve(BuildContext ctx) async {
    final ump = ctx.read<UserManagementProvider>();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Duyệt yêu cầu'),
        content: Text(
            'Duyệt yêu cầu của ${u.displayName.isNotEmpty ? u.displayName : u.email}?\n\n'
            'Vai trò: ${u.requestedRole != null ? _roleName(u.requestedRole!) : "?"}\n'
            'Phòng ban: ${u.requestedDepartmentId ?? "?"}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Duyệt')),
        ],
      ),
    );
    if (ok == true && mounted) {
      debugPrint('[USER_EDIT] approveUser payload uid=${u.id}');
      await _runAndRefresh(ump, () => ump.approveUser(u.id));
    }
  }

  // ── Reject ─────────────────────────────────────────────────────────────────
  Future<void> _reject(BuildContext ctx) async {
    final ump = ctx.read<UserManagementProvider>();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: Text(
            'Từ chối yêu cầu của ${u.displayName.isNotEmpty ? u.displayName : u.email}?\n\n'
            'Tài khoản sẽ bị vô hiệu hoá.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Từ chối')),
        ],
      ),
    );
    if (ok == true && mounted) {
      debugPrint('[USER_EDIT] rejectUser payload uid=${u.id}');
      await _runAndRefresh(ump, () => ump.rejectUser(u.id));
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteUser(BuildContext ctx) async {
    final ump = ctx.read<UserManagementProvider>();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Xoá vĩnh viễn'),
        content: Text(
            'Bạn có chắc muốn XOÁ VĨNH VIỄN tài khoản\n'
            '"${u.displayName.isNotEmpty ? u.displayName : u.email}"?\n\n'
            'Thao tác này KHÔNG THỂ hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('XÓA VĨNH VIỄN')),
        ],
      ),
    );
    if (ok == true && mounted) {
      debugPrint('[USER_EDIT] hardDeleteUser payload uid=${u.id}');
      await _runAndRefresh(ump, () => ump.hardDeleteUser(u.id));
    }
  }
}
