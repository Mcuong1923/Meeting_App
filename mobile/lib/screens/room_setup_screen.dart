import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../utils/room_setup_helper.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({Key? key}) : super(key: key);

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen>
    with SingleTickerProviderStateMixin {
  static const Color _pageBackground = Color(0xFFF4F7FB);
  static const Color _surfaceColor = Colors.white;
  static const Color _titleColor = Color(0xFF0F172A);
  static const Color _bodyColor = Color(0xFF4B5563);
  static const Color _mutedColor = Color(0xFF7B8AA0);
  static const Color _borderColor = Color(0xFFD9E2EC);
  static const Color _primaryBlue = Color(0xFF2A8CFF);
  static const Color _primaryBlueSoft = Color(0xFFEAF3FF);
  static const Color _success = Color(0xFF22C55E);
  static const Color _successSoft = Color(0xFFE9F8EE);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _warningSoft = Color(0xFFFFF5DE);
  static const Color _cyan = Color(0xFF0EA5C6);
  static const Color _cyanSoft = Color(0xFFE8FAFD);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerSoft = Color(0xFFFFECEB);

  late final TabController _tabController;
  bool _isLoading = false;
  bool _isSetupCompleted = false;
  bool _maintenanceNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkSetupStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabPressed(int index) {
    if (_tabController.index == index) {
      return;
    }
    _tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _checkSetupStatus() async {
    final isCompleted = await RoomSetupHelper.isRoomsSetupCompleted();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSetupCompleted = isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        foregroundColor: _titleColor,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
          child: Material(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
            ),
          ),
        ),
        title: const Text(
          'Setup Phòng họp',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _titleColor,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlow(
            alignment: Alignment.topRight,
            offset: const Offset(110, -90),
            size: 220,
            colors: const [Color(0x1F2A8CFF), Color(0x002A8CFF)],
          ),
          _buildBackgroundGlow(
            alignment: Alignment.topLeft,
            offset: const Offset(-120, 220),
            size: 240,
            colors: const [Color(0x140EA5C6), Color(0x000EA5C6)],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _buildTabSelector(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildQuickSetupTab(),
                    _buildTemplatesTab(),
                    _buildAdvancedTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow({
    required Alignment alignment,
    required Offset offset,
    required double size,
    required List<Color> colors,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E0F172A),
                blurRadius: 18,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTabButton(
                index: 0,
                icon: Icons.bolt_rounded,
                label: 'Quick Setup',
              ),
              _buildTabButton(
                index: 1,
                icon: Icons.grid_view_rounded,
                label: 'Templates',
              ),
              _buildTabButton(
                index: 2,
                icon: Icons.settings_rounded,
                label: 'Advanced',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? _surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onTabPressed(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? _primaryBlue : _mutedColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? _primaryBlue : _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSetupStatusCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Thao tác nhanh'),
          const SizedBox(height: 14),
          _buildQuickActionsGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('Thông tin hệ thống'),
          const SizedBox(height: 14),
          _buildSystemInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _titleColor,
      ),
    );
  }

  Widget _buildSetupStatusCard() {
    final cardColor = _isSetupCompleted ? _successSoft : _warningSoft;
    final borderColor = _isSetupCompleted
        ? _success.withOpacity(0.25)
        : _warning.withOpacity(0.28);
    final titleColor =
        _isSetupCompleted ? const Color(0xFF11643E) : const Color(0xFF9A6600);
    final subtitleColor =
        _isSetupCompleted ? const Color(0xFF257A4D) : const Color(0xFF966E16);
    final accentColor = _isSetupCompleted ? _success : _warning;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSetupCompleted
                  ? Icons.check_rounded
                  : Icons.priority_high_rounded,
              size: 32,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSetupCompleted
                      ? 'Hệ thống đã được setup'
                      : 'Chưa setup phòng họp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSetupCompleted
                      ? 'Phòng họp đã được cấu hình và sẵn sàng sử dụng'
                      : 'Thiết lập nhanh danh sách phòng mặc định để bắt đầu sử dụng',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    height: 1.45,
                  ),
                ),
                if (!_isSetupCompleted) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setupDefaultRooms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Đang setup...' : 'Setup tự động',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    const actions = [
      _QuickActionData(
        icon: Icons.add_rounded,
        title: 'Tạo phòng mới',
        subtitle: 'Thêm phòng từ đầu',
        iconColor: _primaryBlue,
        iconBackground: _primaryBlueSoft,
      ),
      _QuickActionData(
        icon: Icons.content_copy_rounded,
        title: 'Sao chép phòng',
        subtitle: 'Copy từ phòng có sẵn',
        iconColor: _primaryBlue,
        iconBackground: _primaryBlueSoft,
      ),
      _QuickActionData(
        icon: Icons.upload_rounded,
        title: 'Import config',
        subtitle: 'Nhập từ file',
        iconColor: _cyan,
        iconBackground: _cyanSoft,
      ),
      _QuickActionData(
        icon: Icons.download_rounded,
        title: 'Export config',
        subtitle: 'Xuất ra file',
        iconColor: _cyan,
        iconBackground: _cyanSoft,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 164,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        late final VoidCallback onTap;
        if (index == 0) {
          onTap = _navigateToAddRoom;
        } else if (index == 1) {
          onTap = _showCopyRoomDialog;
        } else if (index == 2) {
          onTap = _showImportDialog;
        } else {
          onTap = _exportConfig;
        }

        return _buildActionCard(action: action, onTap: onTap);
      },
    );
  }

  Widget _buildActionCard({
    required _QuickActionData action,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: action.iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    color: action.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _mutedColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B0F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.meeting_room_outlined,
                label: 'Tổng số phòng',
                value: '${roomProvider.totalRooms}',
                iconColor: _primaryBlue,
                valueColor: _titleColor,
              ),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.check_circle_rounded,
                label: 'Phòng sẵn sàng',
                value: '${roomProvider.availableCount}',
                iconColor: _success,
                valueColor: _titleColor,
              ),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.build_rounded,
                label: 'Phòng bảo trì',
                value: '${roomProvider.maintenanceCount}',
                iconColor: const Color(0xFFF97316),
                valueColor: _titleColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: _borderColor.withOpacity(0.7),
    );
  }

  Widget _buildTemplatesTab() {
    final templates = RoomSetupHelper.getRoomTemplates();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: _primaryBlue,
            iconBackground: _primaryBlueSoft,
            title: 'Chọn template phòng họp',
            subtitle:
                'Dùng mẫu có sẵn để setup nhanh phòng tiêu chuẩn, phòng họp lớn hoặc không gian đào tạo.',
          ),
          const SizedBox(height: 18),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return _buildTemplateCard(templates[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, int index) {
    const accentPairs = [
      _AccentPair(accent: _primaryBlue, background: _primaryBlueSoft),
      _AccentPair(accent: _success, background: _successSoft),
      _AccentPair(accent: _cyan, background: _cyanSoft),
      _AccentPair(
        accent: Color(0xFF8B5CF6),
        background: Color(0xFFF0EAFE),
      ),
    ];
    final accentPair = accentPairs[index % accentPairs.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _useTemplate(template),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentPair.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '${template['icon']}',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${template['name']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${template['description']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _bodyColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTemplateChip(
                            icon: Icons.people_alt_rounded,
                            label: '${template['capacity']} người',
                            color: accentPair.accent,
                            background: accentPair.background,
                          ),
                          _buildTemplateChip(
                            icon: Icons.square_foot_rounded,
                            label: '${template['suggestedArea']} m²',
                            color: accentPair.accent,
                            background: accentPair.background,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: accentPair.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroCard(
            icon: Icons.tune_rounded,
            iconColor: _cyan,
            iconBackground: _cyanSoft,
            title: 'Cấu hình nâng cao',
            subtitle:
                'Thiết lập dữ liệu mẫu, import số lượng lớn và điều chỉnh các tuỳ chọn vận hành.',
          ),
          const SizedBox(height: 18),
          _buildAdvancedActionsCard(),
          const SizedBox(height: 16),
          _buildMaintenanceSetupCard(),
          const SizedBox(height: 16),
          _buildDangerZoneCard(),
        ],
      ),
    );
  }

  Widget _buildIntroCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _bodyColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionsCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cấu hình nâng cao'),
          const SizedBox(height: 16),
          _buildAdvancedActionTile(
            icon: Icons.build_circle_rounded,
            iconColor: _warning,
            iconBackground: _warningSoft,
            title: 'Setup lịch bảo trì mẫu',
            subtitle: 'Tạo dữ liệu bảo trì để demo nhanh trạng thái hệ thống',
            onTap: _setupSampleMaintenance,
          ),
          _buildDivider(),
          _buildAdvancedActionTile(
            icon: Icons.table_rows_rounded,
            iconColor: _primaryBlue,
            iconBackground: _primaryBlueSoft,
            title: 'Bulk import phòng',
            subtitle: 'Nhập nhiều phòng từ CSV hoặc Excel',
            onTap: _showBulkImportDialog,
          ),
          _buildDivider(),
          _buildAdvancedActionTile(
            icon: Icons.qr_code_rounded,
            iconColor: _success,
            iconBackground: _successSoft,
            title: 'Tạo lại QR code',
            subtitle: 'Sinh lại QR code cho toàn bộ phòng họp',
            onTap: _regenerateQRCodes,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _mutedColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceSetupCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cấu hình bảo trì'),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBackground: const Color(0xFFF0EAFE),
            title: 'Chu kỳ bảo trì mặc định',
            subtitle: '3 tháng cho phòng thường, 1 tháng cho phòng VIP',
            trailing: const Text(
              'Đã cấu hình',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _success,
              ),
            ),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.notifications_active_rounded,
            iconColor: _danger,
            iconBackground: _dangerSoft,
            title: 'Thông báo bảo trì',
            subtitle: 'Nhắc nhở trước 7 ngày',
            trailing: Switch.adaptive(
              value: _maintenanceNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _maintenanceNotificationsEnabled = value;
                });
              },
              activeColor: _primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _mutedColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _danger.withOpacity(0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD9D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vùng nguy hiểm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xoá toàn bộ dữ liệu phòng và tạo lại từ đầu.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _bodyColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showResetConfirmDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                side: BorderSide(color: _danger.withOpacity(0.28)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Reset tất cả phòng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _setupDefaultRooms() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      _showSnackBar('Vui lòng đăng nhập');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await RoomSetupHelper.setupDefaultRooms(currentUser);
      await RoomSetupHelper.setupSampleMaintenanceRecords(currentUser);

      if (mounted) {
        await context.read<RoomProvider>().loadRooms();
        await context.read<RoomProvider>().loadMaintenanceRecords();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSetupCompleted = true;
      });

      _showSnackBar('Đã setup thành công 6 phòng mặc định.');
    } catch (e) {
      _showSnackBar('Lỗi setup: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddRoom() {
    Navigator.pushNamed(context, '/add-room');
  }

  void _useTemplate(Map<String, dynamic> template) {
    _showSnackBar('Chức năng đang phát triển: ${template['name']}');
  }

  void _showCopyRoomDialog() {
    _showSnackBar('Chức năng đang phát triển');
  }

  void _showImportDialog() {
    _showSnackBar('Chức năng đang phát triển');
  }

  void _exportConfig() {
    _showSnackBar('Chức năng đang phát triển');
  }

  Future<void> _setupSampleMaintenance() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      return;
    }

    try {
      await RoomSetupHelper.setupSampleMaintenanceRecords(currentUser);
      if (mounted) {
        await context.read<RoomProvider>().loadMaintenanceRecords();
      }
      _showSnackBar('Đã tạo dữ liệu bảo trì mẫu.');
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    }
  }

  void _showBulkImportDialog() {
    _showSnackBar('Chức năng đang phát triển');
  }

  void _regenerateQRCodes() {
    _showSnackBar('Chức năng đang phát triển');
  }

  void _showResetConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Xác nhận reset',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Bạn có chắc muốn xoá toàn bộ phòng và dữ liệu bảo trì?\n\nHành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resetAllRooms();
              },
              style: TextButton.styleFrom(foregroundColor: _danger),
              child: const Text(
                'Xoá tất cả',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllRooms() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      return;
    }

    try {
      await RoomSetupHelper.resetAllRooms(currentUser);
      if (mounted) {
        await context.read<RoomProvider>().loadRooms();
        await context.read<RoomProvider>().loadMaintenanceRecords();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSetupCompleted = false;
      });
      _showSnackBar('Đã reset toàn bộ phòng.');
    } catch (e) {
      _showSnackBar('Lỗi reset: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
  });
}

class _AccentPair {
  final Color accent;
  final Color background;

  const _AccentPair({
    required this.accent,
    required this.background,
  });
}
