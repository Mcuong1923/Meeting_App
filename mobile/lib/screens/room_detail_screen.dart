import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;

  const RoomDetailScreen({Key? key, required this.room}) : super(key: key);

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RoomModel _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _tabController = TabController(length: 3, vsync: this);
    _loadMaintenanceRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMaintenanceRecords() {
    context.read<RoomProvider>().loadMaintenanceRecords(roomId: _room.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAmenitiesTab(),
                _buildMaintenanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _room.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
            ),
          ),
          child: _room.photoUrl.isNotEmpty
              ? Image.network(
                  _room.photoUrl,
                  fit: BoxFit.cover,
                )
              : Container(
                  child: Icon(
                    Icons.meeting_room,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Tổng quan', icon: Icon(Icons.info, size: 20)),
          Tab(text: 'Tiện ích', icon: Icon(Icons.devices, size: 20)),
          Tab(text: 'Bảo trì', icon: Icon(Icons.build, size: 20)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildQRCodeCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getRoomStatusColor(_room.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trạng thái: ${_room.statusText}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_room.description.isNotEmpty)
              Text(
                _room.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            if (_room.needsMaintenance) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Phòng cần bảo trì',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin chi tiết',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.people,
              label: 'Sức chứa',
              value: '${_room.capacity} người',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.square_foot,
              label: 'Diện tích',
              value: '${_room.area.toStringAsFixed(1)} m²',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tạo',
              value:
                  '${_room.createdAt.day}/${_room.createdAt.month}/${_room.createdAt.year}',
            ),
            if (_room.lastMaintenanceDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.build,
                label: 'Bảo trì lần cuối',
                value:
                    '${_room.lastMaintenanceDate!.day}/${_room.lastMaintenanceDate!.month}/${_room.lastMaintenanceDate!.year}',
              ),
            ],
            if (_room.nextMaintenanceDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.schedule,
                label: 'Bảo trì tiếp theo',
                value:
                    '${_room.nextMaintenanceDate!.day}/${_room.nextMaintenanceDate!.month}/${_room.nextMaintenanceDate!.year}',
                valueColor: _room.needsMaintenance ? Colors.orange : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vị trí',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_room.building.isNotEmpty)
              _buildInfoRow(
                icon: Icons.business,
                label: 'Tòa nhà',
                value: _room.building,
              ),
            if (_room.floor.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.layers,
                label: 'Tầng',
                value: _room.floor,
              ),
            ],
            if (_room.location.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Vị trí cụ thể',
                value: _room.location,
              ),
            ],
            if (_room.fullLocation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _room.fullLocation,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code,
                      size: 60,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _room.qrCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quét mã QR để check-in nhanh vào phòng này',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích có sẵn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_room.amenities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tiện ích nào được cập nhật',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
              ),
              itemCount: _room.amenities.length,
              itemBuilder: (context, index) {
                final amenity = _room.amenities[index];
                return _buildAmenityCard(amenity);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAmenityCard(RoomAmenity amenity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getAmenityIcon(amenity),
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getAmenityName(amenity),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(RoomAmenity amenity) {
    switch (amenity) {
      case RoomAmenity.projector:
        return Icons.slideshow;
      case RoomAmenity.whiteboard:
        return Icons.dashboard;
      case RoomAmenity.wifi:
        return Icons.wifi;
      case RoomAmenity.airConditioner:
        return Icons.ac_unit;
      case RoomAmenity.microphone:
        return Icons.mic;
      case RoomAmenity.speaker:
        return Icons.speaker;
      case RoomAmenity.camera:
        return Icons.camera_alt;
      case RoomAmenity.monitor:
        return Icons.monitor;
      case RoomAmenity.flipChart:
        return Icons.flip_to_front;
      case RoomAmenity.waterDispenser:
        return Icons.water_drop;
      case RoomAmenity.powerOutlet:
        return Icons.power;
      case RoomAmenity.videoConference:
        return Icons.video_call;
    }
  }

  String _getAmenityName(RoomAmenity amenity) {
    switch (amenity) {
      case RoomAmenity.projector:
        return 'Máy chiếu';
      case RoomAmenity.whiteboard:
        return 'Bảng trắng';
      case RoomAmenity.wifi:
        return 'WiFi';
      case RoomAmenity.airConditioner:
        return 'Điều hòa';
      case RoomAmenity.microphone:
        return 'Micro';
      case RoomAmenity.speaker:
        return 'Loa';
      case RoomAmenity.camera:
        return 'Camera';
      case RoomAmenity.monitor:
        return 'Màn hình';
      case RoomAmenity.flipChart:
        return 'Bảng giấy';
      case RoomAmenity.waterDispenser:
        return 'Cây nước';
      case RoomAmenity.powerOutlet:
        return 'Ổ cắm điện';
      case RoomAmenity.videoConference:
        return 'Họp online';
    }
  }

  Widget _buildMaintenanceTab() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        final maintenanceRecords = roomProvider.maintenanceRecords
            .where((record) => record.roomId == _room.id)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Lịch sử bảo trì',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.userModel?.isAdmin == true ||
                          authProvider.userModel?.isDirector == true) {
                        return ElevatedButton.icon(
                          onPressed: () => _showAddMaintenanceDialog(),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Thêm lịch'),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (maintenanceRecords.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.build_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có lịch sử bảo trì',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: maintenanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = maintenanceRecords[index];
                    return _buildMaintenanceCard(record);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceCard(MaintenanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getMaintenancePriorityColor(record.priority)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMaintenanceTypeIcon(record.type),
                    color: _getMaintenancePriorityColor(record.priority),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMaintenanceStatusColor(record.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMaintenanceStatusText(record.status),
                    style: TextStyle(
                      color: _getMaintenanceStatusColor(record.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  record.technician,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${record.scheduledDate.day}/${record.scheduledDate.month}/${record.scheduledDate.year}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            if (record.completedDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Hoàn thành: ${record.completedDate!.day}/${record.completedDate!.month}/${record.completedDate!.year}',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ],
            if (record.cost > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Chi phí: ${record.cost.toStringAsFixed(0)} VND',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoomStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.orange;
      case RoomStatus.maintenance:
        return Colors.red;
      case RoomStatus.disabled:
        return Colors.grey;
    }
  }

  Color _getMaintenancePriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.urgent:
        return Colors.purple;
    }
  }

  IconData _getMaintenanceTypeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.routine:
        return Icons.schedule;
      case MaintenanceType.repair:
        return Icons.build;
      case MaintenanceType.upgrade:
        return Icons.upgrade;
      case MaintenanceType.cleaning:
        return Icons.cleaning_services;
      case MaintenanceType.inspection:
        return Icons.search;
    }
  }

  Color _getMaintenanceStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMaintenanceStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Đã lên lịch';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  void _showAddMaintenanceDialog() {
    // TODO: Implement add maintenance dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }
}
