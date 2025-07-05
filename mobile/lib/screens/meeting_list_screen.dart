import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
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
        title: const Text('Danh sách cuộc họp'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ phê duyệt'),
            Tab(text: 'Của tôi'),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.userModel == null) return const SizedBox();

              // Kiểm tra quyền tạo cuộc họp
              final canCreate =
                  authProvider.userModel!.getAllowedMeetingTypes().isNotEmpty;

              if (canCreate) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _navigateToCreateMeeting(),
                );
              }
              return const SizedBox();
            },
          ),
        ],
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
    IconData icon = Icons.meeting_room;

    switch (type) {
      case MeetingListType.all:
        message = 'Chưa có cuộc họp nào';
        break;
      case MeetingListType.pending:
        message = 'Không có cuộc họp chờ phê duyệt';
        icon = Icons.pending;
        break;
      case MeetingListType.myMeetings:
        message = 'Bạn chưa tạo cuộc họp nào';
        icon = Icons.person;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (type == MeetingListType.myMeetings)
            ElevatedButton(
              onPressed: () => _navigateToCreateMeeting(),
              child: const Text('Tạo cuộc họp đầu tiên'),
            ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, UserModel currentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showMeetingDetails(meeting),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với tiêu đề và trạng thái
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(meeting.status),
                ],
              ),
              const SizedBox(height: 8),

              // Thời gian
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Địa điểm
              Row(
                children: [
                  Icon(
                    meeting.isVirtual ? Icons.video_call : Icons.room,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.isVirtual
                          ? 'Trực tuyến'
                          : (meeting.physicalLocation ?? 'Chưa có địa điểm'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Loại cuộc họp và độ ưu tiên
              Row(
                children: [
                  _buildTypeChip(meeting.type),
                  const SizedBox(width: 8),
                  _buildPriorityChip(meeting.priority),
                ],
              ),
              const SizedBox(height: 8),

              // Người tạo
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Tạo bởi: ${meeting.creatorName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Actions
              if (_canManageMeeting(meeting, currentUser))
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (meeting.isPending && _canApproveMeeting(currentUser))
                      TextButton(
                        onPressed: () => _approveMeeting(meeting),
                        child: const Text('Phê duyệt'),
                      ),
                    if (meeting.isPending && _canApproveMeeting(currentUser))
                      TextButton(
                        onPressed: () => _rejectMeeting(meeting),
                        child: const Text('Từ chối'),
                      ),
                    if (meeting.creatorId == currentUser.id ||
                        currentUser.isSuperAdmin ||
                        currentUser.isAdmin)
                      TextButton(
                        onPressed: () => _editMeeting(meeting),
                        child: const Text('Chỉnh sửa'),
                      ),
                    if (meeting.creatorId == currentUser.id ||
                        currentUser.isSuperAdmin ||
                        currentUser.isAdmin)
                      TextButton(
                        onPressed: () => _deleteMeeting(meeting),
                        child: const Text('Xóa'),
                      ),
                  ],
                ),
            ],
          ),
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meeting.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mô tả: ${meeting.description}'),
              const SizedBox(height: 8),
              Text(
                  'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)}'),
              const SizedBox(height: 8),
              Text(
                  'Địa điểm: ${meeting.isVirtual ? 'Trực tuyến' : (meeting.physicalLocation ?? 'Chưa có')}'),
              const SizedBox(height: 8),
              Text('Người tham gia: ${meeting.participantCount}'),
              if (meeting.agenda != null) ...[
                const SizedBox(height: 8),
                Text('Chương trình: ${meeting.agenda}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
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
