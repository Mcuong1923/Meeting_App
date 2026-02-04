import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../utils/room_setup_helper.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({Key? key}) : super(key: key);

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isSetupCompleted = false;

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

  void _checkSetupStatus() async {
    final isCompleted = await RoomSetupHelper.isRoomsSetupCompleted();
    setState(() {
      _isSetupCompleted = isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Setup Phòng họp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabButton(
                  icon: Icons.flash_on,
                  label: 'Quick Setup',
                  isSelected: _tabController.index == 0,
                  onTap: () {
                    _tabController.animateTo(0);
                    setState(() {});
                  },
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  icon: Icons.widgets,
                  label: 'Templates',
                  isSelected: _tabController.index == 1,
                  onTap: () {
                    _tabController.animateTo(1);
                    setState(() {});
                  },
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  icon: Icons.settings,
                  label: 'Advanced',
                  isSelected: _tabController.index == 2,
                  onTap: () {
                    _tabController.animateTo(2);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickSetupTab(),
          _buildTemplatesTab(),
          _buildAdvancedTab(),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSetupStatusCard(),
          const SizedBox(height: 20),
          const Text(
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(),
          const SizedBox(height: 20),
          const Text(
            'Thông tin hệ thống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSystemInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSetupStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: _isSetupCompleted ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSetupCompleted ? Icons.check_circle : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSetupCompleted
                      ? 'Hệ thống đã được setup'
                      : 'Chưa setup phòng họp',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSetupCompleted
                      ? 'Phòng họp đã được cấu hình và sẵn sàng sử dụng'
                      : 'Hãy setup phòng họp mặc định để bắt đầu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                if (!_isSetupCompleted) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setupDefaultRooms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF9800),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Đang setup...' : 'Setup tự động',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          icon: Icons.add,
          title: 'Tạo phòng mới',
          subtitle: 'Thêm phòng từ đầu',
          color: const Color(0xFF2196F3),
          onTap: () => _navigateToAddRoom(),
        ),
        _buildActionCard(
          icon: Icons.copy_all,
          title: 'Sao chép phòng',
          subtitle: 'Copy từ phòng có sẵn',
          color: const Color(0xFF2196F3),
          onTap: () => _showCopyRoomDialog(),
        ),
        _buildActionCard(
          icon: Icons.upload,
          title: 'Import config',
          subtitle: 'Nhập từ file',
          color: const Color(0xFF00BCD4),
          onTap: () => _showImportDialog(),
        ),
        _buildActionCard(
          icon: Icons.download,
          title: 'Export config',
          subtitle: 'Xuất ra file',
          color: const Color(0xFF00BCD4),
          onTap: () => _exportConfig(),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.meeting_room,
                label: 'Tổng số phòng',
                value: '${roomProvider.totalRooms}',
                color: const Color(0xFF2196F3),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.check_circle,
                label: 'Phòng sẵn sàng',
                value: '${roomProvider.availableCount}',
                color: const Color(0xFF4CAF50),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.build,
                label: 'Phòng bảo trì',
                value: '${roomProvider.maintenanceCount}',
                color: const Color(0xFFFF5722),
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
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    final templates = RoomSetupHelper.getRoomTemplates();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn template phòng họp',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sử dụng template có sẵn để tạo phòng nhanh chóng',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(template);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _useTemplate(template),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      template['icon'],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTemplateChip(
                            Icons.people,
                            '${template['capacity']} người',
                          ),
                          _buildTemplateChip(
                            Icons.square_foot,
                            '${template['suggestedArea']} m²',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedActionsCard(),
          const SizedBox(height: 16),
          _buildMaintenanceSetupCard(),
          const SizedBox(height: 16),
          _buildDangerZoneCard(),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cấu hình nâng cao',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdvancedActionTile(
            icon: Icons.build,
            iconColor: const Color(0xFFFF9800),
            title: 'Setup lịch bảo trì mẫu',
            subtitle: 'Tạo dữ liệu bảo trì để demo',
            onTap: _setupSampleMaintenance,
          ),
          const Divider(height: 24),
          _buildAdvancedActionTile(
            icon: Icons.batch_prediction,
            iconColor: const Color(0xFF2196F3),
            title: 'Bulk import phòng',
            subtitle: 'Nhập nhiều phòng từ CSV/Excel',
            onTap: () => _showBulkImportDialog(),
          ),
          const Divider(height: 24),
          _buildAdvancedActionTile(
            icon: Icons.qr_code,
            iconColor: const Color(0xFF4CAF50),
            title: 'Tạo QR codes',
            subtitle: 'Tạo lại QR code cho tất cả phòng',
            onTap: _regenerateQRCodes,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSetupCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cấu hình bảo trì',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule, color: Color(0xFF9C27B0)),
            title: const Text('Chu kỳ bảo trì mặc định'),
            subtitle: const Text('3 tháng cho phòng thường, 1 tháng cho VIP'),
            trailing: const Text('Đã cấu hình', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications, color: Color(0xFFFF5722)),
            title: const Text('Thông báo bảo trì'),
            subtitle: const Text('Nhắc nhở trước 7 ngày'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Vùng nguy hiểm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showResetConfirmDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset tất cả phòng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Xóa tất cả phòng và bắt đầu lại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _setupDefaultRooms() async {
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
        context.read<RoomProvider>().loadRooms();
        context.read<RoomProvider>().loadMaintenanceRecords();
      }

      setState(() {
        _isSetupCompleted = true;
      });

      _showSnackBar('✅ Đã setup thành công 6 phòng mặc định!');
    } catch (e) {
      _showSnackBar('❌ Lỗi setup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _setupSampleMaintenance() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    try {
      await RoomSetupHelper.setupSampleMaintenanceRecords(currentUser);
      if (mounted) {
        context.read<RoomProvider>().loadMaintenanceRecords();
      }
      _showSnackBar('✅ Đã tạo dữ liệu bảo trì mẫu');
    } catch (e) {
      _showSnackBar('❌ Lỗi: $e');
    }
  }

  void _showBulkImportDialog() {
    _showSnackBar('Chức năng đang phát triển');
  }

  void _regenerateQRCodes() {
    _showSnackBar('Chức năng đang phát triển');
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận reset'),
        content: const Text(
          'Bạn có chắc muốn xóa TẤT CẢ phòng và dữ liệu bảo trì?\n\nHành động này KHÔNG THỂ hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAllRooms();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('XÓA TẤT CẢ'),
          ),
        ],
      ),
    );
  }

  void _resetAllRooms() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    try {
      await RoomSetupHelper.resetAllRooms(currentUser);
      if (mounted) {
        context.read<RoomProvider>().loadRooms();
        context.read<RoomProvider>().loadMaintenanceRecords();
      }
      setState(() {
        _isSetupCompleted = false;
      });
      _showSnackBar('✅ Đã reset tất cả phòng');
    } catch (e) {
      _showSnackBar('❌ Lỗi reset: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
