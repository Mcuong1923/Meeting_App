import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import 'meeting_create_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({Key? key}) : super(key: key);

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  MeetingListType _selectedType = MeetingListType.today;

  // ===== Visual tokens (match new meeting list design screenshot) =====
  static const Color _screenBg = Color(0xFFF6F8FC);
  static const Color _accentPurple = Color(0xFF8E6BFF);
  static const Color _textPrimary = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _chipBorder = Color(0xFFE4E7EC);

  @override
  void initState() {
    super.initState();
    _loadMeetings();
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
      backgroundColor: _screenBg,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Responsive padding
          final screenWidth = MediaQuery.sizeOf(context).width;
          final scale = (screenWidth / 375).clamp(0.85, 1.3);
          final horizontalPadding = (16 * scale).clamp(12.0, 20.0);
          
          return Column(
            children: [
              // Dashboard Cards Grid
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 12 * scale,
                ),
                child: _buildDashboardCards(authProvider.userModel!),
              ),
              
              // Meeting List
              Expanded(
                child: _buildMeetingList(authProvider.userModel!, _selectedType),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) return const SizedBox();

          final canCreate =
              authProvider.userModel!.getAllowedMeetingTypes().isNotEmpty;

          if (canCreate) {
            return FloatingActionButton(
              onPressed: () => _navigateToCreateMeeting(),
              backgroundColor: _accentPurple,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 30),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDashboardCards(UserModel currentUser) {
    final meetingProvider = Provider.of<MeetingProvider>(context);
    final allMeetings = meetingProvider.meetings;
    
    // Responsive scale based on iPhone 11 (375px width)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    
    // Calculate aspect ratio based on screen width
    // Smaller screens need smaller aspect ratio (taller cards)
    final aspectRatio = screenWidth < 360 ? 1.1 : (screenWidth < 400 ? 1.2 : 1.3);
    
    // Calculate counts
    final todayCount = allMeetings.where((m) {
      final now = DateTime.now();
      return m.startTime.year == now.year &&
             m.startTime.month == now.month &&
             m.startTime.day == now.day;
    }).length;
    
    final allCount = allMeetings.length;
    
    final pendingCount = allMeetings.where((m) => m.isPending).length;
    
    final myMeetingsCount = allMeetings.where((m) =>
        m.creatorId == currentUser.id ||
        m.participants.any((p) => p.userId == currentUser.id)
    ).length;

    final spacing = (12 * scale).clamp(8.0, 16.0);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        _buildDashboardCard(
          title: 'Hôm nay',
          count: todayCount,
          icon: Icons.today_rounded,
          color: const Color(0xFFB8C5F2),
          isSelected: _selectedType == MeetingListType.today,
          onTap: () => setState(() => _selectedType = MeetingListType.today),
          scale: scale,
        ),
        _buildDashboardCard(
          title: 'Tất cả',
          count: allCount,
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFFFFF9B1),
          isSelected: _selectedType == MeetingListType.all,
          onTap: () => setState(() => _selectedType = MeetingListType.all),
          scale: scale,
        ),
        _buildDashboardCard(
          title: 'Chờ duyệt',
          count: pendingCount,
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFCBF3E7),
          isSelected: _selectedType == MeetingListType.pending,
          onTap: () => setState(() => _selectedType = MeetingListType.pending),
          scale: scale,
        ),
        _buildDashboardCard(
          title: 'Của tôi',
          count: myMeetingsCount,
          icon: Icons.person_rounded,
          color: const Color(0xFFFDD7E8),
          isSelected: _selectedType == MeetingListType.myMeetings,
          onTap: () => setState(() => _selectedType = MeetingListType.myMeetings),
          scale: scale,
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    double scale = 1.0,
  }) {
    // Responsive sizes
    final padding = (12 * scale).clamp(10.0, 16.0);
    final iconContainerPadding = (6 * scale).clamp(5.0, 8.0);
    final iconSize = (18 * scale).clamp(16.0, 22.0);
    final titleFontSize = (12 * scale).clamp(10.0, 14.0);
    final countFontSize = (30 * scale).clamp(22.0, 36.0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: _accentPurple.withOpacity(0.55), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconContainerPadding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF344054), size: iconSize),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF344054),
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2 * scale),
            Text(
              count.toString(),
              style: TextStyle(
                color: _textPrimary,
                fontSize: countFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
          case MeetingListType.today:
            final now = DateTime.now();
            meetings = meetingProvider.meetings.where((m) {
              return m.startTime.year == now.year &&
                     m.startTime.month == now.month &&
                     m.startTime.day == now.day;
            }).toList();
            break;
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

        // Responsive padding
        final screenWidth = MediaQuery.sizeOf(context).width;
        final scale = (screenWidth / 375).clamp(0.85, 1.3);
        final listPadding = (16 * scale).clamp(12.0, 20.0);
        
        return RefreshIndicator(
          onRefresh: () async => _loadMeetings(),
          child: ListView.separated(
            padding: EdgeInsets.all(listPadding),
            itemCount: meetings.length,
            separatorBuilder: (context, index) => SizedBox(height: 10 * scale),
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _buildMeetingCard(meeting, currentUser, scale);
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
      case MeetingListType.today:
        message = 'Hôm nay chưa có cuộc họp';
        subtitle = 'Các cuộc họp hôm nay sẽ hiển thị ở đây';
        icon = Icons.today_outlined;
        break;
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
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with circular background
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD), // Light blue background
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFF2196F3), // Blue icon
              ),
            ),
            const SizedBox(height: 24),
            
            // Message text (removed subtitle for cleaner look)
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Only show button for myMeetings type
            if (type == MeetingListType.myMeetings) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, UserModel currentUser, [double scale = 1.0]) {
    // Responsive sizes
    final padding = (12 * scale).clamp(10.0, 16.0);
    final iconBoxSize = (44 * scale).clamp(38.0, 52.0);
    final iconSize = (22 * scale).clamp(18.0, 26.0);
    final titleFontSize = (15 * scale).clamp(13.0, 17.0);
    final smallFontSize = (12 * scale).clamp(10.0, 14.0);
    final smallIconSize = (13 * scale).clamp(11.0, 15.0);
    
    return GestureDetector(
      onTap: () => _showMeetingDetails(meeting),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Icon Box
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.videocam_rounded,
                color: const Color(0xFF344054),
                size: iconSize,
              ),
            ),
            
            SizedBox(width: 10 * scale),
            
            // 2. Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meeting.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      _buildStatusBadge(meeting, scale),
                    ],
                  ),
                  SizedBox(height: 5 * scale),
                  
                  // Time Row
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: smallIconSize, color: _textSecondary),
                      SizedBox(width: 4 * scale),
                      Flexible(
                        child: Text(
                          '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)} • ${DateFormat('dd/MM').format(meeting.startTime)}',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: _textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 3 * scale),
                  
                  // Location & People Row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: smallIconSize, color: _textSecondary),
                      SizedBox(width: 4 * scale),
                      Flexible(
                        child: Text(
                          meeting.locationType == MeetingLocationType.virtual
                              ? 'Online'
                              : (meeting.physicalLocation ?? 'P...'),
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: _textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Icon(Icons.people_outline_rounded, size: smallIconSize, color: _textSecondary),
                      SizedBox(width: 4 * scale),
                      Text(
                        '${meeting.participants.length} người',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatusBadge(MeetingModel meeting, [double scale = 1.0]) {
    final now = DateTime.now();
    final isPast = meeting.endTime.isBefore(now);
    
    // Responsive sizes
    final hPadding = (8 * scale).clamp(6.0, 12.0);
    final vPadding = (4 * scale).clamp(3.0, 6.0);
    final fontSize = (10 * scale).clamp(9.0, 12.0);
    
    // If meeting has passed and is approved, treat as completed
    if (isPast && meeting.status == MeetingStatus.approved) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _chipBorder, width: 1),
        ),
        child: Text(
          'Hoàn thành',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
      );
    }
    
    // If meeting is completed status
    if (meeting.status == MeetingStatus.completed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _chipBorder, width: 1),
        ),
        child: Text(
          'Hoàn thành',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
          ),
        ),
      );
    }
    
    // Otherwise show status-based badge
    return _buildStatusBadgeOnly(meeting.status, scale);
  }

  Widget _buildStatusBadgeOnly(MeetingStatus status, [double scale = 1.0]) {
     // Responsive sizes
     final hPadding = (8 * scale).clamp(6.0, 12.0);
     final vPadding = (4 * scale).clamp(3.0, 6.0);
     final fontSize = (10 * scale).clamp(9.0, 12.0);
     
     Color color;
     String text;
     switch (status) {
       case MeetingStatus.pending:
         color = Colors.orange;
         text = 'Chờ duyệt';
         break;
       case MeetingStatus.approved:
         color = Colors.green;
         text = 'Sắp diễn ra';
         break;
       case MeetingStatus.rejected:
         color = Colors.red;
         text = 'Từ chối';
         break;
       case MeetingStatus.cancelled:
         color = Colors.grey;
         text = 'Đã hủy';
         break;
       case MeetingStatus.completed:
         color = Colors.blue;
         text = 'Hoàn thành';
         break;
       case MeetingStatus.expired:
         color = Colors.grey[600]!;
         text = 'Hết hạn';
         break;
     }
     
     return Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.85),
          ),
        ),
      );
  }

  // ... (keep helper methods)


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
      case MeetingStatus.expired:
        return 'Hết hạn';
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
      case MeetingStatus.expired:
        return Colors.grey[600]!;
    }
  }

  Color _getPriorityColor(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return const Color(0xFF4CAF50); // Green
      case MeetingPriority.medium:
        return const Color(0xFF9B59B6); // Purple
      case MeetingPriority.high:
        return const Color(0xFF9B7FED); // Light purple
      case MeetingPriority.urgent:
        return const Color(0xFFFF6B6B); // Coral/Red
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
      case MeetingStatus.expired:
        text = 'Hết hạn';
        icon = Icons.timer_off;
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
      case MeetingStatus.expired:
        color = Colors.grey[600]!;
        text = 'Hết hạn';
        icon = Icons.timer_off;
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
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      meetingProvider.approveMeeting(
        meeting.id,
        authProvider.userModel!,
        notificationProvider: notificationProvider,
      );
    }
  }

  void _rejectMeeting(MeetingModel meeting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối cuộc họp'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (authProvider.userModel != null) {
                meetingProvider.rejectMeeting(
                  meeting.id,
                  authProvider.userModel!,
                  reason: reasonController.text.trim(),
                  notificationProvider: notificationProvider,
                );
              }
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

  // Helper method to get gradient for card based on priority
  LinearGradient _getCardGradient(MeetingModel meeting) {
    switch (meeting.priority) {
      case MeetingPriority.urgent:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MeetingPriority.high:
        return const LinearGradient(
          colors: [Color(0xFF9B7FED), Color(0xFFB89FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Colors.white, Colors.white],
        );
    }
  }

  // Build rounded badge
  Widget _buildRoundedBadge(String text, Color color, bool isOnGradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnGradient ? Colors.white.withOpacity(0.25) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isOnGradient ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }



  // Build participant avatars
  Widget _buildParticipantAvatars(MeetingModel meeting, bool isOnGradient) {
    final participantCount = _getParticipantCount(meeting);
    
    // Mock participant data - in real app, this would come from meeting.participants
    final mockParticipants = List.generate(
      participantCount > 3 ? 3 : participantCount,
      (index) => 'User ${index + 1}',
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show up to 3 avatars
        ...mockParticipants.asMap().entries.map((entry) {
          final index = entry.key;
          final name = entry.value;
          return Container(
            margin: EdgeInsets.only(left: index > 0 ? 0 : 0),
            transform: Matrix4.translationValues(index * -6.0, 0, 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: _getAvatarColor(index),
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
        
        // Show count badge if more than 3 participants
        if (participantCount > 3)
          Container(
            margin: const EdgeInsets.only(left: 0),
            transform: Matrix4.translationValues(-6.0 * 3, 0, 0),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFF9B7FED),
              child: Text(
                '+${participantCount - 3}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Get avatar color based on index
  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    return colors[index % colors.length];
  }
  }


class MeetingCardClipper extends CustomClipper<Path> {
  final double radius;
  final double notchSize;

  MeetingCardClipper({this.radius = 24, this.notchSize = 48});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Start from top-left
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Top line to notch start
    path.lineTo(w - notchSize - radius / 2, 0);

    // Notch curve (smooth S-shape or scoop)
    path.quadraticBezierTo(
      w - notchSize / 3, 0, // Control point near top edge
      w - notchSize / 3, notchSize / 3, // Mid point
    );
    path.quadraticBezierTo(
       w, notchSize/3, // Control point near right edge
       w, notchSize // End point
    );

    // Right line
    path.lineTo(w, h - radius);

    // Bottom-right corner
    path.quadraticBezierTo(w, h, w - radius, h);

    // Bottom line
    path.lineTo(radius, h);

    // Bottom-left corner
    path.quadraticBezierTo(0, h, 0, h - radius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

enum MeetingListType {
  today,
  all,
  pending,
  myMeetings,
}
