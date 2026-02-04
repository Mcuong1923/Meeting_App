import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart' hide MeetingStatus;
import 'meeting_create_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({Key? key}) : super(key: key);

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  MeetingListType _selectedType = MeetingListType.today;

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
      backgroundColor: const Color(0xFFF8F9FD),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Dashboard Cards Grid
              Padding(
                padding: const EdgeInsets.all(16),
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
              backgroundColor: const Color(0xFF9B7FED),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 32),
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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3, // Increased from 1.6 to give more height
      children: [
        _buildDashboardCard(
          title: 'Hôm nay',
          count: todayCount,
          icon: Icons.today_rounded,
          color: const Color(0xFFB8C5F2), // Light blue-purple
          isSelected: _selectedType == MeetingListType.today,
          onTap: () => setState(() => _selectedType = MeetingListType.today),
        ),
        _buildDashboardCard(
          title: 'Tất cả',
          count: allCount,
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFFFFF9B1), // Light yellow
          isSelected: _selectedType == MeetingListType.all,
          onTap: () => setState(() => _selectedType = MeetingListType.all),
        ),
        _buildDashboardCard(
          title: 'Chờ duyệt',
          count: pendingCount,
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFCBF3E7), // Light cyan/mint
          isSelected: _selectedType == MeetingListType.pending,
          onTap: () => setState(() => _selectedType = MeetingListType.pending),
        ),
        _buildDashboardCard(
          title: 'Của tôi',
          count: myMeetingsCount,
          icon: Icons.person_rounded,
          color: const Color(0xFFFDD7E8), // Light pink
          isSelected: _selectedType == MeetingListType.myMeetings,
          onTap: () => setState(() => _selectedType = MeetingListType.myMeetings),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: const Color(0xFF9B7FED), width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF9B7FED).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey.shade700, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF2D2D2D),
                fontSize: 24,
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
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // Light blue background
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

  Widget _buildMeetingCard(MeetingModel meeting, UserModel currentUser) {
    return GestureDetector(
      onTap: () => _showMeetingDetails(meeting),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Icon Box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEBEBF0), // Light greyish background from image
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam_rounded, // Assuming video meetings based on image
                color: Color(0xFF2C1B47), // Dark purple/indigo
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 2. Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    meeting.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Time Row
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)} • ${DateFormat('dd/MM').format(meeting.startTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Location & People Row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meeting.locationType == MeetingLocationType.virtual
                              ? 'Online'
                              : (meeting.physicalLocation ?? 'Chưa có địa điểm'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${meeting.participants.length} người',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 3. Status Chip
            _buildStatusBadge(meeting),
          ],
        ),
      ),
    );
  }


  Widget _buildStatusBadge(MeetingModel meeting) {
    final now = DateTime.now();
    final isPast = meeting.endTime.isBefore(now);
    
    // If meeting has passed and is approved, treat as completed
    if (isPast && meeting.status == MeetingStatus.approved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBF0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Hoàn thành',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C1B47),
          ),
        ),
      );
    }
    
    // If meeting is completed status
    if (meeting.status == MeetingStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBF0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Hoàn thành',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C1B47),
          ),
        ),
      );
    }
    
    // Otherwise show status-based badge
    return _buildStatusBadgeOnly(meeting.status);
  }

  Widget _buildStatusBadgeOnly(MeetingStatus status) {
     Color color;
     String text;
     switch (status) {
       case MeetingStatus.pending:
         color = Colors.orange;
         text = 'Chờ duyệt';
         break;
       case MeetingStatus.approved:
         color = Colors.green;
         text = 'Sắp tới'; // Or 'Đã duyệt'
         break;
       case MeetingStatus.rejected:
         color = Colors.red;
         text = 'Từ chối';
         break;
       case MeetingStatus.cancelled:
         color = Colors.grey;
         text = 'Đã hủy';
         break;
       default:
         color = Colors.blue;
         text = 'Mới';
     }
     
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.8),
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
