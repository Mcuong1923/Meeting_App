import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart' hide MeetingStatus;
import 'meeting_create_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({Key? key}) : super(key: key);

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    _loadMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMeetings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      meetingProvider.loadMeetings(authProvider.userModel!);
    }
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
                  text: 'Tất cả',
                  icon: Icon(Icons.list_outlined, size: 18),
                ),
                Tab(
                  text: 'Chờ phê duyệt',
                  icon: Icon(Icons.pending_outlined, size: 18),
                ),
                Tab(
                  text: 'Của tôi',
                  icon: Icon(Icons.person_outlined, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMeetingList(authProvider.userModel!, MeetingListType.all),
              _buildMeetingList(
                  authProvider.userModel!, MeetingListType.pending),
              _buildMeetingList(
                  authProvider.userModel!, MeetingListType.myMeetings),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) return const SizedBox();

          // Kiểm tra quyền tạo cuộc họp
          final canCreate =
              authProvider.userModel!.getAllowedMeetingTypes().isNotEmpty;

          if (canCreate) {
            return FloatingActionButton(
              onPressed: () => _navigateToCreateMeeting(),
              backgroundColor: const Color(0xFF2E7BE9),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.videocam, size: 24),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMeetingList(UserModel currentUser, MeetingListType type) {
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        if (meetingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MeetingModel> meetings = [];
        switch (type) {
          case MeetingListType.all:
            meetings = meetingProvider.meetings;
            break;
          case MeetingListType.pending:
            meetings = meetingProvider.pendingMeetings;
            break;
          case MeetingListType.myMeetings:
            meetings = meetingProvider.myMeetings;
            break;
        }

        if (meetings.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async => _loadMeetings(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _buildMeetingCard(meeting, currentUser);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(MeetingListType type) {
    String message = '';
    String subtitle = '';
    IconData icon = Icons.meeting_room;

    switch (type) {
      case MeetingListType.all:
        message = 'Chưa có cuộc họp nào';
        subtitle = 'Danh sách cuộc họp sẽ hiển thị ở đây';
        icon = Icons.video_call_outlined;
        break;
      case MeetingListType.pending:
        message = 'Không có cuộc họp chờ phê duyệt';
        subtitle = 'Các cuộc họp cần phê duyệt sẽ xuất hiện ở đây';
        icon = Icons.pending_outlined;
        break;
      case MeetingListType.myMeetings:
        message = 'Bạn chưa tạo cuộc họp nào';
        subtitle = 'Bắt đầu bằng cách tạo cuộc họp đầu tiên';
        icon = Icons.person_outlined;
        break;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(32),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7BE9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF2E7BE9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (type == MeetingListType.myMeetings) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateMeeting(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tạo cuộc họp đầu tiên'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7BE9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, UserModel currentUser) {
    final statusColor = _getStatusColor(meeting.status);

    return GestureDetector(
      onTap: () => _showMeetingDetails(meeting),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Header với status dot, title và menu
            Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_canManageMeeting(meeting, currentUser))
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('Xem chi tiết'),
                      ),
                      if (meeting.isPending &&
                          _canApproveMeeting(currentUser)) ...[
                        const PopupMenuItem(
                          value: 'approve',
                          child: Text('Phê duyệt'),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Text('Từ chối'),
                        ),
                      ],
                      if (meeting.creatorId == currentUser.id ||
                          currentUser.isSuperAdmin ||
                          currentUser.isAdmin) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Chỉnh sửa'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa'),
                        ),
                      ],
                    ],
                    onSelected: (value) => _handleMeetingAction(value, meeting),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Subtitle với thông tin thời gian
            Text(
              _getMeetingSubtitle(meeting),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Thông tin địa điểm
            Row(
              children: [
                Icon(
                  meeting.isVirtual ? Icons.videocam : Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    meeting.isVirtual
                        ? 'Trực tuyến'
                        : (meeting.physicalLocation ?? 'Chưa có địa điểm'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Thông tin số người tham gia
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_getParticipantCount(meeting)} người tham gia',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tags row
            Row(
              children: [
                _buildSimpleChip(_getMeetingTypeText(meeting.type),
                    Colors.blue.shade100, Colors.blue.shade800),
                const SizedBox(width: 8),
                _buildSimpleChip(
                    _getPriorityText(meeting.priority),
                    _getPriorityColor(meeting.priority).withOpacity(0.1),
                    _getPriorityColor(meeting.priority)),
                const Spacer(),
                // Status chip góc phải
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(meeting.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getMeetingSubtitle(MeetingModel meeting) {
    final duration = meeting.endTime.difference(meeting.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    String durationText = '';
    if (hours > 0) {
      durationText = '${hours}h ${minutes}m';
    } else {
      durationText = '${minutes}m';
    }

    return '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)} • $durationText';
  }

  String _getMeetingTypeText(MeetingType type) {
    switch (type) {
      case MeetingType.personal:
        return 'Cá nhân';
      case MeetingType.team:
        return 'Team';
      case MeetingType.department:
        return 'Phòng ban';
      case MeetingType.company:
        return 'Công ty';
    }
  }

  String _getPriorityText(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return 'Thấp';
      case MeetingPriority.medium:
        return 'TB';
      case MeetingPriority.high:
        return 'Cao';
      case MeetingPriority.urgent:
        return 'Khẩn';
    }
  }

  String _getStatusText(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.pending:
        return 'Chờ duyệt';
      case MeetingStatus.approved:
        return 'Đã duyệt';
      case MeetingStatus.rejected:
        return 'Từ chối';
      case MeetingStatus.cancelled:
        return 'Đã hủy';
      case MeetingStatus.completed:
        return 'Hoàn thành';
    }
  }

  void _handleMeetingAction(String action, MeetingModel meeting) {
    switch (action) {
      case 'view':
        _showMeetingDetails(meeting);
        break;
      case 'approve':
        _approveMeeting(meeting);
        break;
      case 'reject':
        _rejectMeeting(meeting);
        break;
      case 'edit':
        _editMeeting(meeting);
        break;
      case 'delete':
        _deleteMeeting(meeting);
        break;
    }
  }

  int _getParticipantCount(MeetingModel meeting) {
    // Trả về số lượng người tham gia mặc định
    // TODO: Cập nhật khi có field participants trong MeetingModel
    return 3; // Giá trị mặc định cho demo
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
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
      ),
    );
  }

  Color _getStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.pending:
        return Colors.orange;
      case MeetingStatus.approved:
        return Colors.green;
      case MeetingStatus.rejected:
        return Colors.red;
      case MeetingStatus.cancelled:
        return Colors.grey;
      case MeetingStatus.completed:
        return const Color(0xFF2E7BE9);
    }
  }

  Color _getPriorityColor(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return Colors.green;
      case MeetingPriority.medium:
        return Colors.orange;
      case MeetingPriority.high:
        return Colors.red;
      case MeetingPriority.urgent:
        return Colors.red.shade900;
    }
  }

  Widget _buildModernStatusChip(MeetingStatus status) {
    Color color = _getStatusColor(status);
    String text;
    IconData icon;

    switch (status) {
      case MeetingStatus.pending:
        text = 'Chờ phê duyệt';
        icon = Icons.schedule;
        break;
      case MeetingStatus.approved:
        text = 'Đã phê duyệt';
        icon = Icons.check_circle;
        break;
      case MeetingStatus.rejected:
        text = 'Bị từ chối';
        icon = Icons.cancel;
        break;
      case MeetingStatus.cancelled:
        text = 'Đã hủy';
        icon = Icons.block;
        break;
      case MeetingStatus.completed:
        text = 'Hoàn thành';
        icon = Icons.done_all;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTypeChip(MeetingType type) {
    String text;
    IconData icon;

    switch (type) {
      case MeetingType.personal:
        text = 'Cá nhân';
        icon = Icons.person;
        break;
      case MeetingType.team:
        text = 'Team';
        icon = Icons.group;
        break;
      case MeetingType.department:
        text = 'Phòng ban';
        icon = Icons.business;
        break;
      case MeetingType.company:
        text = 'Công ty';
        icon = Icons.corporate_fare;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7BE9).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7BE9).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF2E7BE9),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2E7BE9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPriorityChip(MeetingPriority priority) {
    Color color = _getPriorityColor(priority);
    String text;
    IconData icon;

    switch (priority) {
      case MeetingPriority.low:
        text = 'Thấp';
        icon = Icons.low_priority;
        break;
      case MeetingPriority.medium:
        text = 'Trung bình';
        icon = Icons.priority_high;
        break;
      case MeetingPriority.high:
        text = 'Cao';
        icon = Icons.priority_high;
        break;
      case MeetingPriority.urgent:
        text = 'Khẩn cấp';
        icon = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MeetingStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case MeetingStatus.pending:
        color = Colors.orange;
        text = 'Chờ phê duyệt';
        icon = Icons.pending;
        break;
      case MeetingStatus.approved:
        color = Colors.green;
        text = 'Đã phê duyệt';
        icon = Icons.check_circle;
        break;
      case MeetingStatus.rejected:
        color = Colors.red;
        text = 'Bị từ chối';
        icon = Icons.cancel;
        break;
      case MeetingStatus.cancelled:
        color = Colors.grey;
        text = 'Đã hủy';
        icon = Icons.cancel;
        break;
      case MeetingStatus.completed:
        color = Colors.blue;
        text = 'Đã hoàn thành';
        icon = Icons.done_all;
        break;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTypeChip(MeetingType type) {
    String text;
    switch (type) {
      case MeetingType.personal:
        text = 'Cá nhân';
        break;
      case MeetingType.team:
        text = 'Team';
        break;
      case MeetingType.department:
        text = 'Phòng ban';
        break;
      case MeetingType.company:
        text = 'Công ty';
        break;
    }

    return Chip(
      label: Text(text),
      backgroundColor: Colors.blue.shade100,
      labelStyle: TextStyle(color: Colors.blue.shade800),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPriorityChip(MeetingPriority priority) {
    Color color;
    String text;
    IconData icon;

    switch (priority) {
      case MeetingPriority.low:
        color = Colors.green;
        text = 'Thấp';
        icon = Icons.flag;
        break;
      case MeetingPriority.medium:
        color = Colors.orange;
        text = 'TB';
        icon = Icons.flag;
        break;
      case MeetingPriority.high:
        color = Colors.red;
        text = 'Cao';
        icon = Icons.flag;
        break;
      case MeetingPriority.urgent:
        color = Colors.red.shade900;
        text = 'Khẩn';
        icon = Icons.warning;
        break;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  bool _canManageMeeting(MeetingModel meeting, UserModel currentUser) {
    return meeting.creatorId == currentUser.id ||
        currentUser.isSuperAdmin ||
        currentUser.isAdmin;
  }

  bool _canApproveMeeting(UserModel currentUser) {
    return currentUser.isSuperAdmin ||
        currentUser.isAdmin ||
        currentUser.isManager;
  }

  void _navigateToCreateMeeting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeetingCreateScreen(),
      ),
    ).then((_) => _loadMeetings());
  }

  void _showMeetingDetails(MeetingModel meeting) {
    Navigator.pushNamed(
      context,
      '/meeting-detail',
      arguments: meeting.id,
    ).then((_) => _loadMeetings());
  }

  void _approveMeeting(MeetingModel meeting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      meetingProvider.approveMeeting(meeting.id, authProvider.userModel!);
    }
  }

  void _rejectMeeting(MeetingModel meeting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối cuộc họp'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement reject with reason
              Navigator.pop(context);
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _editMeeting(MeetingModel meeting) {
    // TODO: Implement edit meeting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tính năng chỉnh sửa sẽ được implement sau')),
    );
  }

  void _deleteMeeting(MeetingModel meeting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc họp'),
        content: Text('Bạn có chắc chắn muốn xóa cuộc họp "${meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (authProvider.userModel != null) {
                final success = await meetingProvider.deleteMeeting(
                    meeting.id, authProvider.userModel!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa cuộc họp')),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

enum MeetingListType {
  all,
  pending,
  myMeetings,
}
