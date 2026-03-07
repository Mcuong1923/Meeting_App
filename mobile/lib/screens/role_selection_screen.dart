import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../models/user_role.dart';
import '../models/team_model.dart';
import 'welcome/welcome_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  static const _navy = Color(0xFF2D2B6B);
  static const _bg   = Color(0xFFF4F5F9);

  String? _selectedDepartment;
  String? _selectedTeamId;
  bool _isSubmitting = false;
  final TextEditingController _fullNameController = TextEditingController();

  // Local cache: departmentId → list of teams (avoids refetch on dept switch)
  final Map<String, List<TeamModel>> _teamsCache = {};

  /// Map mỗi phòng ban → icon + mô tả ngắn
  static const Map<String, Map<String, dynamic>> _deptMeta = {
    'Công nghệ thông tin': {'icon': Icons.computer_rounded,    'desc': 'Phát triển & hạ tầng kỹ thuật'},
    'Nhân sự':            {'icon': Icons.people_alt_rounded,   'desc': 'Tuyển dụng & phúc lợi nhân viên'},
    'Marketing':          {'icon': Icons.campaign_rounded,     'desc': 'Truyền thông & thương hiệu'},
    'Kế toán':            {'icon': Icons.account_balance_rounded, 'desc': 'Tài chính & kế toán nội bộ'},
    'Kinh doanh':         {'icon': Icons.trending_up_rounded,  'desc': 'Kinh doanh & phát triển thị trường'},
    'Vận hành':           {'icon': Icons.settings_rounded,     'desc': 'Vận hành hệ thống & quy trình'},
    'Khác':               {'icon': Icons.category_rounded,     'desc': 'Các bộ phận khác'},
  };

  final List<String> _departments = [
    'Công nghệ thông tin',
    'Nhân sự',
    'Marketing',
    'Kế toán',
    'Kinh doanh',
    'Vận hành',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userModel != null) {
        // Only pre-fill if it's a real non-placeholder name
        final name = auth.userModel!.displayName;
        final isPlaceholder = name.isEmpty ||
            name == 'Người dùng' ||
            name.toLowerCase() == 'user' ||
            name.toLowerCase().startsWith('user ');
        if (!isPlaceholder) {
          _fullNameController.text = name;
        }
        if (_departments.contains(auth.userModel!.requestedDepartmentId)) {
          setState(() => _selectedDepartment = auth.userModel!.requestedDepartmentId);
          _loadTeams(_selectedDepartment!).then((_) {
            final rid = auth.userModel!.requestedTeamId;
            if (rid != null) {
              final org = Provider.of<OrganizationProvider>(context, listen: false);
              if (org.availableTeams.any((t) => t.id == rid)) {
                setState(() => _selectedTeamId = rid);
              }
            }
          });
        }
      }
    });
  }

  Future<void> _loadTeams(String deptId) async {
    if (_teamsCache.containsKey(deptId)) {
      final org = Provider.of<OrganizationProvider>(context, listen: false);
      org.setAvailableTeamsFromCache(_teamsCache[deptId]!, deptId);
      return;
    }
    final org = Provider.of<OrganizationProvider>(context, listen: false);
    await org.loadTeamsByDepartment(deptId);
    _teamsCache[deptId] = List.of(org.availableTeams);
  }

  void _onDeptChanged(String? v) {
    setState(() { _selectedDepartment = v; _selectedTeamId = null; });
    if (v != null) _loadTeams(v);
  }

  @override
  void dispose() { _fullNameController.dispose(); super.dispose(); }

  bool _canSubmit() {
    final org = Provider.of<OrganizationProvider>(context, listen: false);
    final teamOk = org.availableTeams.isEmpty
        ? true
        : (_selectedTeamId != null && _selectedTeamId!.isNotEmpty);
    return _fullNameController.text.trim().isNotEmpty &&
        _selectedDepartment != null &&
        teamOk &&
        !_isSubmitting;
  }

  // ─── field decoration ────────────────────────────────────────────
  InputDecoration _fieldDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: _navy.withOpacity(0.55), size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ─── section label ───────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    ),
  );

  // ─── Selector field (tap → bottom sheet) ─────────────────────────
  Widget _selectorField({
    required String hint,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(icon, color: _navy.withOpacity(0.55), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: isLoading
                  ? Row(children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _navy.withOpacity(0.6)),
                      ),
                      const SizedBox(width: 10),
                      Text('Đang tải...', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                    ])
                  : Text(
                      value ?? hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: value == null ? Colors.grey.shade400 : const Color(0xFF1A1A2E),
                      ),
                    ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // ─── Bottom sheet: chọn phòng ban ────────────────────────────────
  Future<void> _showDepartmentSheet() async {
    String? temp = _selectedDepartment;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final mq = MediaQuery.of(ctx);
          final viewInsets = mq.viewInsets.bottom;
          final bottomPad = mq.padding.bottom;
          // Tính maxHeight cho list: 92% màn hình - keyboard - header cố định - button
          final totalAvailable = mq.size.height * 0.92 - viewInsets;
          const fixedHeight = 28.0 + 56.0 + 1.0 + 20.0; // handle+header+divider+topPad
          final buttonZone = 52.0 + 32.0 + (viewInsets > 0 ? 12.0 : (bottomPad + 20.0));
          final maxListHeight = (totalAvailable - fixedHeight - buttonZone).clamp(80.0, mq.size.height * 0.6);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Chọn phòng ban',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade100, height: 1),

                // List - chiều cao tính toán chính xác, không overflow
                SizedBox(
                  height: maxListHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _departments.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.grey.shade100,
                      height: 1,
                      indent: 72,
                    ),
                    itemBuilder: (_, i) {
                      final dept = _departments[i];
                      final meta = _deptMeta[dept];
                      final icon = (meta?['icon'] as IconData?) ?? Icons.domain_rounded;
                      final desc = (meta?['desc'] as String?) ?? '';
                      final isSelected = temp == dept;

                      return InkWell(
                        onTap: () => setSheet(() => temp = dept),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              // Icon container
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _navy.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon,
                                  size: 22,
                                  color: isSelected ? _navy : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name + desc
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dept,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(desc,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Radio
                              _RadioDot(selected: isSelected),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Confirm button
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20,
                    viewInsets > 0 ? 12 : (bottomPad + 20)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: temp == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _onDeptChanged(temp);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        disabledBackgroundColor: _navy.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Xác nhận',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ─── Bottom sheet: chọn team ──────────────────────────────────────
  Future<void> _showTeamSheet(List<TeamModel> teams) async {
    String? temp = _selectedTeamId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final mq = MediaQuery.of(ctx);
          final viewInsets = mq.viewInsets.bottom;
          final bottomPad = mq.padding.bottom;
          final totalAvailable = mq.size.height * 0.92 - viewInsets;
          const fixedHeight = 28.0 + 56.0 + 1.0 + 20.0;
          final buttonZone = 52.0 + 32.0 + (viewInsets > 0 ? 12.0 : (bottomPad + 20.0));
          final maxListHeight = (totalAvailable - fixedHeight - buttonZone).clamp(80.0, mq.size.height * 0.6);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Chọn team',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade100, height: 1),

                // List - chiều cao tính toán chính xác, không overflow
                SizedBox(
                  height: maxListHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.grey.shade100,
                      height: 1,
                      indent: 72,
                    ),
                    itemBuilder: (_, i) {
                      final team = teams[i];
                      final isSelected = temp == team.id;
                      final isGeneral = team.isGeneralTeam;

                      return InkWell(
                        onTap: () => setSheet(() => temp = team.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _navy.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isGeneral ? Icons.group_outlined : Icons.groups_2_rounded,
                                  size: 22,
                                  color: isSelected ? _navy : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team.name,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        fontStyle: isGeneral ? FontStyle.italic : FontStyle.normal,
                                        color: isGeneral ? Colors.grey.shade500 : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    if (team.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        team.description,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Radio
                              _RadioDot(selected: isSelected),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Confirm button
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20,
                    viewInsets > 0 ? 12 : (bottomPad + 20)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: temp == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              setState(() => _selectedTeamId = temp);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        disabledBackgroundColor: _navy.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Xác nhận',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userModel;
    final isPending = user != null && user.status == 'pending' && user.requestedDepartmentId != null;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isPending
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text(
          'Yêu cầu quyền truy cập',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await auth.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi đăng xuất: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────
            Text(
              isPending ? 'Yêu cầu đang chờ duyệt' : 'Chào mừng bạn đến với hệ thống!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isPending ? const Color(0xFFE07B00) : const Color(0xFF1A1A2E),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPending
                  ? 'Yêu cầu tham gia phòng ban của bạn đã được gửi.\nQuản trị viên sẽ phê duyệt sớm nhất có thể.'
                  : 'Tài khoản nội bộ cần được phê duyệt. Vui lòng cập nhật họ tên, chọn phòng ban và team của bạn.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500, height: 1.5),
            ),

            const SizedBox(height: 32),

            // ── Full Name ───────────────────────────────────────
            _label('Họ và tên'),
            TextField(
              controller: _fullNameController,
              decoration: _fieldDecoration(hint: 'Họ và tên của bạn', icon: Icons.person_outline_rounded),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // ── Department ──────────────────────────────────────
            _label('Phòng ban'),
            _selectorField(
              hint: 'Chọn phòng ban',
              value: _selectedDepartment,
              icon: Icons.domain_rounded,
              onTap: _showDepartmentSheet,
            ),

            // ── Team ────────────────────────────────────────────
            if (_selectedDepartment != null) ...[
              const SizedBox(height: 24),
              _label('Team'),
              _buildTeamSelector(),
            ],

            const SizedBox(height: 32),

            // ── Pending info banner ─────────────────────────────
            if (isPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFE07B00), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn có thể cập nhật lại thông tin nếu có sai sót. Tính năng tạo cuộc họp sẽ mở sau khi được duyệt.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFFB36200), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 32),

            // ── Submit button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  disabledBackgroundColor: _navy.withOpacity(0.35),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        isPending ? 'Cập nhật yêu cầu' : 'Gửi yêu cầu',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ─── Team selector widget (Consumer) ─────────────────────────────
  Widget _buildTeamSelector() {
    return Consumer<OrganizationProvider>(
      builder: (context, org, _) {
        if (org.isLoadingTeams) {
          return _selectorField(
            hint: 'Đang tải team...',
            value: null,
            icon: Icons.group_outlined,
            onTap: () {},
            isLoading: true,
          );
        }

        final teams = org.availableTeams;
        if (teams.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 18),
                const SizedBox(width: 10),
                Text('Chưa có team. Sẽ được gán vào team chung.',
                    style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        // Validate selected team
        final validId = teams.any((t) => t.id == _selectedTeamId) ? _selectedTeamId : null;
        if (validId != _selectedTeamId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTeamId = validId);
          });
        }

        // Find team name for display
        final selectedTeam = validId != null
            ? teams.firstWhere((t) => t.id == validId, orElse: () => teams.first)
            : null;

        return _selectorField(
          hint: 'Chọn team',
          value: selectedTeam?.name,
          icon: Icons.group_outlined,
          onTap: () => _showTeamSheet(teams),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final name = _fullNameController.text.trim();
      if (name.isEmpty || _selectedDepartment == null) throw Exception('Vui lòng điền đủ thông tin');

      final teamId = _selectedTeamId ?? '${_selectedDepartment}__general';
      await auth.submitRoleAndDepartment(
        UserRole.employee,
        _selectedDepartment!,
        fullName: name,
        teamId: teamId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã gửi yêu cầu thành công. Vui lòng chờ phê duyệt.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ─── Custom Radio Dot widget ──────────────────────────────────────
class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2D2B6B);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? navy : Colors.grey.shade300,
          width: selected ? 0 : 1.5,
        ),
        color: selected ? navy : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
