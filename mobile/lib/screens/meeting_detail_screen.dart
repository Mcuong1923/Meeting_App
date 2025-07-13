import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting_model.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting_minutes_model.dart';
import '../providers/meeting_minutes_provider.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/file_provider.dart';
import '../models/file_model.dart';
import 'package:file_picker/file_picker.dart' hide FileType;
import 'package:url_launcher/url_launcher.dart';
import '../models/analytics_model.dart';
import '../utils/seed_dummy_data.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  const MeetingDetailScreen({Key? key, required this.meetingId})
      : super(key: key);

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  bool _loading = true;
  String? _error; // Thêm biến lưu lỗi
  List<MeetingMinutesModel> _minutes = [];
  List<FileModel> _files = [];
  List<AnalyticsEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 500)); // giả lập loading
    final now = DateTime.now();
    setState(() {
      _minutes = [
        MeetingMinutesModel(
          id: 'demo1',
          meetingId: 'demo',
          content: 'Đây là bản ghi demo.',
          createdBy: 'user123',
          createdByName: 'Nguyễn Văn A',
          status: 'draft',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      _files = [
        FileModel(
          id: 'file1',
          name: 'TaiLieuDemo.pdf',
          originalName: 'TaiLieuDemo.pdf',
          type: FileType.document,
          status: FileStatus.ready,
          mimeType: 'application/pdf',
          size: 123456,
          downloadUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          uploaderId: 'user123',
          uploaderName: 'Nguyễn Văn A',
          meetingId: 'demo',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      _events = [
        AnalyticsEvent(
          id: 'event1',
          type: AnalyticsEventType.meetingCreated,
          userId: 'user123',
          userName: 'Nguyễn Văn A',
          targetId: 'demo',
          timestamp: now,
        ),
      ];
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cuộc họp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _fetchAllData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text('Đã xảy ra lỗi khi tải dữ liệu!',
                          style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      Text(_error ?? '', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        onPressed: _fetchAllData,
                      ),
                    ],
                  ),
                )
              : _MeetingDetailContent(
                  meetingId: widget.meetingId,
                  minutes: _minutes,
                  files: _files,
                  events: _events,
                ),
    );
  }
}

class _MeetingDetailContent extends StatelessWidget {
  final String meetingId;
  final List<MeetingMinutesModel> minutes;
  final List<FileModel> files;
  final List<AnalyticsEvent> events;
  const _MeetingDetailContent(
      {required this.meetingId,
      required this.minutes,
      required this.files,
      required this.events});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeetingMinutesProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: Consumer3<MeetingProvider, MeetingMinutesProvider, FileProvider>(
        builder:
            (context, meetingProvider, minutesProvider, fileProvider, child) {
          MeetingModel? meeting;
          try {
            meeting =
                meetingProvider.meetings.firstWhere((m) => m.id == meetingId);
          } catch (_) {
            meeting = null;
          }
          if (meeting == null) {
            return const Center(child: Text('Không tìm thấy cuộc họp.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  meeting.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Thời gian & trạng thái
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${meeting.startTime.hour.toString().padLeft(2, '0')}:${meeting.startTime.minute.toString().padLeft(2, '0')} - '
                      '${meeting.endTime.hour.toString().padLeft(2, '0')}:${meeting.endTime.minute.toString().padLeft(2, '0')} | '
                      '${meeting.startTime.day.toString().padLeft(2, '0')}/${meeting.startTime.month.toString().padLeft(2, '0')}/${meeting.startTime.year}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    const Spacer(),
                    _buildStatusChip(meeting.status, context),
                  ],
                ),
                const SizedBox(height: 12),
                // Địa điểm
                Row(
                  children: [
                    Icon(
                      meeting.locationType == MeetingLocationType.virtual
                          ? Icons.videocam
                          : Icons.location_on,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meeting.locationType == MeetingLocationType.virtual
                            ? (meeting.virtualMeetingLink ?? 'Trực tuyến')
                            : (meeting.physicalLocation ?? 'Chưa có địa điểm'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Người tạo & thành viên
                Row(
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 6),
                    Text('Người tạo: ${meeting.creatorName}'),
                    const Spacer(),
                    Icon(Icons.group,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('${meeting.participants.length} người tham gia'),
                  ],
                ),
                const SizedBox(height: 16),
                // Mô tả
                if (meeting.description.isNotEmpty) ...[
                  Text('Mô tả', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(meeting.description),
                  const SizedBox(height: 16),
                ],
                // Thông tin bổ sung
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('Loại: ${meeting.type.name}', context),
                    _buildChip('Ưu tiên: ${meeting.priority.name}', context),
                    _buildChip('Phạm vi: ${meeting.scope.name}', context),
                    if (meeting.isRecurring)
                      _buildChip(
                          'Lặp: ${meeting.recurringPattern ?? ''}', context),
                  ],
                ),
                const SizedBox(height: 20),
                // Khu vực bản ghi cuộc họp
                _MeetingMinutesSection(
                  meetingId: meeting?.id ?? '',
                  currentUserId: currentUser?.id ?? '',
                  isAdmin: currentUser?.isAdmin == true ||
                      currentUser?.isSuperAdmin == true,
                  minutes: minutes,
                ),
                const SizedBox(height: 16),
                // Khu vực file đính kèm
                _MeetingFilesSection(
                  meetingId: meeting?.id ?? '',
                  currentUserId: currentUser?.id ?? '',
                  uploaderName: currentUser?.displayName ?? '',
                  files: files,
                ),
                const SizedBox(height: 16),
                // Khu vực thao tác
                Row(
                  children: [
                    if (currentUser != null &&
                        (currentUser.id == meeting.creatorId ||
                            currentUser.isAdmin ||
                            currentUser.isSuperAdmin)) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                        onPressed: () {
                          // TODO: Hiện dialog chỉnh sửa
                        },
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Xóa'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text(
                                  'Bạn có chắc chắn muốn xóa cuộc họp này?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Xóa')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await Provider.of<MeetingProvider>(context,
                                    listen: false)
                                .deleteMeeting(meeting!.id, currentUser);
                            Navigator.pop(context); // Quay lại danh sách
                          }
                        },
                      ),
                    ],
                    const Spacer(),
                    if (currentUser != null &&
                        (currentUser.isAdmin ||
                            currentUser.isSuperAdmin ||
                            currentUser.isManager) &&
                        meeting.status.toString().contains('pending')) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Phê duyệt'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận phê duyệt'),
                              content: const Text(
                                  'Bạn có chắc chắn muốn phê duyệt cuộc họp này?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Phê duyệt')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await Provider.of<MeetingProvider>(context,
                                    listen: false)
                                .approveMeeting(meeting!.id, currentUser);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Đã phê duyệt cuộc họp!')));
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Từ chối'),
                        onPressed: () async {
                          final reasonController = TextEditingController();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Từ chối cuộc họp'),
                              content: TextField(
                                controller: reasonController,
                                decoration: const InputDecoration(
                                    labelText: 'Lý do từ chối'),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Từ chối')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await Provider.of<MeetingProvider>(context,
                                    listen: false)
                                .rejectMeeting(meeting!.id, currentUser,
                                    reason: reasonController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Đã từ chối cuộc họp!')));
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                // Khu vực lịch sử hoạt động
                _MeetingActivityLogSection(
                    meetingId: meeting?.id ?? '', events: events),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(MeetingStatus status, BuildContext context) {
    Color color = Colors.grey;
    String text = '';
    switch (status) {
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
      case MeetingStatus.completed:
        color = Theme.of(context).colorScheme.primary;
        text = 'Hoàn thành';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildChip(String text, BuildContext context) {
    return Chip(
      label: Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}

// Widget hiển thị và thao tác bản ghi cuộc họp
class _MeetingMinutesSection extends StatefulWidget {
  final String meetingId;
  final String currentUserId;
  final bool isAdmin;
  final List<MeetingMinutesModel> minutes;
  const _MeetingMinutesSection(
      {required this.meetingId,
      required this.currentUserId,
      required this.isAdmin,
      required this.minutes});

  @override
  State<_MeetingMinutesSection> createState() => _MeetingMinutesSectionState();
}

class _MeetingMinutesSectionState extends State<_MeetingMinutesSection> {
  List<MeetingMinutesModel> _minutes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
    _loading = false;
  }

  void _showMinutesDialog({MeetingMinutesModel? minutes}) {
    final controller = TextEditingController(text: minutes?.content ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(minutes == null ? 'Tạo bản ghi' : 'Chỉnh sửa bản ghi'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Nội dung bản ghi',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider =
                  Provider.of<MeetingMinutesProvider>(context, listen: false);
              if (minutes == null) {
                await provider.createMeetingMinutes(
                  meetingId: widget.meetingId,
                  content: controller.text,
                  createdBy: widget.currentUserId,
                  createdByName: '', // TODO: lấy tên user
                );
              } else {
                await provider.updateMeetingMinutes(
                  minutesId: minutes.id,
                  content: controller.text,
                );
              }
              Navigator.pop(context);
              // _fetchMinutes(); // This line is removed as data is passed via constructor
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined),
                const SizedBox(width: 8),
                const Text('Bản ghi cuộc họp',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (widget.isAdmin ||
                    _minutes.isEmpty ||
                    (_minutes.isNotEmpty &&
                        _minutes.first.createdBy == widget.currentUserId))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(_minutes.isEmpty ? 'Tạo bản ghi' : 'Chỉnh sửa'),
                    onPressed: () => _showMinutesDialog(
                        minutes: _minutes.isNotEmpty ? _minutes.first : null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_minutes.isEmpty)
              const Text('Chưa có bản ghi nào cho cuộc họp này.'),
            if (_minutes.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_minutes.first.content),
              ),
          ],
        ),
      ),
    );
  }
}

class _MeetingFilesSection extends StatefulWidget {
  final String meetingId;
  final String currentUserId;
  final String uploaderName;
  final List<FileModel> files;
  const _MeetingFilesSection(
      {required this.meetingId,
      required this.currentUserId,
      required this.uploaderName,
      required this.files});

  @override
  State<_MeetingFilesSection> createState() => _MeetingFilesSectionState();
}

class _MeetingFilesSectionState extends State<_MeetingFilesSection> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<FileProvider>(context, listen: false)
    //       .loadFiles(meetingId: widget.meetingId);
    // });
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      await Provider.of<FileProvider>(context, listen: false).uploadFiles(
        result.files,
        widget.currentUserId,
        widget.uploaderName,
        meetingId: widget.meetingId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final files = fileProvider.files;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 8),
                const Text('Tài liệu đính kèm',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Tải lên'),
                  onPressed: _pickAndUploadFile,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (fileProvider.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!fileProvider.isLoading && files.isEmpty)
              const Text('Chưa có file đính kèm nào.'),
            if (!fileProvider.isLoading && files.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    leading: Icon(Icons.insert_drive_file,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(file.originalName),
                    subtitle:
                        Text('${file.uploaderName} • ${file.sizeFormatted}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        final uri = Uri.parse(file.downloadUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MeetingActivityLogSection extends StatefulWidget {
  final String meetingId;
  final List<AnalyticsEvent> events;
  const _MeetingActivityLogSection(
      {required this.meetingId, required this.events});

  @override
  State<_MeetingActivityLogSection> createState() =>
      _MeetingActivityLogSectionState();
}

class _MeetingActivityLogSectionState
    extends State<_MeetingActivityLogSection> {
  List<AnalyticsEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _events = widget.events;
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.history),
                SizedBox(width: 8),
                Text('Lịch sử hoạt động',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _events.isEmpty)
              const Text('Chưa có hoạt động nào.'),
            if (!_loading && _events.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return ListTile(
                    leading: const Icon(Icons.circle, size: 12),
                    title: Text(event.typeDisplayName),
                    subtitle: Text(
                        '${event.userName ?? event.userId} • ${_formatTime(event.timestamp)}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} hôm nay';
    }
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
