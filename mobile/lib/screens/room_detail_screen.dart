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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: Text(
          _room.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2E7BE9),
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  text: 'Tổng quan',
                  icon: Icon(Icons.dashboard_outlined, size: 18),
                ),
                Tab(
                  text: 'Tiện ích',
                  icon: Icon(Icons.devices_outlined, size: 18),
                ),
                Tab(
                  text: 'Bảo trì',
                  icon: Icon(Icons.build_outlined, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAmenitiesTab(),
          _buildMaintenanceTab(),
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
          _buildModernHeaderCard(),
          const SizedBox(height: 16),
          _buildModernInfoGrid(),
          const SizedBox(height: 16),
          _buildModernLocationCard(),
          const SizedBox(height: 16),
          _buildModernQRCard(),
        ],
      ),
    );
  }

  Widget _buildModernHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7BE9),
            const Color(0xFF2E7BE9).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7BE9).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.meeting_room,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _room.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getRoomStatusColor(_room.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _room.statusText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_room.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _room.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (_room.needsMaintenance) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernInfoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin chi tiết',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildInfoCard(
              icon: Icons.people,
              title: 'Sức chứa',
              value: '${_room.capacity}',
              unit: 'người',
              color: Colors.blue,
            ),
            _buildInfoCard(
              icon: Icons.square_foot,
              title: 'Diện tích',
              value: _room.area.toStringAsFixed(1),
              unit: 'm²',
              color: Colors.green,
            ),
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Ngày tạo',
              value: '${_room.createdAt.day}/${_room.createdAt.month}',
              unit: '${_room.createdAt.year}',
              color: Colors.purple,
            ),
            if (_room.lastMaintenanceDate != null)
              _buildInfoCard(
                icon: Icons.build,
                title: 'Bảo trì cuối',
                value:
                    '${_room.lastMaintenanceDate!.day}/${_room.lastMaintenanceDate!.month}',
                unit: '${_room.lastMaintenanceDate!.year}',
                color: Colors.orange,
              )
            else
              _buildInfoCard(
                icon: Icons.new_releases,
                title: 'Trạng thái',
                value: 'Mới',
                unit: '',
                color: Colors.teal,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Vị trí',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_room.building.isNotEmpty)
            _buildLocationRow(
              icon: Icons.business,
              label: 'Tòa nhà',
              value: _room.building,
            ),
          if (_room.floor.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLocationRow(
              icon: Icons.layers,
              label: 'Tầng',
              value: _room.floor,
            ),
          ],
          if (_room.location.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLocationRow(
              icon: Icons.room,
              label: 'Vị trí',
              value: _room.location,
            ),
          ],
          if (_room.fullLocation.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                _room.fullLocation,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildModernQRCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'QR Code Check-in',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 40,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  _room.qrCode,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    );
  }

  Widget _buildOldInfoCard() {
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
          Text(
            'Tiện ích có sẵn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tất cả tiện ích được trang bị trong phòng',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (_room.amenities.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.devices_other,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có tiện ích nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thông tin tiện ích sẽ được cập nhật sau',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 4,
              ),
              itemCount: _room.amenities.length,
              itemBuilder: (context, index) {
                final amenity = _room.amenities[index];
                return _buildModernAmenityCard(amenity, index);
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

  Widget _buildModernAmenityCard(RoomAmenity amenity, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getAmenityIcon(amenity),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAmenityName(amenity),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAmenityDescription(amenity),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Có sẵn',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAmenityDescription(RoomAmenity amenity) {
    switch (amenity) {
      case RoomAmenity.projector:
        return 'Máy chiếu HD chất lượng cao';
      case RoomAmenity.whiteboard:
        return 'Bảng trắng viết marker';
      case RoomAmenity.wifi:
        return 'WiFi tốc độ cao miễn phí';
      case RoomAmenity.airConditioner:
        return 'Điều hòa nhiệt độ tự động';
      case RoomAmenity.microphone:
        return 'Hệ thống âm thanh chuyên nghiệp';
      case RoomAmenity.speaker:
        return 'Loa chất lượng cao';
      case RoomAmenity.camera:
        return 'Camera họp trực tuyến';
      case RoomAmenity.monitor:
        return 'Màn hình hiển thị lớn';
      case RoomAmenity.flipChart:
        return 'Bảng giấy di động';
      case RoomAmenity.waterDispenser:
        return 'Cây nước uống miễn phí';
      case RoomAmenity.powerOutlet:
        return 'Ổ cắm điện đầy đủ';
      case RoomAmenity.videoConference:
        return 'Hệ thống họp trực tuyến';
    }
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
                  Text(
                    'Lịch sử bảo trì',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
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
              const SizedBox(height: 8),
              Text(
                'Quản lý và theo dõi hoạt động bảo trì phòng họp',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
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
    final statusColor = _getMaintenanceStatusColor(record.status);
    final priorityColor = _getMaintenancePriorityColor(record.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với icon, title và status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMaintenanceTypeIcon(record.type),
                  color: priorityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getMaintenanceStatusText(record.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info grid
          Row(
            children: [
              Expanded(
                child: _buildMaintenanceInfoCard(
                  icon: Icons.person,
                  label: 'Kỹ thuật viên',
                  value: record.technician,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMaintenanceInfoCard(
                  icon: Icons.schedule,
                  label: 'Ngày lên lịch',
                  value:
                      '${record.scheduledDate.day}/${record.scheduledDate.month}/${record.scheduledDate.year}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          if (record.completedDate != null || record.cost > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (record.completedDate != null)
                  Expanded(
                    child: _buildMaintenanceInfoCard(
                      icon: Icons.check_circle,
                      label: 'Hoàn thành',
                      value:
                          '${record.completedDate!.day}/${record.completedDate!.month}/${record.completedDate!.year}',
                      color: Colors.green,
                    ),
                  ),
                if (record.completedDate != null && record.cost > 0)
                  const SizedBox(width: 12),
                if (record.cost > 0)
                  Expanded(
                    child: _buildMaintenanceInfoCard(
                      icon: Icons.attach_money,
                      label: 'Chi phí',
                      value: '${record.cost.toStringAsFixed(0)} VND',
                      color: Colors.purple,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
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
