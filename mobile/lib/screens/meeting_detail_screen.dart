import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meeting_model.dart';
import '../providers/meeting_provider.dart';
import '../providers/auth_provider.dart';
import '../models/meeting_task_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/meeting_decision_model.dart';
import '../models/meeting_task_model.dart';
import '../models/meeting_note_model.dart';
import '../models/meeting_comment_model.dart';
import '../models/meeting_minutes_model.dart';
import 'package:file_picker/file_picker.dart';
import 'task_management_screen.dart';
import 'meeting_minutes_editor_screen.dart';
import '../providers/meeting_minutes_provider.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  const MeetingDetailScreen({Key? key, required this.meetingId})
      : super(key: key);

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data - will be replaced with real data later
  // List<MeetingDecision> _decisions = []; // Moved to provider
  List<MeetingTask> _tasks = [];
  List<MeetingNote> _notes = [];
  List<MeetingComment> _comments = [];
  List<Map<String, dynamic>> _files = []; // File attachments
  List<MeetingMinutesModel> _minutesVersions = []; // Meeting minutes versions

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load decisions and log entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MeetingProvider>();
      final now = DateTime.now().toIso8601String();
      final providerHash = provider.providerHash;
      
      print('[MEETING_DETAIL][ENTER] meetingId=${widget.meetingId} time=$now providerHash=$providerHash');
      
      provider.loadDecisions(widget.meetingId);
      provider.loadTasks(widget.meetingId); // Load tasks for current meeting
    
    // Load meeting minutes
    if (mounted) {
      final minutesProvider = context.read<MeetingMinutesProvider>();
      minutesProvider.getLatestMinute(widget.meetingId);
      minutesProvider.getMinutesForMeeting(widget.meetingId);
    }
      // _loadMockData(); // No longer needed
    });
  }

  @override
  void dispose() {
    final provider = context.read<MeetingProvider>();
    final providerHash = provider.providerHash;
    
    print('[MEETING_DETAIL][LEAVE] meetingId=${widget.meetingId} providerHash=$providerHash clearState=false cancelSub=false');
    
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        // Clear all mock data for production-like empty state
        // _decisions = []; // Moved to provider
        _tasks = [];
        _notes = [];
        _comments = [];
        _minutesVersions = [];
        
        // _loading = false; // Moved to provider
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.watch<MeetingProvider>().isLoading;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Chi tiết cuộc họp',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface, size: 24),
            tooltip: 'Tải lại',
            onPressed: isLoading ? null : () {
              context.read<MeetingProvider>().loadDecisions(widget.meetingId);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<MeetingProvider, AuthProvider>(
              builder: (context, meetingProvider, authProvider, child) {
                // Always fetch from Firestore to ensure migration runs for pending participants
                return FutureBuilder<MeetingModel?>(
                  future: meetingProvider.getMeetingById(widget.meetingId),
                  builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                     }
                     
                     if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                       return Center(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             const Icon(Icons.error_outline, size: 48, color: Colors.red),
                             const SizedBox(height: 16),
                             Text('Không tìm thấy cuộc họp\nID: ${widget.meetingId}', textAlign: TextAlign.center),
                           ],
                         ),
                       );
                     }
                     
                     // Check access permission
                     final fetchedMeeting = snapshot.data!;
                     final currentUser = authProvider.userModel;
                     
                     // Access check logic (Client-side)
                     bool canView = false;
                     if (currentUser != null) {
                       if (currentUser.isAdmin || currentUser.isDirector) {
                         canView = true;
                       } else if (fetchedMeeting.creatorId == currentUser.id) {
                         canView = true;
                       } else if (fetchedMeeting.participants.any((p) => p.userId == currentUser.id)) {
                         canView = true;
                       }
                     }
                     
                     if (!canView) {
                        return const Center(child: Text('Bạn không có quyền xem cuộc họp này'));
                     }

                     return _buildMeetingContent(fetchedMeeting, authProvider.userModel);
                  },
                );
              },
            ),
    );
  }

  Widget _buildMeetingContent(MeetingModel meeting, UserModel? currentUser) {
    return Column(
      children: [
        // Header Section
        _buildHeader(meeting),
        // TabBar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            padding: EdgeInsets.zero,
            tabs: const [
              Tab(text: 'Chi tiết'),
              Tab(text: 'Bình luận'),
              Tab(text: 'Tài liệu'),
              Tab(text: 'Biên bản'),
            ],
          ),
        ),
        
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(meeting, currentUser),
              _buildCommentsTab(currentUser),
              _buildFilesTab(currentUser),
              _buildMinutesTab(meeting, currentUser),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildHeader(MeetingModel meeting) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            meeting.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Time and Date
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '• ${DateFormat('dd/MM/yyyy').format(meeting.startTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Badges Row with M3 AssistChips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Participants chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${meeting.participants.length} người',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Priority badge
              _buildPriorityBadge(meeting.priority),
              
              // Status badge (using existing logic)
              _buildStatusBadge(meeting),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(MeetingPriority priority) {
    Color color;
    String text;
    IconData icon;
    
    switch (priority) {
      case MeetingPriority.low:
        color = Colors.green;
        text = 'Thấp';
        icon = Icons.flag_outlined;
        break;
      case MeetingPriority.medium:
        color = Colors.orange;
        text = 'Trung bình';
        icon = Icons.flag_outlined;
        break;
      case MeetingPriority.high:
        color = Colors.deepOrange;
        text = 'Cao';
        icon = Icons.flag_rounded;
        break;
      case MeetingPriority.urgent:
        color = Colors.red;
        text = 'Khẩn cấp';
        icon = Icons.flag_rounded;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MeetingModel meeting) {
    final now = DateTime.now();
    final isPast = meeting.endTime.isBefore(now);
    
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C1B47),
          ),
        ),
      );
    }
    
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C1B47),
          ),
        ),
      );
    }
    
    Color color;
    String text;
    
    switch (meeting.status) {
      case MeetingStatus.pending:
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case MeetingStatus.approved:
        color = Colors.green;
        text = 'Đã duyệt';
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailsTab(MeetingModel meeting, UserModel? currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Info Card
          _buildSummaryCard(meeting),
          const SizedBox(height: 16),
          
          // Participants Card
          _buildParticipantsCard(meeting),
          const SizedBox(height: 16),
          
          // Decisions Card
          _buildDecisionsCard(meeting, currentUser),
          const SizedBox(height: 16),
          
          // Tasks Card
          _buildTasksCard(meeting, currentUser),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MeetingModel meeting) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Thông tin tóm tắt',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Mã tài', 'sss'),
            const SizedBox(height: 12),
            _buildInfoRow('Người tổ chức', meeting.creatorName),
            const SizedBox(height: 12),
            _buildInfoRow('Loại cuộc họp', _getMeetingTypeText(meeting.type)),
          ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _getMeetingTypeText(MeetingType type) {
    switch (type) {
      case MeetingType.personal:
        return 'Cá nhân';
      case MeetingType.team:
        return 'Nhóm';
      case MeetingType.department:
        return 'Phòng ban';
      case MeetingType.company:
        return 'Công ty';
    }
  }

  Widget _buildParticipantsCard(MeetingModel meeting) {
    // Sort participants: chair -> secretary -> others
    final sortedParticipants = List<dynamic>.from(meeting.participants);
    sortedParticipants.sort((a, b) {
      if (a.role == 'chair') return -1;
      if (b.role == 'chair') return 1;
      if (a.role == 'secretary') return -1;
      if (b.role == 'secretary') return 1;
      return 0;
    });

    final confirmedCount =
        meeting.participants.where((p) => p.hasConfirmed).length;
    final totalCount = meeting.participants.length;
    
    // Empty state
    if (totalCount == 0) {
      return Container(
        width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Người tham gia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có người tham gia',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showAllParticipants(sortedParticipants),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Người tham gia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B7FED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content Row
            Row(
              children: [
                // Avatar Stack
                SizedBox(
                  width: _calculateStackWidth(totalCount),
                  height: 44, // 20 radius * 2 + 4/2 border? ~44px
                  child: Stack(
                    children: [
                      // Show up to 4 avatars
                      for (int i = 0; i < (totalCount > 4 ? 4 : totalCount); i++)
                        Positioned(
                          left: i * 32.0, // Reduced overlap for better spacing
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?u=${sortedParticipants[i].userId}',
                              ),
                              backgroundColor:
                                  const Color(0xFF9B7FED).withOpacity(0.2),
                            ),
                          ),
                        ),
                        
                      // If more than 4, show +N bubble
                      if (totalCount > 4)
                        Positioned(
                          left: 4 * 32.0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                '+${totalCount - 4}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCount người tham gia',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$confirmedCount đã xác nhận',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Chevron
                 Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateStackWidth(int count) {
    // 40px width per avatar (radius 20*2)
    // 32px offset per overlap (increased from 28 for better spacing)
    // If count > 4, we show 4 avatars + 1 bubble = 5 items total
    int itemsToShow = count > 4 ? 5 : count;
    if (itemsToShow == 0) return 0;
    // Width = (items-1)*offset + fullWidthOfLastItem
    // Width = (items-1)*32 + 44 (including border)
    return (itemsToShow - 1) * 32.0 + 44.0;
  }

  void _showAllParticipants(List<dynamic> participants) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Bottom Sheet Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Người tham gia (${participants.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Filter chips (Optional Placeholder)
                  // SingleChildScrollView(...)
                  
                  // List
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: participants.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final p = participants[index];
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  const Color(0xFF9B7FED).withOpacity(0.2),
                              child: Text(
                                p.userName.isNotEmpty
                                    ? p.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF9B7FED),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (p.role != 'participant')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getParticipantRoleText(p.role),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: p.hasConfirmed
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.hasConfirmed ? 'Đã xác nhận' : 'Đang chờ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: p.hasConfirmed
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getParticipantRoleText(String role) {
    switch (role) {
      case 'chair':
        return 'Chủ trì';
      case 'secretary':
        return 'Thư ký';
      case 'presenter':
        return 'Báo cáo';
      default:
        return '';
    }
  }

  Widget _buildDecisionsCard(MeetingModel meeting, UserModel? currentUser) {
    final decisions = context.watch<MeetingProvider>().decisions;
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông nhất & Quyết định',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          
          // Decisions list
          if (decisions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Chưa có quyết định nào',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...decisions.map((decision) {
              return _buildDecisionItem(decision, currentUser);
            }).toList(),
          
          // Add decision button
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              _showAddDecisionDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF9B7FED).withOpacity(0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      size: 20, color: Color(0xFF9B7FED)),
                  SizedBox(width: 6),
                  Text(
                    'Thêm quyết định mới',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9B7FED),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionItem(MeetingDecision decision, UserModel? currentUser) {
    final userId = currentUser?.id ?? '';
    final userReaction = decision.getUserReaction(userId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decision content
          Text(
            decision.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          
          // Reaction buttons
          Row(
            children: [
              // Agree button
              _buildReactionButton(
                icon: Icons.thumb_up_rounded,
                color: const Color(0xFF2196F3),
                count: decision.getReactionCount(DecisionReaction.agree),
                isSelected: userReaction == DecisionReaction.agree,
                onTap: () => _handleReaction(decision, DecisionReaction.agree),
              ),
              const SizedBox(width: 8),
              
              // Disagree button
              _buildReactionButton(
                icon: Icons.thumb_down_rounded,
                color: Colors.red,
                count: decision.getReactionCount(DecisionReaction.disagree),
                isSelected: userReaction == DecisionReaction.disagree,
                onTap: () =>
                    _handleReaction(decision, DecisionReaction.disagree),
              ),
              const SizedBox(width: 8),
              
              // Neutral button
              _buildReactionButton(
                icon: Icons.sentiment_neutral_rounded,
                color: Colors.grey,
                count: decision.getReactionCount(DecisionReaction.neutral),
                isSelected: userReaction == DecisionReaction.neutral,
                onTap: () => _handleReaction(decision, DecisionReaction.neutral),
              ),
              const SizedBox(width: 8),
              
              // Finalize button - always show, but gray when finalized
              Flexible(
                child: InkWell(
                  onTap: decision.isFinal
                      ? () {
                          // Show "Already finalized" message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Đã chốt kết quả rồi'),
                                ],
                              ),
                              backgroundColor: Colors.grey.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : () => _handleFinalize(decision, currentUser),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: decision.isFinal 
                          ? Colors.grey.shade400 
                          : const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            decision.isFinal ? 'Đã chốt' : 'Chốt kết quả',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              

              
              // Delete button - show to all, but check permission on tap
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _handleDeleteDecision(decision, currentUser),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom Footer: Convert to task button - only show after finalization
          if (decision.isFinal)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: decision.taskId != null
                    ? InkWell(
                        onTap: () {
                          final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
                          final meetings = meetingProvider.meetings;
                          print('[MEETING_DETAIL][NAV] meetingsCount=${meetings.length} targetId=${widget.meetingId}');
                          
                          if (meetings.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Không tìm thấy thông tin cuộc họp (List empty)'), backgroundColor: Colors.red),
                             );
                             return;
                          }

                          final meeting = meetings.firstWhere(
                            (m) => m.id == widget.meetingId,
                            orElse: () {
                              print('[MEETING_DETAIL][NAV] Warning: Meeting not found in list, using first one');
                              return meetings.first;
                            },
                          );
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskManagementScreen(
                                meeting: meeting,
                                initialTasks: _tasks,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.visibility_outlined,
                                  size: 16, color: Color(0xFF1976D2)),
                              SizedBox(width: 8),
                              Text(
                                'Xem công việc',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showConvertToTaskDialog(decision, currentUser),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.assignment_turned_in_outlined,
                                  size: 16, color: Color(0xFF1976D2)),
                              SizedBox(width: 8),
                              Text(
                                'Chuyển đổi thành nhiệm vụ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          

        ],
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required Color color,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleReaction(MeetingDecision decision, DecisionReaction reaction) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;
    
    // Create new reactions map
    final Map<String, DecisionReaction> newReactions = Map.from(decision.reactions);
    final currentReaction = newReactions[currentUser.id];
    
    if (currentReaction == reaction) {
      // Remove reaction if clicking same button
      newReactions.remove(currentUser.id);
    } else {
      // Add or update reaction
      newReactions[currentUser.id] = reaction;
    }
    
    // Create updated decision
    final updatedDecision = decision.copyWith(reactions: newReactions);
    
    // Update in provider
    await context.read<MeetingProvider>().updateDecision(updatedDecision);
  }

  void _handleFinalize(MeetingDecision decision, UserModel? currentUser) async {
    // Check permission - only creator or admin can finalize
    final isCreator = decision.createdBy == (currentUser?.id ?? '');
    final isAdmin = currentUser?.isAdmin ?? false;
    
    if (!isCreator && !isAdmin) {
      _showPermissionDeniedDialog();
      return;
    }
    
    // Finalize the decision
    final updatedDecision = decision.copyWith(
      isFinal: true,
      finalizedBy: currentUser?.id,
      finalizedByName: currentUser?.displayName,
      finalizedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await context.read<MeetingProvider>().updateDecision(updatedDecision);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Đã chốt kết quả thành công'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDeleteDecision(MeetingDecision decision, UserModel? currentUser) {
    // Check permission - only creator or admin can delete
    final isCreator = decision.createdBy == (currentUser?.id ?? '');
    final isAdmin = currentUser?.isAdmin ?? false;
    
    if (!isCreator && !isAdmin) {
      _showPermissionDeniedDialog();
      return;
    }
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa quyết định này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<MeetingProvider>().deleteDecision(decision.id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9B7FED).withOpacity(0.2),
                      const Color(0xFF9B7FED).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF9B7FED),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Không có quyền',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'Bạn không có quyền thực hiện hành động này. Chỉ người tạo quyết định hoặc Admin mới có thể chốt kết quả hoặc xóa quyết định.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B7FED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDecisionDialog() {
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thêm quyết định mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content Input
                TextFormField(
                  controller: contentController,
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung quyết định...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9B7FED)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FD),
                  ),
                  maxLines: 4,
                  minLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập nội dung quyết định';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setModalState(() => isSubmitting = true);
                                  
                                  try {
                                    final currentUser = context.read<AuthProvider>().userModel;
                                    if (currentUser == null) return;
                                    
                                    // Create new decision
                                    final newDecision = MeetingDecision(
                                      id: '', // Will be generated by Firestore
                                      meetingId: widget.meetingId,
                                      content: contentController.text.trim(),
                                      createdBy: currentUser.id,
                                      createdByName: currentUser.displayName,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );
                                    
                                    final success = await context
                                        .read<MeetingProvider>()
                                        .addDecision(newDecision);
                                        
                                    if (mounted) {
                                      Navigator.pop(context);
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã thêm quyết định mới'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Không thể thêm quyết định'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    print('Error adding decision: $e');
                                    if (mounted) {
                                      setModalState(() => isSubmitting = false);
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B7FED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Tạo quyết định',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConvertToTaskDialog(MeetingDecision decision, UserModel? currentUser) {
    final titleController = TextEditingController(text: decision.content);
    final descriptionController = TextEditingController();
    String selectedAssigneeId = currentUser?.id ?? '';
    String selectedPriority = 'medium';
    String selectedStatus = MeetingTaskStatus.pending;
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    double progressValue = 0.0;
    bool isTitleEmpty = titleController.text.trim().isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          titleController.addListener(() {
            final isEmpty = titleController.text.trim().isEmpty;
            if (isTitleEmpty != isEmpty) {
              setModalState(() => isTitleEmpty = isEmpty);
            }
          });
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // 1. Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_add,
                          color: Color(0xFF9B7FED),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giao nhiệm vụ mới',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tạo nhanh nhiệm vụ từ quyết định',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Body (Scrollable Form)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group A: Basic Info
                        _buildSectionLabel('THÔNG TIN CƠ BẢN'),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Tiêu đề nhiệm vụ',
                            hintText: 'Nhập tiêu đề...',
                            errorText: isTitleEmpty ? 'Vui lòng nhập tiêu đề' : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Mô tả chi tiết',
                            hintText: 'Nhập mô tả...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Group B: Assignment & Deadline
                        _buildSectionLabel('PHÂN CÔNG & THỜI HẠN'),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Người thực hiện', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFFAFAFA),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: const Color(0xFF9B7FED),
                                          child: Text(
                                            currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: selectedAssigneeId.isEmpty ? null : selectedAssigneeId,
                                              hint: const Text('Chọn người', style: TextStyle(fontSize: 13)),
                                              isExpanded: true,
                                              items: [
                                                DropdownMenuItem(
                                                  value: currentUser?.id ?? 'user1',
                                                  child: Text(
                                                    currentUser?.displayName ?? 'Tôi',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) setModalState(() => selectedAssigneeId = val);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Hạn hoàn thành', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDeadline,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setModalState(() => selectedDeadline = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFFFAFAFA),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF666666)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Group C: Priority & Status
                        _buildSectionLabel('CẤU HÌNH NHIỆM VỤ'),
                        const SizedBox(height: 12),
                        
                        const Text('Mức độ ưu tiên', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildPriorityChip('Thấp', 'low', selectedPriority, (val) => setModalState(() => selectedPriority = val)),
                              _buildPriorityChip('Trung bình', 'medium', selectedPriority, (val) => setModalState(() => selectedPriority = val)),
                              _buildPriorityChip('Cao', 'high', selectedPriority, (val) => setModalState(() => selectedPriority = val)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Trạng thái khởi tạo', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildStatusChip('Chờ xử lý', 'pending', selectedStatus, (val) => setModalState(() => selectedStatus = val), Colors.orange),
                              _buildStatusChip('Đang làm', 'in_progress', selectedStatus, (val) => setModalState(() => selectedStatus = val), Colors.blue),
                              _buildStatusChip('Hoàn thành', 'completed', selectedStatus, (val) => setModalState(() => selectedStatus = val), Colors.green),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Group D: Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionLabel('TIẾN ĐỘ THỰC HIỆN'),
                            Text(
                              '${progressValue.round()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9B7FED),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            activeTrackColor: const Color(0xFF9B7FED),
                            inactiveTrackColor: const Color(0xFFE0E0E0),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
                            overlayColor: const Color(0xFF9B7FED).withOpacity(0.1),
                          ),
                          child: Slider(
                            value: progressValue,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (value) => setModalState(() => progressValue = value),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // 3. Footer (Actions)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text('Hủy bỏ', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isTitleEmpty ? null : () {
                            final now = DateTime.now();
                            final newTask = MeetingTask(
                              id: 'task_${now.millisecondsSinceEpoch}',
                              meetingId: widget.meetingId,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              assigneeId: selectedAssigneeId,
                              assigneeName: currentUser?.displayName ?? 'Unknown',
                              assigneeRole: currentUser?.role?.toString() ?? 'Member',
                              deadline: selectedDeadline,
                              status: selectedStatus,
                              priority: selectedPriority,
                              progress: progressValue.round(),
                              createdBy: currentUser?.id ?? '',
                              createdByName: currentUser?.displayName ?? 'Unknown',
                              createdAt: now,
                              updatedAt: now,
                            );

                            // Save task to Firestore via Provider
                            context.read<MeetingProvider>().addTask(newTask).then((docId) {
                              if (docId == null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Lỗi tạo công việc'), backgroundColor: Colors.red),
                                );
                              } else if (docId != null && mounted) {
                                // Reload tasks for current meeting to refresh the task section
                                context.read<MeetingProvider>().loadTasks(widget.meetingId);
                              }
                            });

                            // Update decision with taskId via Provider
                            context.read<MeetingProvider>().updateDecision(
                              decision.copyWith(taskId: newTask.id),
                            );

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle_rounded, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Đã tạo nhiệm vụ thành công'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B7FED),
                            disabledBackgroundColor: const Color(0xFFE0E0E0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Tạo nhiệm vụ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, String groupValue, Function(String) onSelect) {
    final isSelected = value == groupValue;
    Color color;
    switch (value) {
      case 'high': color = Colors.orange; break;
      case 'low': color = Colors.green; break;
      default: color = Colors.blue;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, String groupValue, Function(String) onSelect, Color activeColor) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to Task Management Screen
  void _navigateToTaskManagement() {
    final provider = context.read<MeetingProvider>();
    final meetings = provider.meetings;
    
    print('[MEETING_DETAIL][NAV] meetingsCount=${meetings.length} targetId=${widget.meetingId}');
    
    if (meetings.isEmpty) {
      print('[MEETING_DETAIL][NAV] ERROR: meetings list is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin cuộc họp')),
        );
      }
      return;
    }
    
    final meeting = meetings.firstWhere(
      (m) => m.id == widget.meetingId,
      orElse: () {
        print('[MEETING_DETAIL][NAV] WARN: meeting not found in list');
        return meetings.first; // Fallback
      },
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskManagementScreen(meeting: meeting),
      ),
    );
  }


  Widget _buildTasksCard(MeetingModel meeting, UserModel? currentUser) {
    final provider = context.watch<MeetingProvider>();
    final allTasks = provider.getTasksForMeeting(widget.meetingId);
    final displayTasks = allTasks.take(3).toList();
    final isLoading = provider.isLoading;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhiệm vụ cần làm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (allTasks.isNotEmpty)
                InkWell(
                  onTap: _navigateToTaskManagement,
                  child: const Text(
                    'Xem công việc →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Loading state
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          // Empty state
          else if (allTasks.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có nhiệm vụ nào', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Show create task dialog (not part of current scope)
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Tạo nhiệm vụ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ]
          // Tasks list
          else ...[
            ...displayTasks.map((task) {
              return _buildTaskItem(task);
            }).toList(),
            
            // "Xem tất cả" if more than 3 tasks
            if (allTasks.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _navigateToTaskManagement,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text('Xem thêm ${allTasks.length - 3} nhiệm vụ'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(MeetingTask task) {
    return InkWell(
      onTap: _navigateToTaskManagement,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title + Status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTaskStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.getStatusText(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getTaskStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Row 2: Progress bar + Percentage
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTaskStatusColor(task.status),
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${task.progress}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Row 3: Assignee + Due date
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFF9B7FED).withOpacity(0.2),
                  child: Text(
                    task.assigneeName.isNotEmpty
                        ? task.assigneeName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF9B7FED),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  task.assigneeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: task.isOverdue ? Colors.red : Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(task.deadline),
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilesTab(UserModel? currentUser) {
    return Column(
      children: [
        // Upload button at top
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_rounded, size: 20),
            label: const Text('Tải lên tài liệu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B7FED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        // File list
        Expanded(
          child: _files.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có tài liệu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    return _buildFileItem(_files[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // File icon - larger and more prominent
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileIconColor(file['name'] ?? '').withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(file['name'] ?? ''),
              size: 28,
              color: _getFileIconColor(file['name'] ?? ''),
            ),
          ),
          const SizedBox(width: 14),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(file['size'] ?? 0),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Delete button only
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            color: Colors.grey.shade600,
            onPressed: () {
              setState(() {
                _files.remove(file);
              });
            },
          ),
        ],
      ),
    );
  }

  Color _getFileIconColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'doc':
      case 'docx':
        return const Color(0xFF1976D2);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF388E3C);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return const Color(0xFFF57C00);
      case 'zip':
      case 'rar':
        return const Color(0xFF7B1FA2);
      case 'txt':
        return const Color(0xFF5B7FED);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            _files.add({
              'name': file.name,
              'size': file.size,
              'path': file.path,
              'uploadedBy': 'Current User',
              'uploadedAt': DateTime.now(),
            });
          }
        });
      }
    } catch (e) {
      // Handle error
      print('Error picking file: $e');
    }
  }


  Widget _buildNotesTab(UserModel? currentUser) {
    return Column(
      children: [
        Expanded(
          child: _notes.isEmpty
              ? const Center(
                  child: Text('Chưa có ghi chú nào'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return _buildNoteItem(note, currentUser);
                  },
                ),
        ),
        
        // Add note button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],//
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Show add note dialog
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Thêm ghi chú'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B7FED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(MeetingNote note, UserModel? currentUser) {
    final isOwner = note.createdBy == (currentUser?.id ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF9B7FED).withOpacity(0.2),
                child: Text(
                  note.createdByName.isNotEmpty
                      ? note.createdByName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF9B7FED),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.createdByName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: Colors.grey.shade600),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      // TODO: Edit note
                    } else if (value == 'delete') {
                      setState(() {
                        _notes.removeWhere((n) => n.id == note.id);
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(UserModel? currentUser) {
    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? const Center(
                  child: Text('Chưa có bình luận nào'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return _buildCommentItem(comment);
                  },
                ),
        ),
        
        // Comment input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Viết bình luận...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF9B7FED),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      // TODO: Send comment
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(MeetingComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF9B7FED).withOpacity(0.2),
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFF9B7FED),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ MEETING MINUTES TAB ============

  /// Check if user is global admin
  bool _isGlobalAdmin(UserModel? user) {
    if (user == null) return false;
    return user.isAdmin;
  }

  /// Check if user is secretary or chair in this meeting
  bool _isSecretaryOrChair(MeetingModel meeting, UserModel? user) {
    if (user == null) return false;
    
    // Global admin has all permissions
    if (_isGlobalAdmin(user)) return true;
    
    // Check meeting participant role
    try {
      final participant = meeting.participants.firstWhere(
        (p) => p.userId == user.id,
      );
      return participant.role == 'secretary' || participant.role == 'chair';
    } catch (e) {
      return false;
    }
  }

  /// Helper: Check if current user is Secretary of THIS meeting (Explicit)
  bool _isSecretaryOfMeeting(MeetingModel meeting, UserModel user) {
    return meeting.participants.any((p) => 
      p.userId == user.id && p.role == 'secretary'
    );
  }

  /// Check if user can view this minute
  bool _canViewMinute(MeetingMinutesModel minute, UserModel user, MeetingModel meeting) {
    // Admin sees everything
    if (user.role == UserRole.admin) return true;
    
    // Draft/Pending: Only Secretary or Chair (Creator) or Admin
    if (minute.status == MinutesStatus.draft || 
        minute.status == MinutesStatus.pending_approval) {
      return _isSecretaryOrChair(meeting, user);
    }
    
    // Approved: All participants
    if (minute.status == MinutesStatus.approved) {
      return meeting.participants.any((p) => p.userId == user.id);
    }
    
    // Rejected: Same as draft/pending
    return _isSecretaryOrChair(meeting, user);
  }

  /// Check if user can approve minutes (Global Admin ONLY)
  bool _canApproveMinutes(MeetingModel meeting, UserModel? user) {
    if (user == null) return false;
    
    // ONLY Global admin can approve
    return _isGlobalAdmin(user);
    
    // Chair CANNOT approve anymore per strict requirements
    /*
    // Chair can approve
    try {
      final participant = meeting.participants.firstWhere(
        (p) => p.userId == user.id,
      );
      return participant.role == 'chair';
    } catch (e) {
      return false;
    }
    */
  }

  Widget _buildMinutesTab(MeetingModel meeting, UserModel? currentUser) {
    if (currentUser == null) return const SizedBox.shrink();
    
    return Consumer<MeetingMinutesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle Index Error
        if (provider.error != null && provider.error!.contains('failed-precondition')) {
          return _buildIndexErrorBanner(provider.error!);
        }

        final currentVersion = provider.currentVersion;
        final hasPermission = _isSecretaryOrChair(meeting, currentUser);
        
        // Strict Visibility Check
        if (currentVersion != null && !_canViewMinute(currentVersion, currentUser, meeting)) {
          return _buildNoPermissionState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Version Section
              _buildCurrentVersionSection(meeting, currentUser, currentVersion, hasPermission),
              const SizedBox(height: 24),
              
              // Version History Section (Hidden for now or simplified)
              // _buildVersionHistorySection(meeting, currentUser, hasPermission),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoPermissionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có biên bản chính thức',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 32, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'Cần tạo Index Firestore',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng kiểm tra console log để lấy link tạo index.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentVersionSection(
    MeetingModel meeting,
    UserModel? currentUser,
    MeetingMinutesModel? currentVersion,
    bool hasPermission,
  ) {
    final isAdmin = currentUser?.role == UserRole.admin;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Biên bản cuộc họp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (currentVersion != null)
                _buildMinutesStatusBadge(currentVersion.status),
            ],
          ),
          const SizedBox(height: 16),
          
          if (currentVersion == null) ...[
            // No minutes existence
            Center(
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có biên bản',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (hasPermission) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToMinutesEditor(meeting, null),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tạo biên bản'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B7FED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Archive Tag
            if (currentVersion.isArchived)
               Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(6),
                   border: Border.all(color: Colors.grey.shade300),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(Icons.archive_outlined, size: 14, color: Colors.grey.shade700),
                     const SizedBox(width: 6),
                     Text(
                       'Đã lưu trữ',
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.w600,
                         color: Colors.grey.shade700,
                       ),
                     ),
                   ],
                 ),
               ),
               
            // Info Row
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Cập nhật: ${currentVersion.updatedByName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(currentVersion.updatedAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getContentPreview(currentVersion.content),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showMinutesDetail(currentVersion),
                    child: Text(
                      'Xem thêm →',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF9B7FED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Pending Message for Non-Admin
            if (currentVersion.isPending && !isAdmin && hasPermission)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Đang chờ Admin phê duyệt',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // View (Always visible if we reached here)
                _buildMinutesActionButton(
                  'Xem',
                  Icons.visibility_outlined,
                  const Color(0xFF9B7FED),
                  () => _showMinutesDetail(currentVersion),
                ),
                
                // Edit (Draft + Permission)
                if (hasPermission && currentVersion.isDraft)
                  _buildMinutesActionButton(
                    'Sửa',
                    Icons.edit_outlined,
                    const Color(0xFF9B7FED),
                    () => _navigateToMinutesEditor(meeting, currentVersion),
                  ),
                
                // Submit (Draft + Permission)
                if (hasPermission && currentVersion.isDraft)
                  _buildMinutesActionButton(
                    isAdmin ? 'Duyệt & Phát hành' : 'Gửi duyệt',
                    isAdmin ? Icons.check_circle_rounded : Icons.send_rounded,
                    isAdmin ? Colors.green : Colors.blue,
                    () => _submitMinutesForApproval(currentVersion),
                  ),
                  
                // Approve (Pending + Admin)
                if (isAdmin && currentVersion.isPending)
                  _buildMinutesActionButton(
                    'Duyệt',
                    Icons.check_circle_outline_rounded,
                    Colors.green,
                    () => _approveMinutes(currentVersion, currentUser),
                  ),
                  
                // Reject (Pending + Admin)
                if (isAdmin && currentVersion.isPending)
                  _buildMinutesActionButton(
                    'Từ chối',
                    Icons.cancel_outlined,
                    Colors.red,
                    () => _rejectMinutes(currentVersion),
                  ),

                // Archive (Approved + NotArchived + (Admin or Secretary))
                if (currentVersion.isApproved && !currentVersion.isArchived && (isAdmin || hasPermission))
                   _buildMinutesActionButton(
                    'Lưu trữ',
                    Icons.archive_outlined,
                    Colors.orange,
                    () => _archiveMinute(currentVersion),
                  ),
                  
                // Unarchive (Archived + (Admin or Secretary))
                if (currentVersion.isArchived && (isAdmin || hasPermission))
                   _buildMinutesActionButton(
                    'Gỡ lưu trữ',
                    Icons.unarchive_outlined,
                    Colors.grey,
                    () => _unarchiveMinute(currentVersion),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionHistorySection(
    MeetingModel meeting,
    UserModel? currentUser,
    bool hasPermission,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử biên bản',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (hasPermission)
                TextButton.icon(
                  onPressed: () => _navigateToMinutesEditor(meeting, null),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tạo biên bản mới'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9B7FED),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_minutesVersions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Chưa có lịch sử biên bản',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _minutesVersions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final version = _minutesVersions[index];
                return _buildVersionHistoryItem(version, meeting, currentUser, hasPermission);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVersionHistoryItem(
    MeetingMinutesModel version,
    MeetingModel meeting,
    UserModel? currentUser,
    bool hasPermission,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Biên bản #${version.versionNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              _buildMinutesStatusBadge(version.status),
              const Spacer(),
              if (hasPermission && version.canEdit)
                GestureDetector(
                  onTap: () => _navigateToMinutesEditor(meeting, version),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B7FED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B7FED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (hasPermission && version.canDelete) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteMinutesVersion(version),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Content preview
          Text(
            _getContentPreview(version.content),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Metadata
          Row(
            children: [
              if (version.isApproved && version.approvedByName != null) ...[
                Text(
                  'Gửi: ${version.updatedByName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  ' (${DateFormat('dd/MM/yyyy HH:mm').format(version.updatedAt)})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ] else ...[
                Text(
                  '• Tạo: ${version.createdByName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  ' • ${DateFormat('dd/MM/yyyy').format(version.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesStatusBadge(MinutesStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    
    switch (status) {
      case MinutesStatus.draft:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        text = 'Bản nháp';
        break;
      case MinutesStatus.pending_approval:
        bgColor = Colors.orange.withOpacity(0.1);
        text = 'Chờ duyệt';
        textColor = Colors.orange;
        break;

      case MinutesStatus.approved:
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        text = 'Đã duyệt';
        break;
      case MinutesStatus.rejected:
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        text = 'Từ chối';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMinutesActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    // Strip HTML tags for preview
    final stripped = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return stripped.isEmpty ? 'Nội dung trống' : stripped;
  }

  // ============ MINUTES ACTIONS ============

  void _navigateToMinutesEditor(MeetingModel meeting, MeetingMinutesModel? version) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingMinutesEditorScreen(
          meetingId: meeting.id,
          existingMinutes: version,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh minutes
        context.read<MeetingMinutesProvider>().getLatestMinute(meeting.id);
      }
    });
  }

  void _showMinutesDetail(MeetingMinutesModel version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Chi tiết biên bản',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  _buildMinutesStatusBadge(version.status),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Biên bản #${version.versionNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(version.updatedAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _getContentPreview(version.content),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitMinutesForApproval(MeetingMinutesModel version) async {
    final provider = context.read<MeetingMinutesProvider>();
    final currentUser = context.read<AuthProvider>().userModel;
    final isAdmin = currentUser?.role == UserRole.admin; // Check if user calls it is global admin
    
    final success = await provider.submitForApproval(
      minutesId: version.id,
      isAdmin: isAdmin,
      userId: currentUser?.id,
      userName: currentUser?.displayName,
    );
    
    if (success) {
      // Refresh logic is handled by provider, but show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin ? 'Đã duyệt (Auto)' : 'Đã gửi duyệt'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  void _createNewVersionFromApproved(MeetingModel meeting, MeetingMinutesModel approvedVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo phiên bản mới'),
        content: const Text('Bạn muốn tạo phiên bản mới từ bản đã duyệt này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Create new draft version locally
              final newVersion = MeetingMinutesModel(
                id: 'minutes_${DateTime.now().millisecondsSinceEpoch}',
                meetingId: meeting.id,
                title: approvedVersion.title,
                content: approvedVersion.content,
                versionNumber: _minutesVersions.map((m) => m.versionNumber).reduce((a, b) => a > b ? a : b) + 1,
                status: MinutesStatus.draft,
                createdBy: 'current_user',
                createdByName: 'Người dùng hiện tại',
                createdAt: DateTime.now(),
                updatedBy: 'current_user',
                updatedByName: 'Người dùng hiện tại',
                updatedAt: DateTime.now(),
              );
              setState(() {
                _minutesVersions.insert(0, newVersion);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã tạo biên bản #${newVersion.versionNumber}'),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
              // Navigate to editor
              _navigateToMinutesEditor(meeting, newVersion);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B7FED)),
            child: const Text('Tạo mới'),
          ),
        ],
      ),
    );
  }

  void _approveMinutes(MeetingMinutesModel version, UserModel? currentUser) async {
    final provider = context.read<MeetingMinutesProvider>();
    final success = await provider.approveMinutes(
      minutesId: version.id,
      approvedBy: currentUser?.id ?? '',
      approvedByName: currentUser?.displayName ?? 'Admin',
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt biên bản'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  void _rejectMinutes(MeetingMinutesModel version) async {
    final provider = context.read<MeetingMinutesProvider>();
    final currentUser = context.read<AuthProvider>().userModel;
    // For now, no reason dialog needed per user spec simplicity, can add later
    final success = await provider.rejectMinutes(
      minutesId: version.id,
      rejectedBy: currentUser?.id ?? '',
      rejectedByName: currentUser?.displayName ?? 'Admin',
      reason: 'Rejected by Admin',
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối biên bản'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _archiveMinute(MeetingMinutesModel version) async {
    final provider = context.read<MeetingMinutesProvider>();
    final currentUser = context.read<AuthProvider>().userModel!;
    
    final success = await provider.archiveMinutes(
      minutesId: version.id,
      archivedBy: currentUser.id,
      archivedByName: currentUser.displayName,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu trữ biên bản'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _unarchiveMinute(MeetingMinutesModel version) async {
    final provider = context.read<MeetingMinutesProvider>();
    
    final success = await provider.unarchiveMinutes(version.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gỡ lưu trữ biên bản'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _deleteMinutesVersion(MeetingMinutesModel version) {
    if (!version.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể xóa biên bản nháp'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa biên bản'),
        content: Text('Bạn có chắc muốn xóa biên bản #${version.versionNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _minutesVersions.removeWhere((m) => m.id == version.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa biên bản'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
