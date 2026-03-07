import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_booking_provider.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/room_booking_model.dart';
import '../utils/booking_permissions.dart';
import 'room_detail_screen.dart';
import 'add_edit_room_screen.dart';
import '_gradient_fab.dart';

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

  // Selected stat card index for tab-card UI
  // 0: Total, 1: Available, 2: In Use, 3: Maintenance
  int _selectedStatIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // Hủy real-time stream khi rời khỏi màn hình
    context.read<RoomProvider>().unsubscribeOccupancy();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomProvider = context.read<RoomProvider>();
      roomProvider.loadRooms();
      roomProvider.loadMaintenanceRecords();
      // Bắt đầu lắng nghe real-time occupancy
      roomProvider.subscribeOccupancy();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        bottom: _tabController != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FA),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController!,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7BE9),
                          Color(0xFF4A90FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7BE9).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.all(6),
                    tabAlignment: TabAlignment.fill,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade700,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
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
                          text: 'Lịch đặt',
                          icon: Icon(Icons.calendar_month_outlined, size: 18)),
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
                    _buildCalendarTab(roomProvider, authProvider.userModel),
                  ],
                )
              : const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: GradientFab(
        onPressed: () => _navigateToAddRoom(context),
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
    // Responsive padding
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final padding = (16 * scale).clamp(12.0, 20.0);
    final sectionSpacing = (20 * scale).clamp(16.0, 28.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards (includes filtered rooms section)
          _buildStatisticsCards(roomProvider),
          SizedBox(height: sectionSpacing),
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

            // Progress bar (2-layer)
            buildLayeredProgressBar(
              progress: usageRate / 100,
              height: 6,
              trackColor: isFirstCard
                  ? Colors.white.withOpacity(0.25)
                  : Colors.grey.shade200,
              fillColor: isFirstCard
                  ? Colors.white.withOpacity(0.95)
                  : colorScheme['bg'] as Color,
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
    double scale = 1.0,
  }) {
    // Responsive sizes - smaller for fitting content
    final padding = (10 * scale).clamp(8.0, 12.0);
    final iconContainerPadding = (5 * scale).clamp(4.0, 8.0);
    final iconSize = (14 * scale).clamp(12.0, 18.0);
    final titleFontSize = (11 * scale).clamp(10.0, 13.0);
    final valueFontSize = (20 * scale).clamp(16.0, 26.0);
    final subtitleFontSize = (9 * scale).clamp(8.0, 11.0);
    final percentFontSize = (16 * scale).clamp(14.0, 20.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
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
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : Colors.grey.shade700,
                  size: iconSize,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert,
                size: 12,
                color: isHighlighted ? Colors.white70 : Colors.grey.shade400,
              ),
            ],
          ),

          const Spacer(),

          // Title (separate line)
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? Colors.white : Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Value (big number on separate line)
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : Colors.grey.shade800,
            ),
          ),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Progress section
          Text(
            'Tiến độ',
            style: TextStyle(
              fontSize: (8 * scale).clamp(7.0, 10.0),
              fontWeight: FontWeight.w500,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 3 * scale),

          // Progress bar (2-layer)
          buildLayeredProgressBar(
            progress: progressValue,
            height: 4,
            trackColor: isHighlighted
                ? Colors.white.withOpacity(0.25)
                : Colors.grey.shade200,
            fillColor:
                isHighlighted ? Colors.white.withOpacity(0.95) : Colors.orange,
          ),
          SizedBox(height: 3 * scale),

          // Progress percentage
          Text(
            '${(progressValue * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: percentFontSize,
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
    // Responsive scale based on iPhone 11 (375px width)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);

    // Calculate aspect ratio based on screen width - smaller screens need smaller ratio (taller cards)
    final aspectRatio =
        screenWidth < 360 ? 0.75 : (screenWidth < 400 ? 0.85 : 0.95);
    final spacing = (12 * scale).clamp(8.0, 16.0);

    // Define card data
    final cardData = [
      {
        'title': 'Tổng phòng',
        'subtitle': 'Tất cả phòng họp',
        'value': roomProvider.totalRooms,
        'icon': Icons.home_work,
        'progress': 1.0,
      },
      {
        'title': 'Phòng sẵn sàng',
        'subtitle': 'Có thể sử dụng',
        'value': roomProvider.availableCount,
        'icon': Icons.check_circle,
        'progress': roomProvider.totalRooms > 0
            ? roomProvider.availableCount / roomProvider.totalRooms
            : 0.0,
      },
      {
        'title': 'Đang sử dụng',
        'subtitle': 'Đang có người dùng',
        // Sử dụng currentlyOccupiedCount - đếm thực tế từ meetings đang diễn ra
        'value': roomProvider.currentlyOccupiedCount,
        'icon': Icons.groups,
        'progress': roomProvider.totalRooms > 0
            ? roomProvider.currentlyOccupiedCount / roomProvider.totalRooms
            : 0.0,
      },
      {
        'title': 'Bảo trì',
        'subtitle': 'Cần bảo dưỡng',
        'value': roomProvider.maintenanceCount,
        'icon': Icons.build,
        'progress': roomProvider.totalRooms > 0
            ? roomProvider.maintenanceCount / roomProvider.totalRooms
            : 0.0,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Card với illustration style
        _buildWelcomeCard(scale),
        SizedBox(height: 20 * scale),

        // Statistics Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thống kê tổng quan',
              style: TextStyle(
                fontSize: (18 * scale).clamp(16.0, 22.0),
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
                  fontSize: (14 * scale).clamp(12.0, 16.0),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * scale),

        // Selectable Statistics Grid - Increased height for better number display
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio:
              0.82, // Increased from 0.75 to give more vertical space
          children: List.generate(4, (index) {
            final data = cardData[index];
            return _buildSelectableStatCard(
              index: index,
              title: data['title'] as String,
              subtitle: data['subtitle'] as String,
              value: data['value'] as int,
              icon: data['icon'] as IconData,
              progress: data['progress'] as double,
              scale: scale,
            );
          }),
        ),

        SizedBox(height: 20 * scale),

        // Filtered Rooms Section based on selected tab
        _buildFilteredRoomsSection(roomProvider, scale),
      ],
    );
  }

  /// Selectable stat card with animation
  Widget _buildSelectableStatCard({
    required int index,
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
    required double progress,
    required double scale,
  }) {
    final isActive = _selectedStatIndex == index;
    const activeColor = Color(0xFF2563EB);

    final padding = (16 * scale).clamp(12.0, 20.0);
    final iconSize = (20 * scale).clamp(16.0, 24.0);
    final titleFontSize = (13 * scale).clamp(11.0, 15.0);
    final valueFontSize = (25 * scale)
        .clamp(22.0, 36.0); // Balanced size - prominent but not overflowing
    final subtitleFontSize = (10 * scale).clamp(8.5, 12.0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isActive ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? activeColor.withOpacity(0.32)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isActive ? 22 : 14,
              offset: Offset(0, isActive ? 12 : 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon & Menu row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.2)
                          : activeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: isActive ? Colors.white : activeColor,
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    size: 18 * scale,
                    color: isActive ? Colors.white70 : Colors.grey.shade400,
                  ),
                ],
              ),

              // Middle content section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8 * scale),

                  // Value - Constrained with FittedBox as safety net
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 50 * scale, // Limit max height
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : Colors.grey.shade900,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4 * scale),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: isActive ? Colors.white70 : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              // Footer: Progress section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiến độ',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4 * scale),

                  // Progress bar
                  buildLayeredProgressBar(
                    progress: progress,
                    height: 5,
                    trackColor: isActive
                        ? Colors.white.withOpacity(0.25)
                        : Colors.grey.shade200,
                    fillColor:
                        isActive ? Colors.white.withOpacity(0.95) : activeColor,
                  ),
                  SizedBox(height: 4 * scale),

                  // Percentage
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: (14 * scale).clamp(12.0, 18.0),
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : activeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Filtered rooms section based on selected stat tab
  Widget _buildFilteredRoomsSection(RoomProvider roomProvider, double scale) {
    // Get filtered rooms based on selected index
    List<RoomModel> filteredRooms;
    String sectionTitle;

    switch (_selectedStatIndex) {
      case 0: // Total
        filteredRooms = roomProvider.rooms;
        sectionTitle = 'Tất cả phòng họp';
        break;
      case 1: // Available
        filteredRooms = roomProvider.rooms
            .where((r) => r.status == RoomStatus.available)
            .toList();
        sectionTitle = 'Phòng sẵn sàng';
        break;
      case 2: // In Use (REAL-TIME: dựa trên meetings đang diễn ra)
        filteredRooms = roomProvider.rooms
            .where((r) => roomProvider.isRoomCurrentlyOccupied(r.id))
            .toList();
        sectionTitle = 'Phòng đang sử dụng';
        break;
      case 3: // Maintenance
        filteredRooms = roomProvider.rooms
            .where((r) => r.status == RoomStatus.maintenance)
            .toList();
        sectionTitle = 'Phòng đang bảo trì';
        break;
      default:
        filteredRooms = roomProvider.rooms;
        sectionTitle = 'Tất cả phòng họp';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: TextStyle(
                fontSize: (16 * scale).clamp(14.0, 20.0),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 4 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7BE9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${filteredRooms.length} phòng',
                style: TextStyle(
                  fontSize: (12 * scale).clamp(10.0, 14.0),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E7BE9),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * scale),

        // Animated room list
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: filteredRooms.isEmpty
              ? _buildEmptyFilteredState(sectionTitle, scale)
              : _buildFilteredRoomsList(filteredRooms, scale),
        ),
      ],
    );
  }

  Widget _buildEmptyFilteredState(String title, double scale) {
    return Container(
      key: ValueKey('empty_$_selectedStatIndex'),
      width: double.infinity,
      padding: EdgeInsets.all(32 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 48 * scale,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12 * scale),
          Text(
            'Không có phòng nào',
            style: TextStyle(
              fontSize: (14 * scale).clamp(12.0, 16.0),
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredRoomsList(List<RoomModel> rooms, double scale) {
    return Container(
      key: ValueKey('list_$_selectedStatIndex'),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rooms.length > 5 ? 5 : rooms.length, // Show max 5 rooms
        separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildCompactRoomCard(room, scale);
        },
      ),
    );
  }

  Widget _buildCompactRoomCard(RoomModel room, double scale) {
    final statusColor = _getStatusColor(room.status);
    final statusText = _getStatusText(room.status);

    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Room icon
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.meeting_room,
              size: 22 * scale,
              color: statusColor,
            ),
          ),
          SizedBox(width: 12 * scale),

          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: TextStyle(
                    fontSize: (15 * scale).clamp(13.0, 18.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2 * scale),
                Text(
                  '${room.location} • ${room.capacity} người',
                  style: TextStyle(
                    fontSize: (11 * scale).clamp(9.0, 13.0),
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 6 * scale,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: (10 * scale).clamp(8.0, 12.0),
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return const Color(0xFF4CAF50);
      case RoomStatus.occupied:
        return const Color(0xFFFF9800);
      case RoomStatus.maintenance:
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Sẵn sàng';
      case RoomStatus.occupied:
        return 'Đang dùng';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      default:
        return 'Không xác định';
    }
  }

  Widget _buildWelcomeCard([double scale = 1.0]) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        final occupancyRate = roomProvider.totalRooms > 0
            ? (roomProvider.occupiedCount / roomProvider.totalRooms * 100)
            : 0.0;

        final padding = (20 * scale).clamp(16.0, 26.0);
        final iconSize = (24 * scale).clamp(20.0, 30.0);
        final titleFontSize = (15 * scale).clamp(13.0, 19.0);
        final percentFontSize = (32 * scale).clamp(24.0, 40.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2563EB),
                Color(0xFF4F46E5),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tỷ lệ sử dụng',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10 * scale),

                    // Progress section
                    Text(
                      'Tiến độ',
                      style: TextStyle(
                        fontSize: (11 * scale).clamp(9.0, 13.0),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 6 * scale),

                    // Progress bar (2-layer)
                    buildLayeredProgressBar(
                      progress: occupancyRate / 100,
                      height: 8,
                      trackColor: Colors.white.withOpacity(0.22),
                      fillColor: Colors.white,
                    ),
                    SizedBox(height: 10 * scale),

                    Text(
                      '${occupancyRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: percentFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
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
    double scale = 1.0,
  }) {
    // Responsive sizes - smaller for fitting content
    final padding = (10 * scale).clamp(8.0, 12.0);
    final iconContainerPadding = (5 * scale).clamp(4.0, 8.0);
    final iconSize = (14 * scale).clamp(12.0, 18.0);
    final titleFontSize = (11 * scale).clamp(10.0, 13.0);
    final valueFontSize = (20 * scale).clamp(16.0, 26.0);
    final subtitleFontSize = (9 * scale).clamp(8.0, 11.0);
    final percentFontSize = (16 * scale).clamp(14.0, 20.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
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
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : Colors.grey.shade700,
                  size: iconSize,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert,
                size: 12,
                color: isHighlighted ? Colors.white70 : Colors.grey.shade400,
              ),
            ],
          ),

          const Spacer(),

          // Title (separate line)
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? Colors.white : Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Value (big number on separate line)
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : Colors.grey.shade800,
            ),
          ),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Progress section
          Text(
            'Tiến độ',
            style: TextStyle(
              fontSize: (8 * scale).clamp(7.0, 10.0),
              fontWeight: FontWeight.w500,
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 3 * scale),

          // Progress bar (2-layer)
          buildLayeredProgressBar(
            progress: progressValue,
            height: 4,
            trackColor: isHighlighted
                ? Colors.white.withOpacity(0.25)
                : Colors.grey.shade200,
            fillColor: isHighlighted
                ? Colors.white.withOpacity(0.95)
                : (bgColor == Colors.white ? const Color(0xFF2E7BE9) : bgColor),
          ),
          SizedBox(height: 3 * scale),

          // Progress percentage
          Text(
            '${(progressValue * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: percentFontSize,
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
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
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
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
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
      return SizedBox(
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
                  Expanded(
                    child: Text(
                      room.fullLocation,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${room.capacity} người',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.square_foot,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${room.area.toStringAsFixed(0)} m²',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
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

  // Calendar state
  DateTime _selectedCalendarDate = DateTime.now();
  String? _selectedCalendarRoomId;

  Widget _buildCalendarTab(RoomProvider roomProvider, UserModel? currentUser) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);

    return Consumer<RoomBookingProvider>(
      builder: (context, bookingProvider, child) {
        return Column(
          children: [
            // Calendar Header
            _buildCalendarHeader(roomProvider, scale),

            // Day Timeline
            Expanded(
              child: _buildDayTimeline(
                roomProvider,
                bookingProvider,
                currentUser,
                scale,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarHeader(RoomProvider roomProvider, double scale) {
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCalendarDate =
                        _selectedCalendarDate.subtract(const Duration(days: 1));
                  });
                  _loadBookingsForDate();
                },
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),

              // Date Display - Tappable to show date picker
              GestureDetector(
                onTap: () => _showDatePicker(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7BE9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18 * scale,
                        color: const Color(0xFF2E7BE9),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        dateFormat.format(_selectedCalendarDate),
                        style: TextStyle(
                          fontSize: (14 * scale).clamp(12.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7BE9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCalendarDate =
                        _selectedCalendarDate.add(const Duration(days: 1));
                  });
                  _loadBookingsForDate();
                },
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),

          SizedBox(height: 12 * scale),

          // Room Filter
          Row(
            children: [
              Text(
                'Phòng:',
                style: TextStyle(
                  fontSize: (13 * scale).clamp(11.0, 15.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedCalendarRoomId,
                      isExpanded: true,
                      hint: Text(
                        'Tất cả phòng',
                        style:
                            TextStyle(fontSize: (13 * scale).clamp(11.0, 15.0)),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Tất cả phòng',
                            style: TextStyle(
                                fontSize: (13 * scale).clamp(11.0, 15.0)),
                          ),
                        ),
                        ...roomProvider.rooms
                            .map((room) => DropdownMenuItem<String?>(
                                  value: room.id,
                                  child: Text(
                                    room.name,
                                    style: TextStyle(
                                        fontSize:
                                            (13 * scale).clamp(11.0, 15.0)),
                                  ),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCalendarRoomId = value;
                        });
                        _loadBookingsForDate();
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8 * scale),

              // Today button
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCalendarDate = DateTime.now();
                  });
                  _loadBookingsForDate();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                ),
                child: Text(
                  'Hôm nay',
                  style: TextStyle(
                    fontSize: (12 * scale).clamp(10.0, 14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTimeline(
    RoomProvider roomProvider,
    RoomBookingProvider bookingProvider,
    UserModel? currentUser,
    double scale,
  ) {
    // Generate time slots from 7:00 to 22:00
    final timeSlots = List.generate(
      BookingRules.workingHoursEnd - BookingRules.workingHoursStart,
      (index) => BookingRules.workingHoursStart + index,
    );

    final bookings = bookingProvider.bookings;

    return RefreshIndicator(
      onRefresh: () => _loadBookingsForDate(),
      child: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16 * scale),
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final hour = timeSlots[index];
                final slotStart = DateTime(
                  _selectedCalendarDate.year,
                  _selectedCalendarDate.month,
                  _selectedCalendarDate.day,
                  hour,
                );
                final slotEnd = slotStart.add(const Duration(hours: 1));

                // Find bookings in this time slot
                final slotBookings = bookings.where((b) {
                  final overlaps = b.startTime.isBefore(slotEnd) &&
                      b.endTime.isAfter(slotStart);
                  if (_selectedCalendarRoomId != null) {
                    return overlaps && b.roomId == _selectedCalendarRoomId;
                  }
                  return overlaps;
                }).toList();

                return _buildTimeSlot(
                  hour: hour,
                  bookings: slotBookings,
                  roomProvider: roomProvider,
                  currentUser: currentUser,
                  scale: scale,
                );
              },
            ),
    );
  }

  Widget _buildTimeSlot({
    required int hour,
    required List<RoomBooking> bookings,
    required RoomProvider roomProvider,
    required UserModel? currentUser,
    required double scale,
  }) {
    final timeFormat = DateFormat('HH:mm');
    final slotTime = DateTime(_selectedCalendarDate.year,
        _selectedCalendarDate.month, _selectedCalendarDate.day, hour);
    final isCurrentHour = DateTime.now().hour == hour &&
        _isSameDay(_selectedCalendarDate, DateTime.now());

    return Container(
      margin: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 50 * scale,
            child: Text(
              timeFormat.format(slotTime),
              style: TextStyle(
                fontSize: (12 * scale).clamp(10.0, 14.0),
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w500,
                color: isCurrentHour
                    ? const Color(0xFF2E7BE9)
                    : Colors.grey.shade600,
              ),
            ),
          ),

          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12 * scale,
                height: 12 * scale,
                decoration: BoxDecoration(
                  color: isCurrentHour
                      ? const Color(0xFF2E7BE9)
                      : (bookings.isEmpty
                          ? Colors.grey.shade300
                          : Colors.orange),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 60 * scale,
                color: Colors.grey.shade200,
              ),
            ],
          ),

          SizedBox(width: 12 * scale),

          // Booking cards or empty slot
          Expanded(
            child: bookings.isEmpty
                ? _buildEmptyTimeSlot(
                    slotTime, roomProvider, currentUser, scale)
                : Column(
                    children: bookings
                        .map((booking) =>
                            _buildBookingCard(booking, currentUser, scale))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeSlot(
    DateTime slotTime,
    RoomProvider roomProvider,
    UserModel? currentUser,
    double scale,
  ) {
    final isPast = slotTime.isBefore(DateTime.now());

    return GestureDetector(
      onTap: isPast
          ? null
          : () => _showQuickBookDialog(slotTime, roomProvider, currentUser),
      child: Container(
        height: 60 * scale,
        decoration: BoxDecoration(
          color: isPast ? Colors.grey.shade100 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPast ? Colors.grey.shade200 : Colors.green.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPast ? Icons.block : Icons.add_circle_outline,
                size: 18 * scale,
                color: isPast ? Colors.grey.shade400 : Colors.green.shade600,
              ),
              SizedBox(width: 6 * scale),
              Text(
                isPast ? 'Đã qua' : 'Trống - Nhấn để đặt',
                style: TextStyle(
                  fontSize: (12 * scale).clamp(10.0, 14.0),
                  color: isPast ? Colors.grey.shade400 : Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      RoomBooking booking, UserModel? currentUser, double scale) {
    final timeFormat = DateFormat('HH:mm');
    final canView = currentUser != null &&
        BookingPermissions.canViewBookingDetails(currentUser, booking);
    final isMyBooking = currentUser?.id == booking.createdBy;

    // Determine color and style based on status
    Color statusColor;
    Color bgColor;
    bool isDashed = false;
    IconData statusIcon = Icons.event;

    switch (booking.status) {
      case BookingStatus.reserved:
        statusColor = Colors.purple;
        bgColor = Colors.purple.shade50;
        statusIcon = Icons.lock_clock;
        if (booking.isPendingAdminApproval) {
          isDashed = true;
          statusColor = Colors.orange;
          bgColor = Colors.orange.shade50;
        }
        break;
      case BookingStatus.pending:
        statusColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        statusIcon = Icons.hourglass_top;
        break;
      case BookingStatus.approved:
        statusColor = const Color(0xFF2E7BE9);
        bgColor = const Color(0xFF2E7BE9).withOpacity(0.1);
        statusIcon = Icons.check_circle_outline;
        break;
      case BookingStatus.converted:
        statusColor = Colors.green;
        bgColor = Colors.green.shade50;
        statusIcon = Icons.event_available;
        break;
      case BookingStatus.releasedBySystem:
        statusColor = Colors.grey;
        bgColor = Colors.grey.shade100;
        statusIcon = Icons.event_busy;
        break;
      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey.shade100;
    }

    return GestureDetector(
      onTap: isMyBooking && booking.needsConversion
          ? () => _showBookingActionSheet(booking)
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 8 * scale),
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: statusColor.withOpacity(isDashed ? 0.5 : 0.3),
            width: isDashed ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status
            Row(
              children: [
                // Quick booking indicator
                if (booking.isQuickBooking) ...[
                  Icon(statusIcon, size: 14 * scale, color: statusColor),
                  SizedBox(width: 4 * scale),
                ],
                Expanded(
                  child: Text(
                    canView || isMyBooking ? booking.title : 'Đã đặt',
                    style: TextStyle(
                      fontSize: (13 * scale).clamp(11.0, 15.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.isPendingAdminApproval
                        ? 'Chờ duyệt'
                        : booking.statusText,
                    style: TextStyle(
                      fontSize: (9 * scale).clamp(8.0, 11.0),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 6 * scale),

            // Time & Room
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14 * scale, color: Colors.grey.shade600),
                SizedBox(width: 4 * scale),
                Text(
                  '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                  style: TextStyle(
                    fontSize: (11 * scale).clamp(9.0, 13.0),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Icon(Icons.meeting_room,
                    size: 14 * scale, color: Colors.grey.shade600),
                SizedBox(width: 4 * scale),
                Expanded(
                  child: Text(
                    booking.roomName,
                    style: TextStyle(
                      fontSize: (11 * scale).clamp(9.0, 13.0),
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Creator (if can view)
            if (canView && !isMyBooking) ...[
              SizedBox(height: 4 * scale),
              Row(
                children: [
                  Icon(Icons.person,
                      size: 14 * scale, color: Colors.grey.shade500),
                  SizedBox(width: 4 * scale),
                  Text(
                    booking.createdByName,
                    style: TextStyle(
                      fontSize: (10 * scale).clamp(8.0, 12.0),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],

            // Quick booking action hint (for own bookings needing conversion)
            if (isMyBooking && booking.needsConversion) ...[
              SizedBox(height: 8 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app,
                        size: 12 * scale, color: Colors.amber.shade800),
                    SizedBox(width: 4 * scale),
                    Text(
                      'Nhấn để tạo cuộc họp',
                      style: TextStyle(
                        fontSize: (10 * scale).clamp(8.0, 12.0),
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade800,
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

  /// Show action sheet for booking (create meeting, cancel, etc.)
  void _showBookingActionSheet(RoomBooking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Booking info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_clock,
                      color: Colors.purple.shade700, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.roomName} • ${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
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
            ),

            const SizedBox(height: 16),

            // Countdown warning
            if (booking.minutesUntilAutoRelease <= 10 && booking.isOngoing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Còn ${booking.minutesUntilAutoRelease} phút để tạo cuộc họp!',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Create meeting button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToCreateMeetingFromBooking(booking);
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tạo cuộc họp ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7BE9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel booking button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancelBooking(booking),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Hủy đặt phòng',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Confirm cancel booking
  void _confirmCancelBooking(RoomBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt phòng?'),
        content: const Text(
          'Bạn có chắc muốn hủy đặt phòng này? Phòng sẽ được giải phóng cho người khác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet

              final authProvider = context.read<AuthProvider>();
              final bookingProvider = context.read<RoomBookingProvider>();

              final user = authProvider.userModel;
              if (user == null) return;

              final success = await bookingProvider.cancelBooking(
                booking.id,
                user,
                'Người dùng tự hủy',
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy đặt phòng'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadBookingsForDate();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(bookingProvider.error ?? 'Lỗi hủy đặt phòng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đặt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Navigate to create meeting with booking data
  void _navigateToCreateMeetingFromBooking(RoomBooking booking) {
    // TODO: Navigate to meeting creation with prefilled data
    // This will be implemented in Phase 7
    Navigator.pushNamed(
      context,
      '/meeting/create',
      arguments: {
        'source': 'quick_booking_reminder',
        'bookingId': booking.id,
        'roomId': booking.roomId,
        'roomName': booking.roomName,
        'startTime': booking.startTime.toIso8601String(),
        'endTime': booking.endTime.toIso8601String(),
        'title': booking.title,
        'description': booking.description,
      },
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedCalendarDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        _selectedCalendarDate = picked;
      });
      _loadBookingsForDate();
    }
  }

  Future<void> _loadBookingsForDate() async {
    final bookingProvider = context.read<RoomBookingProvider>();
    await bookingProvider.getBookingsForDate(
      _selectedCalendarDate,
      roomId: _selectedCalendarRoomId,
    );
  }

  void _showQuickBookDialog(
    DateTime slotTime,
    RoomProvider roomProvider,
    UserModel? currentUser,
  ) {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt phòng')),
      );
      return;
    }

    final titleController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedRoomId = _selectedCalendarRoomId;
    int duration = BookingRules.defaultQuickBookingDuration;
    bool isLoading = false;
    UserBookingStats? userStats;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Load user stats on first build
          if (userStats == null) {
            final bookingProvider = context.read<RoomBookingProvider>();
            bookingProvider.getUserBookingStats(currentUser.id).then((stats) {
              setModalState(() {
                userStats = stats;
              });
            });
          }

          final endTime = slotTime.add(Duration(minutes: duration));
          final maxDuration =
              BookingRules.getMaxBookingDuration(currentUser.role);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Đặt phòng nhanh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quota card (Số lượt đặt phòng)
                    if (userStats != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Số lượt đặt phòng',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Còn ${userStats!.remainingQuickBookings(currentUser.role)} lượt',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2E7BE9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Hôm nay bạn còn ${userStats!.remainingQuickBookings(currentUser.role)} lượt đặt phòng nhanh.',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Chi tiết',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7BE9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (userStats == null) const SizedBox.shrink(),
                    const SizedBox(height: 16),

                    // Restricted user warning
                    if (userStats?.isRestricted == true)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bạn đang bị hạn chế. Booking cần admin duyệt hoặc tự mở sau 24h.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Time & Date display (two cards like design)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THỜI GIAN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: Color(0xFF2E7BE9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${DateFormat('HH:mm').format(slotTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF101828),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NGÀY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: Color(0xFF2E7BE9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(slotTime),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF101828),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title input
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Mục đích / Tiêu đề *',
                        hintText: 'VD: Họp team, Phỏng vấn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Room selection
                    DropdownButtonFormField<String>(
                      value: selectedRoomId,
                      decoration: InputDecoration(
                        labelText: 'Chọn phòng *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.meeting_room),
                      ),
                      items: roomProvider.rooms
                          .where((r) => r.status == RoomStatus.available)
                          .map((room) => DropdownMenuItem(
                                value: room.id,
                                child: Text(
                                    '${room.name} (${room.capacity} người)'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedRoomId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Note input
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                        hintText: 'Thêm ghi chú...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Duration selection
                    Row(
                      children: [
                        const Text('Thời lượng:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text(
                          '(tối đa ${maxDuration ~/ 60}h)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BookingRules.quickBookingDurations
                          .where((mins) => mins <= maxDuration)
                          .map((mins) {
                        final isSelected = duration == mins;
                        final label = mins >= 60
                            ? '${mins ~/ 60}h${mins % 60 > 0 ? " ${mins % 60}p" : ""}'
                            : '${mins}p';
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                duration = mins;
                              });
                            }
                          },
                          selectedColor:
                              const Color(0xFF2E7BE9).withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Important notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.amber.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Lưu ý quan trọng:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• Bạn sẽ nhận nhắc nhở 15 phút trước giờ họp\n'
                            '• Phải tạo cuộc họp trong 10 phút đầu, nếu không phòng sẽ được giải phóng\n'
                            '• Không tạo cuộc họp sẽ bị ghi nhận vi phạm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (titleController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Vui lòng nhập mục đích')),
                                      );
                                      return;
                                    }
                                    if (selectedRoomId == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Vui lòng chọn phòng')),
                                      );
                                      return;
                                    }

                                    setModalState(() => isLoading = true);

                                    final room = roomProvider.rooms.firstWhere(
                                      (r) => r.id == selectedRoomId,
                                    );

                                    final bookingProvider =
                                        context.read<RoomBookingProvider>();
                                    final result = await bookingProvider
                                        .createQuickBooking(
                                      room: room,
                                      user: currentUser,
                                      startTime: slotTime,
                                      endTime: slotTime
                                          .add(Duration(minutes: duration)),
                                      title: titleController.text.trim(),
                                      note: noteController.text.trim().isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    );

                                    setModalState(() => isLoading = false);
                                    Navigator.pop(context);

                                    if (result != null) {
                                      String message = 'Đặt phòng thành công!';
                                      if (result.isPendingAdminApproval) {
                                        message =
                                            'Đã gửi yêu cầu, chờ admin duyệt';
                                      }

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(message,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Nhớ tạo cuộc họp trước khi bắt đầu!',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                      _loadBookingsForDate();
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(bookingProvider.error ??
                                              'Lỗi đặt phòng'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7BE9),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Giữ chỗ ngay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thống kê chi tiết',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
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
          // Dùng số phòng đang có meeting diễn ra REAL-TIME
          value: roomProvider.currentlyOccupiedCount.toString(),
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
    // Thống kê phần trăm dựa trên số phòng đang có meeting diễn ra
    final occupied = roomProvider.currentlyOccupiedCount;
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
                child: const Icon(
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

/// Reusable 2-layer progress bar widget
/// [progress] should be 0.0 to 1.0
/// [height] default 6px
/// [trackColor] background track color
/// [fillColor] progress fill color
Widget buildLayeredProgressBar({
  required double progress,
  double height = 6,
  Color? trackColor,
  Color? fillColor,
  bool isLightTheme = false,
}) {
  // Clamp progress between 0 and 1
  final clampedProgress = progress.clamp(0.0, 1.0);

  // Default colors based on theme
  final defaultTrackColor =
      isLightTheme ? Colors.grey.shade200 : Colors.white.withOpacity(0.25);
  final defaultFillColor =
      isLightTheme ? Colors.blue : Colors.white.withOpacity(0.95);

  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final fillWidth = maxWidth * clampedProgress;

      return SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            // Track layer (background - full width)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: double.infinity,
                height: height,
                color: trackColor ?? defaultTrackColor,
              ),
            ),
            // Fill layer (progress)
            if (clampedProgress > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: fillWidth < height
                      ? height
                      : fillWidth, // Min width = height for rounded look
                  height: height,
                  color: fillColor ?? defaultFillColor,
                ),
              ),
          ],
        ),
      );
    },
  );
}
