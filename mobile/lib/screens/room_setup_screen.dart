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
      appBar: AppBar(
        title: const Text('Setup Phòng họp'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Quick Setup', icon: Icon(Icons.flash_on, size: 20)),
            Tab(text: 'Templates', icon: Icon(Icons.widgets, size: 20)),
            Tab(text: 'Advanced', icon: Icon(Icons.settings, size: 20)),
          ],
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

  Widget _buildQuickSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSetupStatusCard(),
          const SizedBox(height: 24),
          _buildQuickActionsCard(),
          const SizedBox(height: 24),
          _buildSystemInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSetupStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSetupCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isSetupCompleted ? Icons.check_circle : Icons.warning,
                    color: _isSetupCompleted ? Colors.green : Colors.orange,
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSetupCompleted
                            ? 'Phòng họp đã được cấu hình và sẵn sàng sử dụng'
                            : 'Hãy setup phòng họp mặc định để bắt đầu',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isSetupCompleted) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _setupDefaultRooms,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_isLoading ? 'Đang setup...' : 'Setup tự động'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thao tác nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildActionTile(
                  icon: Icons.add_business,
                  title: 'Tạo phòng mới',
                  subtitle: 'Thêm phòng từ đầu',
                  color: Colors.blue,
                  onTap: () => _navigateToAddRoom(),
                ),
                _buildActionTile(
                  icon: Icons.copy,
                  title: 'Sao chép phòng',
                  subtitle: 'Copy từ phòng có sẵn',
                  color: Colors.green,
                  onTap: () => _showCopyRoomDialog(),
                ),
                _buildActionTile(
                  icon: Icons.upload_file,
                  title: 'Import config',
                  subtitle: 'Nhập từ file',
                  color: Colors.orange,
                  onTap: () => _showImportDialog(),
                ),
                _buildActionTile(
                  icon: Icons.download,
                  title: 'Export config',
                  subtitle: 'Xuất ra file',
                  color: Colors.purple,
                  onTap: () => _exportConfig(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin hệ thống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<RoomProvider>(
              builder: (context, roomProvider, child) {
                return Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.meeting_room,
                      label: 'Tổng số phòng',
                      value: '${roomProvider.totalRooms}',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.check_circle,
                      label: 'Phòng sẵn sàng',
                      value: '${roomProvider.availableCount}',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.build,
                      label: 'Phòng bảo trì',
                      value: '${roomProvider.maintenanceCount}',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.analytics,
                      label: 'Tỷ lệ sử dụng',
                      value:
                          '${roomProvider.occupancyRate.toStringAsFixed(1)}%',
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sử dụng template có sẵn để tạo phòng nhanh chóng',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        template['icon'],
                        style: const TextStyle(fontSize: 24),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template['description'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTemplateSpec(
                    icon: Icons.people,
                    value: '${template['capacity']} người',
                  ),
                  const SizedBox(width: 16),
                  _buildTemplateSpec(
                    icon: Icons.square_foot,
                    value: '${template['suggestedArea']} m²',
                  ),
                  const SizedBox(width: 16),
                  _buildTemplateSpec(
                    icon: Icons.devices,
                    value: '${(template['amenities'] as List).length} tiện ích',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSpec({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedActionsCard(),
          const SizedBox(height: 24),
          _buildMaintenanceSetupCard(),
          const SizedBox(height: 24),
          _buildDangerZoneCard(),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấu hình nâng cao',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.build, color: Colors.orange),
              title: const Text('Setup lịch bảo trì mẫu'),
              subtitle: const Text('Tạo dữ liệu bảo trì để demo'),
              onTap: _setupSampleMaintenance,
            ),
            ListTile(
              leading: const Icon(Icons.batch_prediction, color: Colors.blue),
              title: const Text('Bulk import phòng'),
              subtitle: const Text('Nhập nhiều phòng từ CSV/Excel'),
              onTap: () => _showBulkImportDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.green),
              title: const Text('Tạo QR codes'),
              subtitle: const Text('Tạo lại QR code cho tất cả phòng'),
              onTap: _regenerateQRCodes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSetupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấu hình bảo trì',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.purple),
              title: const Text('Chu kỳ bảo trì mặc định'),
              subtitle: const Text('3 tháng cho phòng thường, 1 tháng cho VIP'),
              trailing: const Text('Đã cấu hình'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.red),
              title: const Text('Thông báo bảo trì'),
              subtitle: const Text('Nhắc nhở trước 7 ngày'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement notification settings
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  'Vùng nguy hiểm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
              title: Text(
                'Reset tất cả phòng',
                style: TextStyle(color: Colors.red.shade600),
              ),
              subtitle: const Text('Xóa tất cả phòng và bắt đầu lại'),
              onTap: _showResetConfirmDialog,
            ),
          ],
        ),
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

      // Reload data
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
    // TODO: Navigate to add room with template data
    _showSnackBar('Chức năng đang phát triển: ${template['name']}');
  }

  void _showCopyRoomDialog() {
    // TODO: Show dialog to select room to copy
    _showSnackBar('Chức năng đang phát triển');
  }

  void _showImportDialog() {
    // TODO: Show import dialog
    _showSnackBar('Chức năng đang phát triển');
  }

  void _exportConfig() {
    // TODO: Export rooms config
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
        SnackBar(content: Text(message)),
      );
    }
  }
}
