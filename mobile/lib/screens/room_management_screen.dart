import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import 'room_detail_screen.dart';
import 'add_edit_room_screen.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  RoomStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadRooms();
      context.read<RoomProvider>().loadMaintenanceRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Phòng họp'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddRoom(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Tất cả', icon: Icon(Icons.meeting_room, size: 20)),
            Tab(text: 'Bảo trì', icon: Icon(Icons.build, size: 20)),
            Tab(text: 'Thống kê', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: Consumer2<RoomProvider, AuthProvider>(
        builder: (context, roomProvider, authProvider, child) {
          if (roomProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (roomProvider.error.isNotEmpty) {
            return _buildErrorWidget(roomProvider.error);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(roomProvider),
              _buildAllRoomsTab(roomProvider, authProvider.userModel),
              _buildMaintenanceTab(roomProvider, authProvider.userModel),
              _buildStatisticsTab(roomProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(RoomProvider roomProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCards(roomProvider),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentActivity(roomProvider),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(RoomProvider roomProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê tổng quan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Tổng phòng',
                value: roomProvider.totalRooms.toString(),
                icon: Icons.meeting_room,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Sẵn sàng',
                value: roomProvider.availableCount.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Đang sử dụng',
                value: roomProvider.occupiedCount.toString(),
                icon: Icons.people,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Bảo trì',
                value: roomProvider.maintenanceCount.toString(),
                icon: Icons.build,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Tỷ lệ sử dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${roomProvider.occupancyRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Thêm phòng',
                subtitle: 'Tạo phòng họp mới',
                icon: Icons.add_business,
                color: Colors.blue,
                onTap: () => _navigateToAddRoom(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Lịch bảo trì',
                subtitle: 'Xem lịch bảo trì',
                icon: Icons.schedule,
                color: Colors.green,
                onTap: () => _tabController.animateTo(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(RoomProvider roomProvider) {
    final needMaintenanceRooms = roomProvider.roomsNeedMaintenance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cần chú ý',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (needMaintenanceRooms.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tất cả phòng đều trong tình trạng tốt',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...needMaintenanceRooms.take(3).map((room) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Cần bảo trì',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToRoomDetail(context, room),
                      child: const Text('Xem'),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildAllRoomsTab(RoomProvider roomProvider, UserModel? currentUser) {
    return Column(
      children: [
        _buildSearchAndFilter(roomProvider),
        Expanded(
          child: _buildRoomsList(roomProvider, currentUser),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(RoomProvider roomProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm phòng...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', null),
                const SizedBox(width: 8),
                _buildFilterChip('Sẵn sàng', RoomStatus.available),
                const SizedBox(width: 8),
                _buildFilterChip('Đang sử dụng', RoomStatus.occupied),
                const SizedBox(width: 8),
                _buildFilterChip('Bảo trì', RoomStatus.maintenance),
                const SizedBox(width: 8),
                _buildFilterChip('Tạm ngưng', RoomStatus.disabled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RoomStatus? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildRoomsList(RoomProvider roomProvider, UserModel? currentUser) {
    List<RoomModel> filteredRooms = roomProvider.searchRooms(
      keyword: _searchQuery,
      status: _filterStatus,
    );

    if (filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy phòng nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        return _buildRoomCard(room, currentUser);
      },
    );
  }

  Widget _buildRoomCard(RoomModel room, UserModel? currentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToRoomDetail(context, room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getRoomStatusColor(room.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (currentUser?.isAdmin == true ||
                      currentUser?.isDirector == true)
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleRoomAction(value, room, currentUser!),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 20),
                              SizedBox(width: 8),
                              Text('Đổi trạng thái'),
                            ],
                          ),
                        ),
                        if (currentUser?.isAdmin == true)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    room.fullLocation,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoomStatusColor(room.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.statusText,
                      style: TextStyle(
                        color: _getRoomStatusColor(room.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${room.capacity} người',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.square_foot,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${room.area.toStringAsFixed(0)} m²',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (room.amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: room.amenityNames
                      .take(3)
                      .map((amenity) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 10,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (room.needsMaintenance) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Cần bảo trì',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
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

  Widget _buildMaintenanceTab(
      RoomProvider roomProvider, UserModel? currentUser) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch sử bảo trì',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMaintenanceDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Thêm lịch'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildMaintenanceList(roomProvider),
        ),
      ],
    );
  }

  Widget _buildMaintenanceList(RoomProvider roomProvider) {
    if (roomProvider.maintenanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch bảo trì nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roomProvider.maintenanceRecords.length,
      itemBuilder: (context, index) {
        final record = roomProvider.maintenanceRecords[index];
        final room = roomProvider.getRoomById(record.roomId);
        return _buildMaintenanceCard(record, room);
      },
    );
  }

  Widget _buildMaintenanceCard(MaintenanceRecord record, RoomModel? room) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (room != null)
                        Text(
                          room.name,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                    ],
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
            const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
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

  Widget _buildStatisticsTab(RoomProvider roomProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê chi tiết',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailedStatistics(roomProvider),
        ],
      ),
    );
  }

  Widget _buildDetailedStatistics(RoomProvider roomProvider) {
    return Column(
      children: [
        _buildStatCard(
          title: 'Tổng số phòng',
          value: roomProvider.totalRooms.toString(),
          icon: Icons.meeting_room,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Phòng sẵn sàng',
          value: roomProvider.availableCount.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Phòng đang sử dụng',
          value: roomProvider.occupiedCount.toString(),
          icon: Icons.people,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Phòng bảo trì',
          value: roomProvider.maintenanceCount.toString(),
          icon: Icons.build,
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Phòng tạm ngưng',
          value: roomProvider.disabledCount.toString(),
          icon: Icons.block,
          color: Colors.grey,
        ),
      ],
    );
  }

  void _handleRoomAction(String action, RoomModel room, UserModel currentUser) {
    switch (action) {
      case 'edit':
        _navigateToEditRoom(context, room);
        break;
      case 'status':
        _showChangeStatusDialog(context, room, currentUser);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, room, currentUser);
        break;
    }
  }

  void _navigateToAddRoom(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditRoomScreen(),
      ),
    );
  }

  void _navigateToEditRoom(BuildContext context, RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRoomScreen(room: room),
      ),
    );
  }

  void _navigateToRoomDetail(BuildContext context, RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(room: room),
      ),
    );
  }

  void _showChangeStatusDialog(
      BuildContext context, RoomModel room, UserModel currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thay đổi trạng thái - ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoomStatus.values
              .map((status) => ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getRoomStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(_getRoomStatusText(status)),
                    onTap: () {
                      Navigator.pop(context);
                      _changeRoomStatus(room.id, status, currentUser);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  String _getRoomStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Sẵn sàng';
      case RoomStatus.occupied:
        return 'Đang sử dụng';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.disabled:
        return 'Tạm ngưng';
    }
  }

  void _showDeleteConfirmDialog(
      BuildContext context, RoomModel room, UserModel currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa phòng "${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(room.id, currentUser);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showAddMaintenanceDialog(BuildContext context) {
    // TODO: Implement add maintenance dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _changeRoomStatus(
      String roomId, RoomStatus newStatus, UserModel currentUser) async {
    try {
      await context
          .read<RoomProvider>()
          .changeRoomStatus(roomId, newStatus, currentUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thay đổi trạng thái phòng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _deleteRoom(String roomId, UserModel currentUser) async {
    try {
      await context.read<RoomProvider>().deleteRoom(roomId, currentUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa phòng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
