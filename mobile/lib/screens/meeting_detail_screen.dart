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
import '../models/meeting_note_model.dart';
import '../models/meeting_comment_model.dart';
import '../models/meeting_minutes_model.dart';
import '../providers/file_provider_simple.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // ===== Visual tokens (Light mode, match new design screenshot) =====
  static const Color _screenBg = Color(0xFFF6F8FC);
  static const Color _accentGreen = Color(0xFF00C853);
  static const Color _textPrimary = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _chipBorder = Color(0xFFE4E7EC);
  static const Color _cardBorder = Color(0xFFEAF0F6);
  static const Color _successBg = Color(0xFFE9F9EF);

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cardBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  BoxDecoration _chipDecoration({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _chipBorder, width: 1),
    );
  }

  // Mock data - will be replaced with real data later
  // List<MeetingDecision> _decisions = []; // Moved to provider
  List<MeetingTask> _tasks = [];
  List<MeetingNote> _notes = [];
  List<MeetingMinutesModel> _minutesVersions = [];
  // Files chờ xác nhận upload
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  late TextEditingController _commentController;
  FocusNode? _commentFocusNode;
  Future<MeetingModel?>? _meetingFuture;
  bool _isSendingComment = false;
  VoidCallback? _tabListener;
  bool _commentsRequested = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _commentController = TextEditingController();
    // Hot-reload safe: if this State existed before adding this field, initState
    // won't re-run, so we also lazily init in build().
    _commentFocusNode ??= FocusNode();

    // Add listener to TabController to load comments when switching to Comments tab
    _tabListener = () {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        // Tab index 1 is Comments tab
        _loadComments();
      }
    };
    _tabController.addListener(_tabListener!);

    // Load decisions and log entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MeetingProvider>();
      final now = DateTime.now().toIso8601String();
      final providerHash = provider.providerHash;

      print(
          '[MEETING_DETAIL][ENTER] meetingId=${widget.meetingId} time=$now providerHash=$providerHash');

      // Cache the future to avoid rebuilding FutureBuilder unnecessarily
      _meetingFuture = provider.getMeetingById(widget.meetingId);

      provider.loadDecisions(widget.meetingId);
      provider.loadTasks(widget.meetingId); // Load tasks for current meeting

      // Load meeting minutes
      if (mounted) {
        final minutesProvider = context.read<MeetingMinutesProvider>();
        minutesProvider.getLatestMinute(widget.meetingId);
        minutesProvider.getMinutesForMeeting(widget.meetingId);
      }
      // _loadMockData(); // No longer needed

      // Load files for this meeting (for Tài liệu tab)
      if (mounted) {
        final fileProvider = context.read<SimpleFileProvider>();
        fileProvider.loadFiles(meetingId: widget.meetingId);
      }
    });
  }

  void _loadComments() {
    if (!mounted) return;
    _commentsRequested = true;
    final provider = context.read<MeetingProvider>();
    provider.loadComments(widget.meetingId);
  }

  @override
  void dispose() {
    if (_tabListener != null) {
      _tabController.removeListener(_tabListener!);
    }
    _tabController.dispose();
    _commentController.dispose();
    _commentFocusNode?.dispose();
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
        _minutesVersions = [];

        // _loading = false; // Moved to provider
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MeetingProvider>().isLoading;

    return Scaffold(
      backgroundColor: _screenBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Chi tiết cuộc họp',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: _screenBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textPrimary, size: 24),
            tooltip: 'Tải lại',
            onPressed: isLoading
                ? null
                : () {
                    context
                        .read<MeetingProvider>()
                        .loadDecisions(widget.meetingId);
                  },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<MeetingProvider, AuthProvider>(
              builder: (context, meetingProvider, authProvider, child) {
                // Use cached future to avoid rebuilding unnecessarily
                _meetingFuture ??= meetingProvider.getMeetingById(widget.meetingId);
                return FutureBuilder<MeetingModel?>(
                  future: _meetingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                                'Không tìm thấy cuộc họp\nID: ${widget.meetingId}',
                                textAlign: TextAlign.center),
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
                      } else if (fetchedMeeting.participants
                          .any((p) => p.userId == currentUser.id)) {
                        canView = true;
                      }
                    }

                    if (!canView) {
                      return const Center(
                          child: Text('Bạn không có quyền xem cuộc họp này'));
                    }

                    return _buildMeetingContent(
                        fetchedMeeting, authProvider.userModel);
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
          color: _screenBg,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: _accentGreen,
            unselectedLabelColor: _textSecondary,
            indicatorColor: _accentGreen,
            indicatorWeight: 3,
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: _screenBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            meeting.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Time and Date
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: _textSecondary),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '• ${DateFormat('dd/MM/yyyy').format(meeting.startTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _chipBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 14, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${meeting.participants.length} người',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
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
        color = _accentGreen;
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
        color: priority == MeetingPriority.low
            ? _successBg
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
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
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _chipBorder, width: 1),
        ),
        child: const Text(
          'Hoàn thành',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475467),
          ),
        ),
      );
    }

    if (meeting.status == MeetingStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _chipBorder, width: 1),
        ),
        child: const Text(
          'Hoàn thành',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475467),
          ),
        ),
      );
    }

    Color color;
    String text;

    switch (meeting.status) {
      case MeetingStatus.pending:
        color = Colors.orange;
        String level = '';
        if (meeting.approvalLevel == MeetingApprovalLevel.department) {
          level = ' (Trưởng phòng)';
        } else if (meeting.approvalLevel == MeetingApprovalLevel.company) {
          level = ' (Giám đốc)';
        } else {
          level = ' (Trưởng nhóm)';
        }
        text = 'Chờ duyệt$level';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
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
          const SizedBox(height: 20),

          // Participants Card
          _buildParticipantsCard(meeting),
          const SizedBox(height: 20),

          // Decisions Card
          _buildDecisionsCard(meeting, currentUser),
          const SizedBox(height: 20),

          // Tasks Card
          _buildTasksCard(meeting, currentUser),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MeetingModel meeting) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: _successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_rounded,
                  size: 18,
                  color: _accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thông tin tóm tắt',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow('Phòng họp', _getRoomDisplayText(meeting)),
          const SizedBox(height: 12),
          _buildInfoRow('Người tổ chức', meeting.creatorName),
          const SizedBox(height: 12),
          _buildInfoRow('Loại cuộc họp', _getMeetingTypeText(meeting.type)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getRoomDisplayText(MeetingModel meeting) {
    // Ưu tiên dùng roomName snapshot từ MeetingModel
    if (meeting.roomName != null && meeting.roomName!.trim().isNotEmpty) {
      return meeting.roomName!;
    }

    // Fallback cho các cuộc họp cũ chỉ lưu physicalLocation
    if (meeting.physicalLocation != null &&
        meeting.physicalLocation!.trim().isNotEmpty) {
      return meeting.physicalLocation!;
    }

    // Fallback cho cuộc họp online
    if (meeting.locationType == MeetingLocationType.virtual ||
        meeting.locationType == MeetingLocationType.hybrid) {
      if (meeting.virtualMeetingLink != null &&
          meeting.virtualMeetingLink!.trim().isNotEmpty) {
        return 'Trực tuyến (${meeting.virtualMeetingLink})';
      }
      return 'Trực tuyến';
    }

    return 'Chưa có phòng họp';
  }

  String _getMeetingTypeText(MeetingType type) {
    switch (type) {
      case MeetingType.personal:
        return 'Cá nhân (Personal)';
      case MeetingType.team:
        return 'Nhóm (Team)';
      case MeetingType.department:
        return 'Phòng ban (Department)';
      case MeetingType.company:
        return 'Công ty (Company)';
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
        decoration: _cardDecoration(),
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

    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _showAllParticipants(sortedParticipants),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: _successBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: _accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Người tham gia',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration:
                      _chipDecoration(backgroundColor: const Color(0xFFF2F4F7)),
                  child: Text(
                    '$totalCount',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475467),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Row
            Row(
              children: [
                // Avatar Stack - dùng Stack với clipBehavior: Clip.none
                // để avatar không bị SizedBox cắt bỏ
                SizedBox(
                  width: _calculateStackWidth(totalCount),
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Show up to 4 avatars
                      for (int i = 0;
                          i < (totalCount > 4 ? 4 : totalCount);
                          i++)
                        Positioned(
                          left: i * 28.0,
                          child: Container(
                            // Dùng padding + color instead of Border
                            // Để tạo vùng trắng SOLID che avatar phía sau
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white, // Solid opaque - không xâm qua
                            ),
                            child: _buildParticipantAvatar(
                              sortedParticipants[i],
                              radius: 20,
                            ),
                          ),
                        ),

                      // If more than 4, show +N bubble
                      if (totalCount > 4)
                        Positioned(
                          left: 4 * 28.0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
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
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$confirmedCount đã xác nhận',
                        style: textTheme.bodySmall?.copyWith(
                          color: _textSecondary,
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
    // 28px offset per overlap item
    // If count > 4, we show 4 avatars + 1 bubble = 5 items total
    int itemsToShow = count > 4 ? 5 : count;
    if (itemsToShow == 0) return 0;
    // Width = (items-1)*28 + 44 (full width of last item including border)
    return (itemsToShow - 1) * 28.0 + 44.0;
  }

  void _showAllParticipants(List<dynamic> participants) {
    final currentUser = context.read<AuthProvider>().userModel;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ParticipantsBottomSheet(
        participants: participants.cast<MeetingParticipant>(),
        meetingId: widget.meetingId,
        currentUserId: currentUser?.id ?? '',
        isHost: participants.cast<MeetingParticipant>().any(
              (p) => p.userId == (currentUser?.id ?? '') && (p.role == 'chair' || p.role == 'host'),
            ),
      ),
    );
  }

  /// Avatar đồng bộ toàn app - dùng pravatar.cc với seed = email
  /// (nhất quán với home_screen.dart và settings_screen.dart)
  Widget _buildParticipantAvatar(MeetingParticipant participant, {double radius = 20}) {
    final email = participant.userEmail.isNotEmpty
        ? participant.userEmail
        : participant.userId; // fallback nếu không có email

    final name = participant.userName.isNotEmpty
        ? participant.userName
        : (participant.userEmail.isNotEmpty
            ? participant.userEmail.split('@').first
            : 'U');

    // Initials - dùng khi ảnh load lỗi
    final parts = name.trim().split(RegExp(r'\s+'));
    String initials;
    if (parts.length >= 2) {
      initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    } else {
      initials = 'U';
    }

    // Hash màu cho fallback initials
    const colors = [
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEF5350),
      Color(0xFFAB47BC), Color(0xFF42A5F5), Color(0xFF66BB6A),
      Color(0xFFFFA726), Color(0xFF26C6DA), Color(0xFFEC407A),
      Color(0xFF8D6E63),
    ];
    final colorIndex = email.codeUnits.fold(0, (sum, code) => sum + code) % colors.length;

    // Dùng _AvatarWithFallback để handle lỗi load ảnh
    return _AvatarWithFallback(
      imageUrl: 'https://i.pravatar.cc/150?u=$email',
      initials: initials,
      fallbackColor: colors[colorIndex],
      radius: radius,
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: _successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  size: 18,
                  color: _accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thống nhất & Quyết định',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
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
                  color: _accentGreen.withOpacity(0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: _accentGreen),
                  SizedBox(width: 6),
                  Text(
                    'Thêm quyết định mới',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _accentGreen,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  decision.content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (decision.isFinal)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _successBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Đã chốt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accentGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Reaction buttons row (+ delete button on the right)
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
                onTap: () =>
                    _handleReaction(decision, DecisionReaction.neutral),
              ),

              const SizedBox(width: 8),

              // Delete button
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
          const SizedBox(height: 8),

          // Action buttons row (finalize only)
          Row(
            children: [
              // Finalize button - always show, but gray when finalized
              InkWell(
                onTap: decision.isFinal
                    ? () {
                        // Show "Already finalized" message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.white, size: 20),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        decision.isFinal ? Colors.grey.shade400 : _accentGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        decision.isFinal ? 'Đã chốt' : 'Chốt kết quả',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
                          final meetingProvider = Provider.of<MeetingProvider>(
                              context,
                              listen: false);
                          final meetings = meetingProvider.meetings;
                          print(
                              '[MEETING_DETAIL][NAV] meetingsCount=${meetings.length} targetId=${widget.meetingId}');

                          // Find meeting by id, or create a minimal stub with correct id
                          final meeting = meetings.isEmpty
                              ? null
                              : meetings.firstWhere(
                                  (m) => m.id == widget.meetingId,
                                  orElse: () => meetings.first,
                                );

                          if (meeting == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Không tìm thấy thông tin cuộc họp'),
                                  backgroundColor: Colors.red),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskManagementScreen(
                                meeting: meeting,
                                meetingId: widget
                                    .meetingId, // Always use the correct meetingId
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
                            border: Border.all(
                                color:
                                    const Color(0xFF2196F3).withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                        onTap: () =>
                            _showConvertToTaskDialog(decision, currentUser),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFF2196F3).withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
    final baseColor = isSelected ? color : _textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: baseColor),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: baseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReaction(
      MeetingDecision decision, DecisionReaction reaction) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    // Create new reactions map
    final Map<String, DecisionReaction> newReactions =
        Map.from(decision.reactions);
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
        content: const Row(
          children: [
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
                                    final currentUser =
                                        context.read<AuthProvider>().userModel;
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Đã thêm quyết định mới'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Không thể thêm quyết định'),
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

  void _showConvertToTaskDialog(
      MeetingDecision decision, UserModel? currentUser) {
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

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              clipBehavior: Clip.hardEdge,
              height: (MediaQuery.of(context).size.height * 0.85 -
                      MediaQuery.of(context).viewInsets.bottom)
                  .clamp(300.0, MediaQuery.of(context).size.height * 0.85),
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
                            child: const Icon(Icons.close,
                                size: 20, color: Colors.grey),
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
                              errorText:
                                  isTitleEmpty ? 'Vui lòng nhập tiêu đề' : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
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
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
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
                                    const Text('Người thực hiện',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFFFAFAFA),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor:
                                                const Color(0xFF9B7FED),
                                            child: Text(
                                              (currentUser?.displayName ?? 'U')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value:
                                                    selectedAssigneeId.isEmpty
                                                        ? null
                                                        : selectedAssigneeId,
                                                hint: const Text('Chọn người',
                                                    style: TextStyle(
                                                        fontSize: 13)),
                                                isExpanded: true,
                                                items: [
                                                  DropdownMenuItem(
                                                    value: currentUser?.id ??
                                                        'user1',
                                                    child: Text(
                                                      currentUser
                                                              ?.displayName ??
                                                          'Tôi',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setModalState(() =>
                                                        selectedAssigneeId =
                                                            val);
                                                  }
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
                                    const Text('Hạn hoàn thành',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13)),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDeadline,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          setModalState(
                                              () => selectedDeadline = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: const Color(0xFFFAFAFA),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: Color(0xFF666666)),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                                              style:
                                                  const TextStyle(fontSize: 13),
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

                          const Text('Mức độ ưu tiên',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
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
                                _buildPriorityChip(
                                    'Thấp',
                                    'low',
                                    selectedPriority,
                                    (val) => setModalState(
                                        () => selectedPriority = val)),
                                _buildPriorityChip(
                                    'Trung bình',
                                    'medium',
                                    selectedPriority,
                                    (val) => setModalState(
                                        () => selectedPriority = val)),
                                _buildPriorityChip(
                                    'Cao',
                                    'high',
                                    selectedPriority,
                                    (val) => setModalState(
                                        () => selectedPriority = val)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text('Trạng thái khởi tạo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
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
                                _buildStatusChip(
                                    'Chờ xử lý',
                                    'pending',
                                    selectedStatus,
                                    (val) => setModalState(
                                        () => selectedStatus = val),
                                    Colors.orange),
                                _buildStatusChip(
                                    'Đang làm',
                                    'in_progress',
                                    selectedStatus,
                                    (val) => setModalState(
                                        () => selectedStatus = val),
                                    Colors.blue),
                                _buildStatusChip(
                                    'Hoàn thành',
                                    'completed',
                                    selectedStatus,
                                    (val) => setModalState(
                                        () => selectedStatus = val),
                                    Colors.green),
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
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10, elevation: 2),
                              overlayColor:
                                  const Color(0xFF9B7FED).withOpacity(0.1),
                            ),
                            child: Slider(
                              value: progressValue,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: (value) =>
                                  setModalState(() => progressValue = value),
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
                      border: Border(
                          top: BorderSide(
                              color: Colors.grey.shade200, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              foregroundColor: Colors.grey.shade700,
                            ),
                            child: const Text('Hủy bỏ',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isTitleEmpty
                                ? null
                                : () {
                                    final now = DateTime.now();
                                    final newTask = MeetingTask(
                                      id: 'task_${now.millisecondsSinceEpoch}',
                                      meetingId: widget.meetingId,
                                      title: titleController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                      assigneeId: selectedAssigneeId,
                                      assigneeName:
                                          currentUser?.displayName ?? 'Unknown',
                                      assigneeRole:
                                          currentUser?.role.toString() ??
                                              'Member',
                                      deadline: selectedDeadline,
                                      status: selectedStatus,
                                      priority: selectedPriority,
                                      progress: progressValue.round(),
                                      createdBy: currentUser?.id ?? '',
                                      createdByName:
                                          currentUser?.displayName ?? 'Unknown',
                                      createdAt: now,
                                      updatedAt: now,
                                    );

                                    // Save task to Firestore via Provider
                                    context
                                        .read<MeetingProvider>()
                                        .addTask(newTask)
                                        .then((docId) {
                                      if (docId == null && mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Lỗi tạo công việc'),
                                              backgroundColor: Colors.red),
                                        );
                                      } else if (docId != null && mounted) {
                                        // Reload tasks for current meeting to refresh the task section
                                        context
                                            .read<MeetingProvider>()
                                            .loadTasks(widget.meetingId);
                                      }
                                    });

                                    // Update decision with taskId via Provider
                                    context
                                        .read<MeetingProvider>()
                                        .updateDecision(
                                          decision.copyWith(taskId: newTask.id),
                                        );

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded,
                                                color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Đã tạo nhiệm vụ thành công'),
                                          ],
                                        ),
                                        backgroundColor:
                                            const Color(0xFF4CAF50),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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

  Widget _buildPriorityChip(String label, String value, String groupValue,
      Function(String) onSelect) {
    final isSelected = value == groupValue;
    Color color;
    switch (value) {
      case 'high':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
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

  Widget _buildStatusChip(String label, String value, String groupValue,
      Function(String) onSelect, Color activeColor) {
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
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
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

    print(
        '[MEETING_DETAIL][NAV] meetingsCount=${meetings.length} targetId=${widget.meetingId}');

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
        builder: (context) => TaskManagementScreen(
          meeting: meeting,
          meetingId: widget.meetingId, // Always use explicit meetingId
        ),
      ),
    );
  }

  Widget _buildTasksCard(MeetingModel meeting, UserModel? currentUser) {
    final provider = context.watch<MeetingProvider>();
    final allTasks = provider.getTasksForMeeting(widget.meetingId);
    final displayTasks = allTasks.take(3).toList();
    final isLoading = provider.isLoading;

    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: _successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      size: 18,
                      color: _accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nhiệm vụ cần làm',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              if (allTasks.isNotEmpty)
                InkWell(
                  onTap: _navigateToTaskManagement,
                  child: Text(
                    'Xem công việc',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _accentGreen,
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
                  Icon(Icons.assignment_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có nhiệm vụ nào',
                      style: TextStyle(color: Colors.grey.shade500)),
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
                  backgroundColor: _accentGreen,
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
                    foregroundColor: _accentGreen,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF7), width: 1),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  backgroundColor: _accentGreen.withOpacity(0.12),
                  child: Text(
                    task.assigneeName.isNotEmpty
                        ? task.assigneeName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _accentGreen,
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
    final fileProvider = context.watch<SimpleFileProvider>();
    final files = fileProvider.files;
    final isLoading = fileProvider.isLoading;
    final hasPending = _selectedFiles.isNotEmpty;

    return Column(
      children: [
        // ── Nút Chọn tệp luôn hiển thị ─────────────────────────
        Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(16, 16, 16, hasPending ? 8 : 16),
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickFilesOnly,
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            label: const Text(
              'Chọn tệp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              elevation: 0,
            ),
          ),
        ),

        // ── Preview files chờ upload ────────────────────────────
        if (hasPending) ...
          [
            // Danh sách file đã chọn
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã chọn ${_selectedFiles.length} tệp',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedFiles.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(f.name),
                          size: 18,
                          color: _getFileIconColor(f.name),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.name,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatFileSize(f.size),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Nút Tải lên + Hủy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Nút Hủy
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading
                          ? null
                          : () => setState(() => _selectedFiles = []),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nút Tải lên
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadSelectedFiles,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload_rounded, size: 20),
                      label: Text(
                        _isUploading ? 'Đang tải...' : 'Tải lên',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

        // ── Danh sách file đã upload ────────────────────────────
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : files.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0xFFE0ECFF), Color(0xFFFFFFFF)],
                              center: Alignment(0, 0.2),
                              radius: 0.9,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.folder_open_rounded,
                                size: 32,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Chưa có tài liệu',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF101828))),
                        const SizedBox(height: 8),
                        const Text(
                            'Tài liệu được tải lên sẽ xuất hiện tại đây',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF98A2B3))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: files.length,
                      itemBuilder: (ctx, i) => _buildFileItem(files[i]),
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
                  (file['originalName'] ?? file['name'] ?? 'Unknown') as String,
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

          // Download + Delete buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút download
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 22),
                color: const Color(0xFF5B7FED),
                tooltip: 'Tải xuống',
                onPressed: () async {
                  final url = file['downloadUrl'] as String?;
                  if (url != null && url.isNotEmpty) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Không thể mở file')),
                        );
                      }
                    }
                  }
                },
              ),
              // Nút xóa
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: Colors.grey.shade600,
                tooltip: 'Xóa',
                onPressed: () async {
                  final fileId = file['id'] as String?;
                  if (fileId != null) {
                    await context.read<SimpleFileProvider>().deleteFile(fileId);
                  }
                },
              ),
            ],
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

  /// Chỉ chọn file, chưa upload
  Future<void> _pickFilesOnly() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFiles = result.files);
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Upload các file đã chọn sau khi người dùng xác nhận
  Future<void> _uploadSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      _showCustomSnackBar('Không xác định được danh tính người dùng.', false);
      return;
    }

    setState(() => _isUploading = true);
    final fileProvider = context.read<SimpleFileProvider>();
    try {
      await fileProvider.uploadFiles(
        _selectedFiles,
        currentUser.id,
        currentUser.displayName,
        meetingId: widget.meetingId,
      );
      setState(() => _selectedFiles = []);
      _showCustomSnackBar('Tải lên tài liệu thành công!', true);
    } catch (e) {
      _showCustomSnackBar('Tải lên thất bại. Vui lòng thử lại.', false);
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
            ], //
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
    return Consumer<MeetingProvider>(
      builder: (context, provider, child) {
        final comments = provider.comments;
        final isLoadingComments = provider.isLoadingComments;
        final commentsError = provider.commentsError;

        // Hot-reload / listener-safety: ensure we request comments at least once
        // when the Comments tab is visible.
        if (_tabController.index == 1 && !_commentsRequested) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadComments();
          });
        }

        return Column(
          children: [
            // Body / loading / empty / error state
            Expanded(
              child: isLoadingComments && comments.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : commentsError != null && comments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  commentsError,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (commentsError.contains('permission-denied') ||
                                    commentsError.contains('không có quyền'))
                                  const Text(
                                    'Chỉ những người tham gia cuộc họp mới có thể xem và gửi bình luận.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    print('[MEETING_DETAIL] Retry load comments');
                                    _loadComments();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8E6BFF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : comments.isEmpty
                          ? SingleChildScrollView(
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.6,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1ECFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 56,
                                            color: const Color(0xFF8E6BFF)
                                                .withOpacity(0.9),
                                          ),
                                          Positioned(
                                            right: 32,
                                            top: 40,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.06),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.more_horiz_rounded,
                                                size: 16,
                                                color: Color(0xFF8E6BFF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Chưa có bình luận nào',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF101828),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        'Hãy là người đầu tiên bắt đầu cuộc trò chuyện\ntrong cuộc họp này.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF98A2B3),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return _buildCommentItem(comment);
                              },
                            ),
            ),

            // Comment input - Fixed at bottom
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      // Hot-reload safe: create if missing
                      focusNode: (_commentFocusNode ??= FocusNode()),
                      enabled: !_isSendingComment,
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _isSendingComment
                          ? const Color(0xFF8E6BFF).withOpacity(0.5)
                          : const Color(0xFF8E6BFF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSendingComment
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                      onPressed: _isSendingComment
                          ? null
                          : () {
                              _sendComment(currentUser);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendComment(UserModel? currentUser) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để bình luận'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSendingComment) return;

    setState(() {
      _isSendingComment = true;
    });

    try {
      final provider = context.read<MeetingProvider>();
      final newComment = await provider.saveComment(
        widget.meetingId,
        content,
        currentUser.id,
        currentUser.displayName.isNotEmpty
            ? currentUser.displayName
            : (currentUser.email.split('@').first),
        currentUser.photoURL,
      );

      if (newComment != null && mounted) {
        // Clear input
        _commentController.clear();

        // Hide keyboard
        FocusScope.of(context).unfocus();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi bình luận'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print('💬 Comment sent successfully: ${newComment.content}');
      } else {
        // Error already handled in provider, show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  provider.commentsError ?? 'Lỗi gửi bình luận. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error sending comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi bình luận: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  Widget _buildCommentItem(MeetingComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF8E6BFF).withOpacity(0.16),
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFF8E6BFF),
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
                border: Border.all(
                  color: const Color(0xFFE4E7EC),
                  width: 1,
                ),
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
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(comment.createdAt),
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
    return meeting.participants
        .any((p) => p.userId == user.id && p.role == 'secretary');
  }

  /// Check if user can view this minute
  bool _canViewMinute(
      MeetingMinutesModel minute, UserModel user, MeetingModel meeting) {
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
        if (provider.error != null &&
            provider.error!.contains('failed-precondition')) {
          return _buildIndexErrorBanner(provider.error!);
        }

        final currentVersion = provider.currentVersion;
        final hasPermission = _isSecretaryOrChair(meeting, currentUser);

        // Strict Visibility Check
        if (currentVersion != null &&
            !_canViewMinute(currentVersion, currentUser, meeting)) {
          return _buildNoPermissionState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Version Section
              _buildCurrentVersionSection(
                  meeting, currentUser, currentVersion, hasPermission),
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
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 32, color: Colors.orange),
          SizedBox(height: 12),
          Text(
            'Cần tạo Index Firestore',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  Icon(Icons.description_outlined,
                      size: 48, color: Colors.grey.shade400),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined,
                        size: 14, color: Colors.grey.shade700),
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
                Icon(Icons.person_outline_rounded,
                    size: 16, color: Colors.grey.shade600),
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
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(currentVersion.updatedAt),
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
                    child: const Text(
                      'Xem thêm →',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9B7FED),
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
                    const Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
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
                if (currentVersion.isApproved &&
                    !currentVersion.isArchived &&
                    (isAdmin || hasPermission))
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                return _buildVersionHistoryItem(
                    version, meeting, currentUser, hasPermission);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  void _navigateToMinutesEditor(
      MeetingModel meeting, MeetingMinutesModel? version) {
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
    final isAdmin = currentUser?.role ==
        UserRole.admin; // Check if user calls it is global admin

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

  void _createNewVersionFromApproved(
      MeetingModel meeting, MeetingMinutesModel approvedVersion) {
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
                versionNumber: _minutesVersions
                        .map((m) => m.versionNumber)
                        .reduce((a, b) => a > b ? a : b) +
                    1,
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
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B7FED)),
            child: const Text('Tạo mới'),
          ),
        ],
      ),
    );
  }

  void _approveMinutes(
      MeetingMinutesModel version, UserModel? currentUser) async {
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
        content:
            Text('Bạn có chắc muốn xóa biên bản #${version.versionNumber}?'),
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

/// Widget avatar với pravatar.cc + fallback initials khi ảnh lỗi
/// Đảm bảo avatar luôn hiển thị đúng ngay cả khi mất mạng
class _AvatarWithFallback extends StatefulWidget {
  final String imageUrl;
  final String initials;
  final Color fallbackColor;
  final double radius;

  const _AvatarWithFallback({
    required this.imageUrl,
    required this.initials,
    required this.fallbackColor,
    required this.radius,
  });

  @override
  State<_AvatarWithFallback> createState() => _AvatarWithFallbackState();
}

class _AvatarWithFallbackState extends State<_AvatarWithFallback> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Fallback: initials avatar với màu riêng
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.fallbackColor,
        child: Text(
          widget.initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.radius * 0.7,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      // Dùng màu opaque khi image đang load - tránh nhìn thấy avatar phía sau
      backgroundColor: widget.fallbackColor,
      backgroundImage: NetworkImage(widget.imageUrl),
      onBackgroundImageError: (_, __) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM PARTICIPANTS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
// PARTICIPANTS BOTTOM SHEET — v2 (Fixed shadow overlay + 4 statuses + Respond)
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantsBottomSheet extends StatefulWidget {
  final List<MeetingParticipant> participants;
  final String meetingId;
  final String currentUserId;
  final bool isHost;

  const _ParticipantsBottomSheet({
    required this.participants,
    required this.meetingId,
    required this.currentUserId,
    required this.isHost,
  });

  @override
  State<_ParticipantsBottomSheet> createState() =>
      _ParticipantsBottomSheetState();
}

class _ParticipantsBottomSheetState extends State<_ParticipantsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _isResponding = false;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _sGreen    = Color(0xFF12B76A);
  static const Color _sGreenBg  = Color(0xFFECFDF3);
  static const Color _sAmber    = Color(0xFFDC6803);
  static const Color _sAmberBg  = Color(0xFFFFFAEB);
  static const Color _sRed      = Color(0xFFD92D20);
  static const Color _sRedBg    = Color(0xFFFEF3F2);
  static const Color _sPurple   = Color(0xFF6941C6);
  static const Color _sPurpleBg = Color(0xFFF4F3FF);
  static const Color _sBlueBg   = Color(0xFFEFF8FF);
  static const Color _sBlue     = Color(0xFF0284C7);
  static const Color _sGrayBg   = Color(0xFFF2F4F7);
  static const Color _sGray     = Color(0xFF667085);
  static const Color _textPrimary   = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MeetingParticipant> _filtered(int tab) {
    var list = List<MeetingParticipant>.from(widget.participants);
    switch (tab) {
      case 1: list = list.where((p) => p.attendanceStatus == ParticipantAttendanceStatus.accepted).toList(); break;
      case 2: list = list.where((p) => p.attendanceStatus == ParticipantAttendanceStatus.pending).toList(); break;
      case 3: list = list.where((p) =>
          p.attendanceStatus == ParticipantAttendanceStatus.declined ||
          p.attendanceStatus == ParticipantAttendanceStatus.tentative).toList(); break;
    }
    if (_query.isNotEmpty) {
      list = list.where((p) =>
        p.userName.toLowerCase().contains(_query) ||
        p.userEmail.toLowerCase().contains(_query)).toList();
    }
    return list;
  }

  // ── Status config ───────────────────────────────────────────────────────────
  _StatusStyleInfo _statusStyle(ParticipantAttendanceStatus s) {
    switch (s) {
      case ParticipantAttendanceStatus.accepted:
        return const _StatusStyleInfo(color: _sGreen, bg: _sGreenBg, icon: Icons.check_circle_rounded, label: 'Đã xác nhận');
      case ParticipantAttendanceStatus.pending:
        return const _StatusStyleInfo(color: _sAmber, bg: _sAmberBg, icon: Icons.hourglass_top_rounded, label: 'Chờ phản hồi');
      case ParticipantAttendanceStatus.declined:
        return const _StatusStyleInfo(color: _sRed, bg: _sRedBg, icon: Icons.cancel_rounded, label: 'Từ chối');
      case ParticipantAttendanceStatus.tentative:
        return const _StatusStyleInfo(color: _sPurple, bg: _sPurpleBg, icon: Icons.help_outline_rounded, label: 'Có thể');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total    = widget.participants.length;
    final accepted = widget.participants.where((p) => p.attendanceStatus == ParticipantAttendanceStatus.accepted).length;
    final pending  = widget.participants.where((p) => p.attendanceStatus == ParticipantAttendanceStatus.pending).length;
    final declined = widget.participants.where((p) =>
        p.attendanceStatus == ParticipantAttendanceStatus.declined ||
        p.attendanceStatus == ParticipantAttendanceStatus.tentative).length;

    // Current user's participant record
    final myParticipant = widget.participants
        .where((p) => p.userId == widget.currentUserId)
        .firstOrNull;
    final myStatus = myParticipant?.attendanceStatus;
    final showRespondBar = myStatus != null &&
        myStatus != ParticipantAttendanceStatus.accepted &&
        !widget.isHost;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final filtered = _filtered(_tabController.index);
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle
              const SizedBox(height: 10),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),

              // ── Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Người tham gia',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
                      const SizedBox(height: 2),
                      Text('$accepted/$total đã xác nhận',
                        style: const TextStyle(fontSize: 13, color: _textSecondary)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(color: _sGrayBg, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 16, color: _sGray),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Stats row (NO shadow — plain colored backgrounds only)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _statPill(Icons.groups_rounded, '$total', 'Tổng', const Color(0xFF5C6BC0), const Color(0xFFEEF0FB)),
                  const SizedBox(width: 8),
                  _statPill(Icons.check_circle_rounded, '$accepted', 'Xác nhận', _sGreen, _sGreenBg),
                  const SizedBox(width: 8),
                  _statPill(Icons.hourglass_top_rounded, '$pending', 'Chờ', _sAmber, _sAmberBg),
                  const SizedBox(width: 8),
                  _statPill(Icons.cancel_rounded, '$declined', 'Không', _sRed, _sRedBg),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Use Material so elevation clips correctly — NO extra BoxShadow
                  child: Material(
                    elevation: 1,
                    shadowColor: Colors.black12,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14, color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0B7C3)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFB0B7C3)),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFFB0B7C3)),
                                onPressed: () => _searchCtrl.clear())
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Tab Bar — NO BoxShadow on indicator, color contrast only
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _sGrayBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      // ✅ No BoxShadow on indicator → eliminates tab shadow artifact
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: _textPrimary,
                    unselectedLabelColor: _textSecondary,
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(text: 'Tất cả ($total)'),
                      Tab(text: '✓ ($accepted)'),
                      Tab(text: '⌛ ($pending)'),
                      Tab(text: '✗ ($declined)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEAF0F6)),

              // ── List — ✅ Use Material elevation per card, NOT Container+BoxShadow
              Expanded(
                child: filtered.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildCard(filtered[i]),
                      ),
              ),

              // ── Respond bar (for current user if pending)
              if (showRespondBar) _buildRespondBar(context, myStatus),
            ],
          ),
        );
      },
    );
  }

  // ── Stat pill — flat, no shadow ──────────────────────────────────────────────
  Widget _statPill(IconData icon, String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          // ✅ No BoxShadow, no Border → cleaner look
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, height: 1)),
            ]),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.75), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Participant card — ✅ Material elevation + ClipRRect (no stacked shadows) ──
  Widget _buildCard(MeetingParticipant p) {
    final status = _statusStyle(p.attendanceStatus);
    final roleConfig = _roleConfig(p.role);
    final name = p.userName.isNotEmpty
        ? p.userName
        : (p.userEmail.isNotEmpty ? p.userEmail.split('@').first : 'Người dùng');
    final isMe = p.userId == widget.currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        // ✅ ClipRRect ensures Material elevation shadow doesn't bleed through rounded corners
        child: Material(
          elevation: 1,                          // ✅ Single elevation source — no stacked shadows
          shadowColor: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onLongPress: widget.isHost ? () => _showRoleMenu(p) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                // Avatar + indicator dot
                Stack(clipBehavior: Clip.none, children: [
                  _buildAvatar(p),
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 12),

                // Name + role
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.1,
                        ),
                        overflow: TextOverflow.ellipsis),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: _sBlueBg, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Bạn', style: TextStyle(fontSize: 9, color: _sBlue, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  if (roleConfig != null) ...[
                    const SizedBox(height: 3),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(roleConfig.icon, size: 10, color: roleConfig.color),
                      const SizedBox(width: 3),
                      Text(roleConfig.label,
                        style: TextStyle(fontSize: 10, color: roleConfig.color, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ])),

                // Status pill — compact, no heavy border
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(status.icon, size: 10, color: status.color),
                    const SizedBox(width: 3),
                    Text(status.label,
                      style: TextStyle(fontSize: 10, color: status.color, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Respond bar ─────────────────────────────────────────────────────────────
  Widget _buildRespondBar(BuildContext context, ParticipantAttendanceStatus current) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAEEF4), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: _sAmber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              current == ParticipantAttendanceStatus.pending
                  ? 'Bạn chưa phản hồi lời mời này'
                  : 'Trạng thái: ${_statusStyle(current).label}',
              style: const TextStyle(fontSize: 12, color: _sAmber, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _respondBtn('Chấp nhận', Icons.check_circle_outline_rounded, _sGreen, _sGreenBg,
              () => _respond(context, ParticipantAttendanceStatus.accepted)),
          const SizedBox(width: 8),
          _respondBtn('Có thể', Icons.help_outline_rounded, _sPurple, _sPurpleBg,
              () => _respond(context, ParticipantAttendanceStatus.tentative)),
          const SizedBox(width: 8),
          _respondBtn('Từ chối', Icons.cancel_outlined, _sRed, _sRedBg,
              () => _respond(context, ParticipantAttendanceStatus.declined)),
        ]),
      ]),
    );
  }

  Widget _respondBtn(String label, IconData icon, Color color, Color bg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: _isResponding ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isResponding)
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: color))
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext ctx, ParticipantAttendanceStatus status) async {
    // PHASE 1 — verbose logging when user taps a respond button
    final myParticipant = widget.participants
        .where((p) => p.userId == widget.currentUserId)
        .firstOrNull;

    debugPrint('[PARTICIPANT][UI][TAP] '
        'meetingId=${widget.meetingId} '
        'currentUserId=${widget.currentUserId} '
        'selectedStatus=${status.name} '
        'currentParticipant=$myParticipant '
        '_isResponding=$_isResponding');

    setState(() => _isResponding = true);

    final provider = Provider.of<MeetingProvider>(ctx, listen: false);
    bool ok = false;

    try {
      debugPrint('[PARTICIPANT][UI] Calling respondToMeeting...');
      ok = await provider.respondToMeeting(
        meetingId: widget.meetingId,
        userId: widget.currentUserId,
        status: status,
      );
      debugPrint('[PARTICIPANT][UI] respondToMeeting finished ok=$ok');
    } catch (e, st) {
      debugPrint('[PARTICIPANT][UI][ERROR] Exception when responding: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Lỗi khi cập nhật phản hồi. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isResponding = false);
      }
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Đã cập nhật: ${_statusStyle(status).label}'),
        backgroundColor: _statusStyle(status).color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    } else {
      // Surfacing provider error path so user sees something when write fails
      final error = Provider.of<MeetingProvider>(ctx, listen: false).error;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(error ?? 'Không thể cập nhật trạng thái tham gia.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Role management (host long-press) ────────────────────────────────────────
  void _showRoleMenu(MeetingParticipant p) {
    final name = p.userName.isNotEmpty ? p.userName : 'Người dùng';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Đổi vai trò cho $name',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 16),
          ...[
            const _RoleMenuItem('chair', 'Chủ trì', Icons.star_rounded, _sPurple),
            const _RoleMenuItem('secretary', 'Thư ký', Icons.edit_note_rounded, _sBlue),
            const _RoleMenuItem('presenter', 'Báo cáo', Icons.present_to_all_rounded, _sAmber),
            const _RoleMenuItem('participant', 'Thành viên', Icons.person_outline_rounded, _sGray),
          ].map((r) => ListTile(
            leading: Icon(r.icon, color: r.color),
            title: Text(r.label, style: TextStyle(fontWeight: r.id == p.role ? FontWeight.w700 : FontWeight.w500)),
            trailing: r.id == p.role ? const Icon(Icons.check_rounded, color: _sGreen) : null,
            onTap: () async {
              Navigator.pop(context);
              if (r.id == p.role) return;
              final ok = await Provider.of<MeetingProvider>(context, listen: false)
                  .updateParticipantRole(
                    meetingId: widget.meetingId,
                    targetUserId: p.userId,
                    newRole: r.id,
                    currentUser: Provider.of<AuthProvider>(context, listen: false).userModel!,
                  );
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Đã đổi vai trò thành ${r.label}'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
          )),
        ]),
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────────
  Widget _buildAvatar(MeetingParticipant p) {
    final email = p.userEmail.isNotEmpty ? p.userEmail : p.userId;
    final name  = p.userName.isNotEmpty ? p.userName
        : (p.userEmail.isNotEmpty ? p.userEmail.split('@').first : 'U');
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    const palette = [
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEF5350),
      Color(0xFFAB47BC), Color(0xFF42A5F5), Color(0xFF66BB6A),
      Color(0xFFFFA726), Color(0xFF26C6DA), Color(0xFFEC407A), Color(0xFF8D6E63),
    ];
    final c = palette[email.codeUnits.fold(0, (s, e) => s + e) % palette.length];
    return _AvatarWithFallback(
      imageUrl: 'https://i.pravatar.cc/150?u=$email',
      initials: initials,
      fallbackColor: c,
      radius: 20,
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _emptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(color: _sGrayBg, shape: BoxShape.circle),
        child: const Icon(Icons.person_search_rounded, size: 32, color: Color(0xFFB0B7C3)),
      ),
      const SizedBox(height: 14),
      const Text('Không tìm thấy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textSecondary)),
      const SizedBox(height: 4),
      const Text('Thử thay đổi bộ lọc hoặc tìm kiếm', style: TextStyle(fontSize: 12, color: _textSecondary)),
    ]));
  }

  // ── Role config ──────────────────────────────────────────────────────────────
  _RoleConfig? _roleConfig(String role) {
    switch (role) {
      case 'host':
      case 'chair':
        return const _RoleConfig(label: 'Chủ trì', icon: Icons.star_rounded,
            color: Color(0xFF7C3AED), bg: Color(0xFFF3EEFF));
      case 'secretary':
        return const _RoleConfig(label: 'Thư ký', icon: Icons.edit_note_rounded,
            color: Color(0xFF0284C7), bg: Color(0xFFE0F2FE));
      case 'presenter':
        return const _RoleConfig(label: 'Báo cáo', icon: Icons.present_to_all_rounded,
            color: Color(0xFFD97706), bg: Color(0xFFFEF3C7));
      default: return null;
    }
  }
}

class _RoleConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _RoleConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StatusStyleInfo {
  final Color color;
  final Color bg;
  final IconData icon;
  final String label;

  const _StatusStyleInfo({
    required this.color,
    required this.bg,
    required this.icon,
    required this.label,
  });
}

class _RoleMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _RoleMenuItem(this.id, this.label, this.icon, this.color);
}
