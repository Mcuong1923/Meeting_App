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
  TabController? _tabController;
  String _searchQuery = '';
  RoomStatus? _filterStatus;
  List<RoomAmenity> _selectedAmenities = [];
  int? _minCapacity;
  int? _maxCapacity;
  String? _selectedBuilding;
  String? _selectedFloor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.1),
        bottom: _tabController != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController!,
                    indicator: BoxDecoration(
                      color: const Color(0xFF2E7BE9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    tabAlignment: TabAlignment.fill,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                          text: 'Tổng quan',
                          icon: Icon(Icons.dashboard_outlined, size: 18)),
                      Tab(
                          text: 'Tất cả',
                          icon: Icon(Icons.meeting_room_outlined, size: 18)),
                      Tab(
                          text: 'Bảo trì',
                          icon: Icon(Icons.build_outlined, size: 18)),
                      Tab(
                          text: 'Thống kê',
                          icon: Icon(Icons.analytics_outlined, size: 18)),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Consumer2<RoomProvider, AuthProvider>(
        builder: (context, roomProvider, authProvider, child) {
          if (roomProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (roomProvider.error.isNotEmpty) {
            return _buildErrorWidget(roomProvider.error);
          }

          return _tabController != null
              ? TabBarView(
                  controller: _tabController!,
                  children: [
                    _buildOverviewTab(roomProvider),
                    _buildAllRoomsTab(roomProvider, authProvider.userModel),
                    _buildMaintenanceTab(roomProvider, authProvider.userModel),
                    _buildStatisticsTab(roomProvider),
                  ],
                )
              : const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddRoom(context),
        backgroundColor: const Color(0xFF2E7BE9),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
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
          // Statistics Cards
          _buildStatisticsCards(roomProvider),
          const SizedBox(height: 24),

          // Available Rooms Section
          _buildAvailableRoomsSection(roomProvider),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(roomProvider),
        ],
      ),
    );
  }

  Widget _buildAvailableRoomsSection(RoomProvider roomProvider) {
    final availableRooms = roomProvider.rooms
        .where((room) => room.status == RoomStatus.available && room.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Phòng trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController?.animateTo(1); // Switch to "Tất cả" tab
              },
              child: Text(
                'xem tất cả',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rooms Grid with new project-style design
        if (availableRooms.isEmpty)
          _buildEmptyRoomsState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: availableRooms.length > 4 ? 4 : availableRooms.length,
            itemBuilder: (context, index) {
              final room = availableRooms[index];
              return _buildProjectStyleRoomCard(room, index);
            },
          ),
      ],
    );
  }

  Widget _buildProjectStyleRoomCard(RoomModel room, int index) {
    // Color schemes theo design trong hình
    final colors = [
      {
        'bg': const Color(0xFF4A5FE7),
        'light': const Color(0xFFE8EBFF)
      }, // Dark blue (A2-302)
      {
        'bg': const Color(0xFF9E9E9E),
        'light': const Color(0xFFF5F5F5)
      }, // Gray (Phòng Họp A1)
      {
        'bg': const Color(0xFFFF9F43),
        'light': const Color(0xFFFFF3E0)
      }, // Orange (Phòng họp A1)
      {
        'bg': const Color(0xFF66BB6A),
        'light': const Color(0xFFE8F5E8)
      }, // Green (Phòng họp B1)
    ];

    final colorScheme = colors[index % colors.length];
    final usageRate = _calculateUsageRate(room);
    final isFirstCard = index == 0;

    return GestureDetector(
      onTap: () => _navigateToRoomDetail(context, room),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFirstCard ? colorScheme['bg'] : Colors.white,
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
            // Header with icon and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFirstCard
                        ? Colors.white.withOpacity(0.2)
                        : colorScheme['light'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRoomIcon(room),
                    color: isFirstCard ? Colors.white : colorScheme['bg'],
                    size: 20,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isFirstCard ? Colors.white70 : Colors.grey.shade400,
                    size: 18,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'view', child: Text('Xem chi tiết')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Chỉnh sửa')),
                    const PopupMenuItem(
                        value: 'maintenance', child: Text('Lên lịch bảo trì')),
                  ],
                  onSelected: (value) => _handleProjectCardAction(value, room),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Room name and type
            Text(
              room.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isFirstCard ? Colors.white : Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _getRoomType(room),
              style: TextStyle(
                fontSize: 12,
                color: isFirstCard ? Colors.white70 : Colors.grey.shade600,
              ),
            ),

            const Spacer(),

            // Progress section
            Text(
              'Tiến độ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isFirstCard ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),

            // Progress bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: isFirstCard
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: usageRate / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFirstCard ? Colors.white : colorScheme['bg'],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Usage percentage
            Text(
              '${usageRate.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isFirstCard ? Colors.white : colorScheme['bg'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRoomsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có phòng trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm phòng mới để bắt đầu',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddRoom(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm phòng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceDashboardCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color bgColor,
    required bool isHighlighted,
    required double progressValue,
  }) {
    // progressValue được truyền từ bên ngoài dựa trên thống kê thực tế

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon và menu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : Colors.grey.shade700,
                  size: 18,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert,
                size: 14,
                color: isHighlighted ? Colors.white70 : Colors.grey.shade400,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title và số thống kê
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white : Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
          ),

          const Spacer(),

          // Progress section
          Text(
            'Tiến độ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),

          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressValue,
              child: Container(
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.white : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Progress percentage
          Text(
            '${(progressValue * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for project-style cards
  IconData _getRoomIcon(RoomModel room) {
    if (room.amenities.contains(RoomAmenity.videoConference)) {
      return Icons.video_call;
    } else if (room.amenities.contains(RoomAmenity.projector)) {
      return Icons.present_to_all;
    } else if (room.capacity > 20) {
      return Icons.groups;
    } else {
      return Icons.meeting_room;
    }
  }

  String _getRoomType(RoomModel room) {
    if (room.capacity > 50) {
      return 'Large Conference';
    } else if (room.capacity > 20) {
      return 'Conference Room';
    } else if (room.capacity > 10) {
      return 'Meeting Room';
    } else {
      return 'Small Room';
    }
  }

  double _calculateUsageRate(RoomModel room) {
    // Calculate usage rate based on room status and bookings
    switch (room.status) {
      case RoomStatus.available:
        return 30.0 + (room.capacity * 0.5); // Base usage + capacity factor
      case RoomStatus.occupied:
        return 85.0;
      case RoomStatus.maintenance:
        return 15.0;
      case RoomStatus.disabled:
        return 0.0;
    }
  }

  void _handleProjectCardAction(String action, RoomModel room) {
    switch (action) {
      case 'view':
        _navigateToRoomDetail(context, room);
        break;
      case 'edit':
        _navigateToEditRoom(context, room);
        break;
      case 'maintenance':
        _scheduleMaintenanceDialog(room);
        break;
    }
  }

  void _scheduleMaintenanceDialog(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lên lịch bảo trì'),
        content: Text('Lên lịch bảo trì cho ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã lên lịch bảo trì cho ${room.name}')),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(RoomProvider roomProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Card với illustration style
        _buildWelcomeCard(),
        const SizedBox(height: 24),

        // Statistics Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thống kê tổng quan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController?.animateTo(3); // Statistics tab
              },
              child: Text(
                'xem tất cả',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Statistics Grid với project-style cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _buildProjectStyleCard(
              title: 'Tổng phòng',
              subtitle: 'Tất cả phòng họp',
              value: roomProvider.totalRooms.toString(),
              icon: Icons.home_work,
              bgColor: const Color(0xFF2E7BE9),
              isHighlighted: true,
              date: '',
              progressValue: 1.0, // 100% cho tổng phòng
            ),
            _buildProjectStyleCard(
              title: 'Phòng sẵn sàng',
              subtitle: 'Có thể sử dụng',
              value: roomProvider.availableCount.toString(),
              icon: Icons.check_circle,
              bgColor: Colors.white,
              isHighlighted: false,
              date: '',
              progressValue: roomProvider.totalRooms > 0
                  ? roomProvider.availableCount / roomProvider.totalRooms
                  : 0.0,
            ),
            _buildProjectStyleCard(
              title: 'Đang sử dụng',
              subtitle: 'Đang có người dùng',
              value: roomProvider.occupiedCount.toString(),
              icon: Icons.groups,
              bgColor: Colors.white,
              isHighlighted: false,
              date: '',
              progressValue: roomProvider.totalRooms > 0
                  ? roomProvider.occupiedCount / roomProvider.totalRooms
                  : 0.0,
            ),
            _buildMaintenanceDashboardCard(
              title: 'Bảo trì',
              subtitle: 'Cần bảo dưỡng',
              value: roomProvider.maintenanceCount.toString(),
              icon: Icons.build,
              bgColor: Colors.white,
              isHighlighted: false,
              progressValue: roomProvider.totalRooms > 0
                  ? roomProvider.maintenanceCount / roomProvider.totalRooms
                  : 0.0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        final occupancyRate = roomProvider.totalRooms > 0
            ? (roomProvider.occupiedCount / roomProvider.totalRooms * 100)
            : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2E7BE9), const Color(0xFF4A90FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tỷ lệ sử dụng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress section
                    Text(
                      'Tiến độ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: occupancyRate / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${occupancyRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectStyleCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color bgColor,
    required bool isHighlighted,
    required String date,
    required double progressValue,
  }) {
    // progressValue được truyền từ bên ngoài dựa trên thống kê thực tế

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon và menu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : Colors.grey.shade700,
                  size: 18,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert,
                size: 14,
                color: isHighlighted ? Colors.white70 : Colors.grey.shade400,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title và số thống kê
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white : Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
          ),

          const Spacer(),

          // Progress section
          Text(
            'Tiến độ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),

          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressValue,
              child: Container(
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white
                      : (bgColor == Colors.white
                          ? const Color(0xFF2E7BE9)
                          : bgColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Progress percentage
          Text(
            '${(progressValue * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? Colors.white
                  : (bgColor == Colors.white
                      ? const Color(0xFF2E7BE9)
                      : bgColor),
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
        _buildActionCard(
          title: 'Lịch bảo trì',
          subtitle: 'Xem lịch bảo trì',
          icon: Icons.schedule,
          color: Colors.green,
          onTap: () => _tabController?.animateTo(2),
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
                  borderRadius: BorderRadius.circular(12),
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
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAdvancedFilters,
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Lọc nâng cao'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
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
      requiredAmenities: _selectedAmenities,
      minCapacity: _minCapacity,
      maxCapacity: _maxCapacity,
      building: _selectedBuilding,
      floor: _selectedFloor,
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

  Widget _buildRoomsListWidget(
      RoomProvider roomProvider, UserModel? currentUser) {
    List<RoomModel> filteredRooms = roomProvider.searchRooms(
      keyword: _searchQuery,
      status: _filterStatus,
      requiredAmenities: _selectedAmenities,
      minCapacity: _minCapacity,
      maxCapacity: _maxCapacity,
      building: _selectedBuilding,
      floor: _selectedFloor,
    );

    if (filteredRooms.isEmpty) {
      return Container(
        height: 200,
        child: Center(
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
        ),
      );
    }

    return Column(
      children: filteredRooms
          .take(5)
          .map((room) => _buildRoomCard(room, currentUser))
          .toList(),
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
                              borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernStatisticsHeader(),
          const SizedBox(height: 24),
          _buildModernDetailedStatistics(roomProvider),
          const SizedBox(height: 32),
          _buildStatisticsChart(roomProvider),
          const SizedBox(height: 32),
          _buildQuickStatsGrid(roomProvider),
        ],
      ),
    );
  }

  Widget _buildModernStatisticsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê chi tiết',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tổng quan về tình trạng phòng họp',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailedStatistics(RoomProvider roomProvider) {
    return Column(
      children: [
        _buildModernStatCard(
          title: 'Tổng số phòng',
          value: roomProvider.totalRooms.toString(),
          icon: Icons.meeting_room,
          color: const Color(0xFF4A90E2),
          backgroundColor: const Color(0xFFF8FAFE),
        ),
        const SizedBox(height: 16),
        _buildModernStatCard(
          title: 'sẵn sàng',
          value: roomProvider.availableCount.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF8E8E93),
          backgroundColor: const Color(0xFFF8F9FA),
        ),
        const SizedBox(height: 16),
        _buildModernStatCard(
          title: 'Phòng đang sử dụng',
          value: roomProvider.occupiedCount.toString(),
          icon: Icons.people,
          color: const Color(0xFF8E8E93),
          backgroundColor: const Color(0xFFF8F9FA),
        ),
        const SizedBox(height: 16),
        _buildModernStatCard(
          title: 'Phòng bảo trì',
          value: roomProvider.maintenanceCount.toString(),
          icon: Icons.build,
          color: const Color(0xFFFF9500),
          backgroundColor: const Color(0xFFFFFBF5),
        ),
        const SizedBox(height: 16),
        _buildModernStatCard(
          title: 'Phòng tạm ngưng',
          value: roomProvider.disabledCount.toString(),
          icon: Icons.block,
          color: const Color(0xFF8E8E93),
          backgroundColor: const Color(0xFFF8F9FA),
        ),
      ],
    );
  }

  Widget _buildStatisticsChart(RoomProvider roomProvider) {
    final total = roomProvider.totalRooms;
    final available = roomProvider.availableCount;
    final occupied = roomProvider.occupiedCount;
    final maintenance = roomProvider.maintenanceCount;
    final disabled = roomProvider.disabledCount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Phân bố trạng thái',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total > 0) ...[
            _buildProgressBar(
                'Sẵn sàng', available, total, const Color(0xFF8E8E93)),
            const SizedBox(height: 16),
            _buildProgressBar(
                'Đang sử dụng', occupied, total, const Color(0xFF8E8E93)),
            const SizedBox(height: 16),
            _buildProgressBar(
                'Bảo trì', maintenance, total, const Color(0xFFFF9500)),
            const SizedBox(height: 16),
            _buildProgressBar(
                'Tạm ngưng', disabled, total, const Color(0xFF8E8E93)),
          ] else
            Center(
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$value (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid(RoomProvider roomProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê nhanh',
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
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildQuickStatCard(
              'Tỷ lệ sử dụng',
              '${_calculateUsagePercentage(roomProvider).toStringAsFixed(1)}%',
              Icons.trending_up,
              const Color(0xFF4A90E2),
            ),
            _buildQuickStatCard(
              'Hiệu suất',
              '${_calculateEfficiencyPercentage(roomProvider).toStringAsFixed(1)}%',
              Icons.speed,
              const Color(0xFF8E8E93),
            ),
            _buildQuickStatCard(
              'Cần bảo trì',
              '${roomProvider.maintenanceCount}',
              Icons.warning,
              const Color(0xFFFF9500),
            ),
            _buildQuickStatCard(
              'Khả dụng',
              '${roomProvider.availableCount}',
              Icons.check_circle,
              const Color(0xFF8E8E93),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
      String title, String value, IconData icon, Color color) {
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
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateUsagePercentage(RoomProvider roomProvider) {
    final total = roomProvider.totalRooms;
    if (total == 0) return 0.0;
    final used = roomProvider.occupiedCount;
    return (used / total) * 100;
  }

  double _calculateEfficiencyPercentage(RoomProvider roomProvider) {
    final total = roomProvider.totalRooms;
    if (total == 0) return 0.0;
    final available = roomProvider.availableCount + roomProvider.occupiedCount;
    return (available / total) * 100;
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => _AdvancedFiltersDialog(
        selectedAmenities: _selectedAmenities,
        minCapacity: _minCapacity,
        maxCapacity: _maxCapacity,
        selectedBuilding: _selectedBuilding,
        selectedFloor: _selectedFloor,
        availableBuildings: context.read<RoomProvider>().buildings,
        onFiltersApplied: (amenities, minCap, maxCap, building, floor) {
          setState(() {
            _selectedAmenities = amenities;
            _minCapacity = minCap;
            _maxCapacity = maxCap;
            _selectedBuilding = building;
            _selectedFloor = floor;
          });
        },
      ),
    );
  }
}

// Advanced Filters Dialog
class _AdvancedFiltersDialog extends StatefulWidget {
  final List<RoomAmenity> selectedAmenities;
  final int? minCapacity;
  final int? maxCapacity;
  final String? selectedBuilding;
  final String? selectedFloor;
  final List<String> availableBuildings;
  final Function(List<RoomAmenity>, int?, int?, String?, String?)
      onFiltersApplied;

  const _AdvancedFiltersDialog({
    Key? key,
    required this.selectedAmenities,
    this.minCapacity,
    this.maxCapacity,
    this.selectedBuilding,
    this.selectedFloor,
    required this.availableBuildings,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<_AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<_AdvancedFiltersDialog> {
  late List<RoomAmenity> _selectedAmenities;
  late int? _minCapacity;
  late int? _maxCapacity;
  late String? _selectedBuilding;
  late String? _selectedFloor;

  @override
  void initState() {
    super.initState();
    _selectedAmenities = List.from(widget.selectedAmenities);
    _minCapacity = widget.minCapacity;
    _maxCapacity = widget.maxCapacity;
    _selectedBuilding = widget.selectedBuilding;
    _selectedFloor = widget.selectedFloor;
  }

  String _getAmenityDisplayName(RoomAmenity amenity) {
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
        return 'Thiết bị họp online';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lọc nâng cao'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amenities Section
              const Text(
                'Tiện ích',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: RoomAmenity.values.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(_getAmenityDisplayName(amenity)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    selectedColor: Colors.blue.withOpacity(0.2),
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Capacity Section
              const Text(
                'Sức chứa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tối thiểu',
                        border: OutlineInputBorder(),
                        suffixText: 'người',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minCapacity = int.tryParse(value);
                      },
                      controller: TextEditingController(
                        text: _minCapacity?.toString() ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tối đa',
                        border: OutlineInputBorder(),
                        suffixText: 'người',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxCapacity = int.tryParse(value);
                      },
                      controller: TextEditingController(
                        text: _maxCapacity?.toString() ?? '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Building Section
              const Text(
                'Tòa nhà',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBuilding,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Chọn tòa nhà',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả'),
                  ),
                  ...widget.availableBuildings.map((building) {
                    return DropdownMenuItem<String>(
                      value: building,
                      child: Text(building),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBuilding = value;
                    _selectedFloor = null; // Reset floor when building changes
                  });
                },
              ),
              const SizedBox(height: 16),

              // Floor Section
              if (_selectedBuilding != null) ...[
                const Text(
                  'Tầng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Consumer<RoomProvider>(
                  builder: (context, roomProvider, child) {
                    final floors =
                        roomProvider.getFloorsByBuilding(_selectedBuilding!);
                    return DropdownButtonFormField<String>(
                      value: _selectedFloor,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Chọn tầng',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tất cả'),
                        ),
                        ...floors.map((floor) {
                          return DropdownMenuItem<String>(
                            value: floor,
                            child: Text('Tầng $floor'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFloor = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear all filters
            setState(() {
              _selectedAmenities.clear();
              _minCapacity = null;
              _maxCapacity = null;
              _selectedBuilding = null;
              _selectedFloor = null;
            });
            widget.onFiltersApplied([], null, null, null, null);
            Navigator.pop(context);
          },
          child: const Text('Xóa bộ lọc'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFiltersApplied(
              _selectedAmenities,
              _minCapacity,
              _maxCapacity,
              _selectedBuilding,
              _selectedFloor,
            );
            Navigator.pop(context);
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }
}
