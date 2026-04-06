import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/room_booking_model.dart';
import '../providers/meeting_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/room_booking_provider.dart';
import '../services/room_recommendation_engine.dart';
import '../services/gemini_service.dart';
import '../services/smart_schedule_service.dart';
import '../components/room_time_slots_bottom_sheet.dart';

class MeetingCreateScreen extends StatefulWidget {
  const MeetingCreateScreen({Key? key}) : super(key: key);

  @override
  State<MeetingCreateScreen> createState() => _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends State<MeetingCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _virtualLinkController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  MeetingLocationType _locationType = MeetingLocationType.physical;
  MeetingPriority _priority = MeetingPriority.medium;
  MeetingType _meetingType = MeetingType.personal;
  bool _isPublic = false;

  final List<UserModel> _selectedParticipants = [];
  UserModel? _selectedSecretary;

  // Selected room (from Firestore via RoomProvider)
  RoomModel? _selectedRoom;

  bool _isCreating = false;

  // ─── AI Suggestion State ───
  bool _isLoadingTimeSuggestion = false;
  bool _isLoadingAgenda = false;
  final SmartScheduleService _scheduleService = SmartScheduleService();

  // Quick booking data (when creating from booking reminder)
  String? _sourceBookingId;
  bool _isFromQuickBooking = false;
  RoomBooking? _sourceBooking;
  bool _bookingExpired = false;

  // ===== Visual tokens (Light mode, match new "Create meeting" design) =====
  static const Color _screenBg = Color(0xFFF6F8FC);
  static const Color _headerTeal = Color(0xFF2C5F6F);
  static const Color _accentBlue = Color(0xFF007AFF);
  static const Color _textPrimary = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _placeholder = Color(0xFF98A2B3);
  static const Color _cardBorder = Color(0xFFEAF0F6);

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
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

  Widget _sectionIcon(IconData icon, {Color bg = const Color(0xFFF2F4F7)}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 20, color: _headerTeal),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  TextStyle get _kSectionLabel => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF667085),
      );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = now.add(const Duration(minutes: 15));
    final end = start.add(const Duration(hours: 1));
    _selectedDate = start;
    _startTime = TimeOfDay.fromDateTime(start);
    _endTime = TimeOfDay.fromDateTime(end);

    _titleController.addListener(_updateState);

    // Load rooms from Firestore and handle booking arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadRooms();
      _handleRouteArguments();
    });
  }

  /// Handle route arguments for quick booking conversion
  Future<void> _handleRouteArguments() async {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      final source = args['source'] as String?;

      if (source == 'quick_booking_reminder') {
        _isFromQuickBooking = true;
        _sourceBookingId = args['bookingId'] as String?;

        // Load booking data
        if (_sourceBookingId != null) {
          final bookingProvider = context.read<RoomBookingProvider>();
          final booking =
              await bookingProvider.getBookingById(_sourceBookingId!);

          if (booking != null) {
            _sourceBooking = booking;

            // Check if booking is expired
            if (booking.status == BookingStatus.releasedBySystem) {
              _bookingExpired = true;
              if (mounted) {
                _showBookingExpiredDialog();
              }
            } else {
              // Auto-fill fields
              _autoFillFromBooking(booking);
            }
          }
        } else {
          // Use data from arguments directly
          _autoFillFromArguments(args);
        }

        setState(() {});
      }
    }
  }

  /// Auto-fill form fields from booking data
  void _autoFillFromBooking(RoomBooking booking) {
    _titleController.text = booking.title;
    if (booking.description != null && booking.description!.isNotEmpty) {
      _descriptionController.text = booking.description!;
    }

    _selectedDate = booking.startTime;
    _startTime = TimeOfDay.fromDateTime(booking.startTime);
    _endTime = TimeOfDay.fromDateTime(booking.endTime);

    // Find and set the room
    final roomProvider = context.read<RoomProvider>();
    final room = roomProvider.rooms.firstWhere(
      (r) => r.id == booking.roomId,
      orElse: () => roomProvider.rooms.first,
    );
    _selectedRoom = room;
    _locationType = MeetingLocationType.physical;

    debugPrint('[MeetingCreate] Auto-filled from booking: ${booking.id}');
  }

  /// Auto-fill form fields from route arguments
  void _autoFillFromArguments(Map<String, dynamic> args) {
    final title = args['title'] as String?;
    final description = args['description'] as String?;
    final roomId = args['roomId'] as String?;
    final startTimeStr = args['startTime'] as String?;
    final endTimeStr = args['endTime'] as String?;

    if (title != null) _titleController.text = title;
    if (description != null) _descriptionController.text = description;

    if (startTimeStr != null) {
      final startTime = DateTime.tryParse(startTimeStr);
      if (startTime != null) {
        _selectedDate = startTime;
        _startTime = TimeOfDay.fromDateTime(startTime);
      }
    }

    if (endTimeStr != null) {
      final endTime = DateTime.tryParse(endTimeStr);
      if (endTime != null) {
        _endTime = TimeOfDay.fromDateTime(endTime);
      }
    }

    // Find and set the room
    if (roomId != null) {
      final roomProvider = context.read<RoomProvider>();
      final room = roomProvider.rooms.firstWhere(
        (r) => r.id == roomId,
        orElse: () => roomProvider.rooms.first,
      );
      _selectedRoom = room;
      _locationType = MeetingLocationType.physical;
    }

    debugPrint('[MeetingCreate] Auto-filled from arguments');
  }

  /// Show dialog when booking has expired
  void _showBookingExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Đặt phòng đã hết hạn'),
          ],
        ),
        content: const Text(
          'Đặt phòng của bạn đã bị hủy do không tạo cuộc họp kịp thời.\n\n'
          'Vui lòng chọn phòng khác để tiếp tục tạo cuộc họp.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Reset room selection
              setState(() {
                _selectedRoom = null;
                _bookingExpired = false;
              });
            },
            child: const Text('Chọn phòng khác'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateState);
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _virtualLinkController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  // ─────────────────────── AI HELPERS ───────────────────────

  /// Gợi ý khung giờ họp thông minh bằng Gemini
  Future<void> _showTimeSuggestions() async {
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người tham dự trước')),
      );
      return;
    }

    setState(() => _isLoadingTimeSuggestion = true);

    try {
      final participantIds = _selectedParticipants.map((u) => u.id).toList();
      final participantNames = {
        for (final u in _selectedParticipants) u.id: u.displayName,
      };
      final durationMinutes = _endTime.hour * 60 +
          _endTime.minute -
          _startTime.hour * 60 -
          _startTime.minute;
      final duration = durationMinutes > 0 ? durationMinutes : 60;

      final slots = await _scheduleService.suggestTimeSlots(
        participantIds: participantIds,
        participantNames: participantNames,
        targetDate: _selectedDate,
        durationMinutes: duration,
      );

      if (!mounted) return;
      _showTimeSuggestionBottomSheet(slots);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gợi ý giờ: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingTimeSuggestion = false);
    }
  }

  /// Hiển thị bottom sheet chứa danh sách giờ gợi ý
  void _showTimeSuggestionBottomSheet(List<SuggestedTimeSlot> slots) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.7, // Giới hạn chiều cao 70% màn hình
        child: _AiTimeSuggestionSheet(
          slots: slots,
          targetDate: _selectedDate,
          onSelect: (slot) {
            setState(() {
              _startTime = TimeOfDay(hour: slot.startHour, minute: slot.startMinute);
              _endTime   = TimeOfDay(hour: slot.endHour,   minute: slot.endMinute);
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã áp dụng: ${slot.start} – ${slot.end}'),
                backgroundColor: Colors.green.shade600,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Gợi ý agenda bằng Gemini và hiển thị dialog
  Future<void> _suggestAgenda() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề trước')),
      );
      return;
    }

    setState(() => _isLoadingAgenda = true);

    try {
      final durationMinutes = _endTime.hour * 60 +
          _endTime.minute -
          _startTime.hour * 60 -
          _startTime.minute;

      final meetingTypeStr = {
        MeetingType.personal:   'Cá nhân',
        MeetingType.team:       'Team',
        MeetingType.department: 'Phòng ban',
        MeetingType.company:    'Toàn công ty',
      }[_meetingType] ?? 'Thông thường';

      final agenda = await GeminiService.suggestAgenda(
        meetingTitle:      title,
        meetingType:       meetingTypeStr,
        durationMinutes:   durationMinutes > 0 ? durationMinutes : 60,
        participantsCount: _selectedParticipants.length,
      );

      if (!mounted) return;
      _showAgendaBottomSheet(
        agenda,
        title,
        durationMinutes > 0 ? durationMinutes : 60,
        _selectedParticipants.length,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gợi ý agenda: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAgenda = false);
    }
  }

  void _showAgendaBottomSheet(String agenda, String meetingTitle, int durationMinutes, int participantsCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5), // Tăng lên 0.5 theo yêu cầu
      elevation: 0,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.7, // Chính xác 0.7 theo yêu cầu
        child: _AiAgendaBottomSheet(
          agendaRawText: agenda,
          meetingTitle: meetingTitle,
          durationMinutes: durationMinutes,
          participantsCount: participantsCount,
          onApply: (String processedAgenda) {
            _descriptionController.text = processedAgenda;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã điền agenda vào phần mô tả'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  bool get _canCreate {
    bool basicCheck = _titleController.text.trim().isNotEmpty &&
        _selectedParticipants.isNotEmpty;

    // For physical/hybrid meetings, room must be selected
    if (_locationType == MeetingLocationType.physical ||
        _locationType == MeetingLocationType.hybrid) {
      if (!basicCheck || _selectedRoom == null) return false;
    } else {
      if (!basicCheck) return false;
    }

    // Check if start time is in the past (with 5 minutes grace period)
    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    final now = DateTime.now();
    const gracePeriod = Duration(minutes: 5);
    final minStartTime = now.subtract(gracePeriod);

    if (startDateTime.isBefore(minStartTime)) {
      return false; // Disable create button if meeting is in the past
    }

    return true;
  }

  void _handleCreate() async {
    // Logic remains same as previous working version
    // if (!_canCreate) return; // Removed implicit check

    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tiêu đề cuộc họp')),
        );
      }
      return;
    }

    if (_selectedParticipants.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn ít nhất một người tham gia')),
        );
      }
      return;
    }

    // Validate room selection for physical/hybrid meetings
    if ((_locationType == MeetingLocationType.physical ||
            _locationType == MeetingLocationType.hybrid) &&
        _selectedRoom == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn phòng họp')),
        );
      }
      return;
    }

    // YÊU CẦU: Với các loại họp khác "Cá nhân", bắt buộc phải chọn thư ký.
    if (_meetingType != MeetingType.personal && _selectedSecretary == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng chọn Thư ký cuộc họp trước khi lưu',
            ),
          ),
        );
      }
      return;
    }

    // (Vẫn giữ thay đổi mới: không bắt buộc mô tả tối thiểu 10 ký tự.)

    // Validate: Cannot create meeting in the past (with 5 minutes grace period)
    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    final now = DateTime.now();
    const gracePeriod = Duration(minutes: 5);
    final minStartTime = now.subtract(gracePeriod);

    if (startDateTime.isBefore(minStartTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Không thể tạo cuộc họp trong quá khứ. Thời gian bắt đầu phải sau ${minStartTime.hour}:${minStartTime.minute.toString().padLeft(2, '0')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint(
          '[MEETING_CREATE] VALIDATION FAILED: startDateTime=$startDateTime is before minStartTime=$minStartTime');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.userModel;

      if (currentUser == null) throw Exception('User not found');

      final meetingProvider = context.read<MeetingProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      final participants = _selectedParticipants.map((u) {
        String role = 'participant';
        if (_selectedSecretary?.id == u.id) role = 'secretary';
        // Auto-accept if user is the creator, otherwise pending
        final status = (u.id == currentUser.id)
            ? ParticipantAttendanceStatus.accepted
            : ParticipantAttendanceStatus.pending;

        return MeetingParticipant(
          userId: u.id,
          userName: u.displayName,
          userEmail: u.email,
          role: role,
          isRequired: true,
          attendanceStatus: status,
          confirmedAt: status == ParticipantAttendanceStatus.accepted
              ? DateTime.now()
              : null,
        );
      }).toList();

      if (!participants.any((p) => p.userId == currentUser.id)) {
        participants.insert(
            0,
            MeetingParticipant(
              userId: currentUser.id,
              userName: currentUser.displayName,
              userEmail: currentUser.email,
              role: 'chair',
              isRequired: true,
              attendanceStatus: ParticipantAttendanceStatus.accepted,
              confirmedAt: DateTime.now(),
            ));
      }

      final startDateTime = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, _startTime.hour, _startTime.minute);

      final endDateTime = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, _endTime.hour, _endTime.minute);

      // Log selected room info before creating meeting
      if (_selectedRoom != null) {
        debugPrint(
            '[MEETING_CREATE][ROOM_SELECTED] roomId=${_selectedRoom!.id} '
            'roomName=${_selectedRoom!.name} '
            'source=RoomProvider.docId '
            'isDocId=${_selectedRoom!.id.length > 10}'); // DocId typically > 10 chars
      }

      final meeting = MeetingModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _meetingType, // Spec 3.3: Use selected meeting type
        status: MeetingStatus.pending,
        locationType: _locationType,
        priority: _priority,
        startTime: startDateTime,
        endTime: endDateTime,
        durationMinutes: endDateTime.difference(startDateTime).inMinutes,
        // Room booking - use selected room from RoomProvider (docId format)
        roomId: _selectedRoom?.id,
        roomName: _selectedRoom?.name,
        physicalLocation:
            _selectedRoom?.name ?? _locationController.text.trim(),
        virtualMeetingLink: _locationType == MeetingLocationType.virtual
            ? _virtualLinkController.text.trim()
            : null,
        creatorId: currentUser.id,
        creatorName: currentUser.displayName,
        participants: List<MeetingParticipant>.from(participants),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRecurring: false,
        scope: _isPublic ? MeetingScope.company : MeetingScope.team,
        approvalStatus: MeetingApprovalStatus.pending,
        approvalReason: _descriptionController.text.trim(),
      );

      final result = await meetingProvider.createMeeting(
          meeting, currentUser, notificationProvider);

      if (mounted) {
        if (result != null) {
          // Convert quick booking to meeting if applicable
          if (_isFromQuickBooking && _sourceBookingId != null) {
            final bookingProvider = context.read<RoomBookingProvider>();
            await bookingProvider.convertToMeeting(
                _sourceBookingId!, result.id);

            // Unlock user if they were restricted
            await bookingProvider
                .unlockUserAfterSuccessfulConversion(currentUser.id);

            debugPrint(
                '[MeetingCreate] Converted booking $_sourceBookingId to meeting ${result.id}');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isFromQuickBooking
                  ? 'Đã tạo cuộc họp và xác nhận đặt phòng!'
                  : 'Tạo cuộc họp thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(meetingProvider.error ?? 'Thất bại')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: _screenBg,
        body: Column(
          children: [
            // Dark teal header
            Container(
              decoration: const BoxDecoration(
                color: _headerTeal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top bar with Cancel, Meeting, Save
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamedAndRemoveUntil(
                                    '/home', (route) => false),
                            child: const Text(
                              'H\u1ee7y',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Text(
                            'Cu\u1ed9c h\u1ecdp',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: _isCreating ? null : _handleCreate,
                            child: _isCreating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'L\u01b0u',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Title input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Th\u00eam ti\u00eau \u0111\u1ec1',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // White content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick booking banner
                    if (_isFromQuickBooking &&
                        _sourceBooking != null &&
                        !_bookingExpired)
                      _buildQuickBookingBanner(),

                    // Date + time card
                    _buildDateTimeCard(),
                    const SizedBox(height: 16),

                    // Description
                    _buildDescriptionField(),
                    const SizedBox(height: 16),

                    // Meeting Type
                    _buildMeetingTypeField(),
                    const SizedBox(height: 16),

                    // Location
                    _buildLocationField(),
                    const SizedBox(height: 16),

                    // Participants
                    _buildParticipantsSection(),
                    const SizedBox(height: 16),

                    // Priority
                    _buildPrioritySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return _card(
      child: Column(
        children: [
          InkWell(
            onTap: _showDateTimePicker,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _sectionIcon(Icons.calendar_today_rounded,
                      bg: const Color(0xFFEFF6FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DATE', style: _kSectionLabel),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateFull(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: _placeholder, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─── Nút gợi ý giờ họp AI ───
          GestureDetector(
            onTap: _isLoadingTimeSuggestion ? null : _showTimeSuggestions,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: _selectedParticipants.isEmpty
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1C8EF9), Color(0xFF7C5CFC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: _selectedParticipants.isEmpty
                    ? const Color(0xFFF2F4F7)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingTimeSuggestion
                  ? const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          _selectedParticipants.isEmpty
                              ? 'Chọn người tham dự để gợi ý giờ'
                              : 'Gợi ý khung giờ thông minh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedParticipants.isEmpty
                                ? const Color(0xFF98A2B3)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE4E7EC)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showTimePicker(true),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 18, color: _textSecondary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(_startTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_downward_rounded,
                  color: Color(0xFF98A2B3), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showTimePicker(false),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('End',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(_endTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded,
                          size: 18, color: _textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build banner showing quick booking info
  Widget _buildQuickBookingBanner() {
    final booking = _sourceBooking!;
    final timeFormat = DateFormat('HH:mm');
    final minutesRemaining = booking.minutesUntilAutoRelease;
    final isUrgent = minutesRemaining <= 5 && minutesRemaining > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [Colors.red.shade50, Colors.red.shade100]
              : [Colors.purple.shade50, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade300 : Colors.purple.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Đã giữ chỗ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (booking.isOngoing && minutesRemaining > 0) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color:
                      isUrgent ? Colors.red.shade700 : Colors.purple.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Còn $minutesRemaining phút',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isUrgent ? Colors.red.shade700 : Colors.purple.shade700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn đang tạo cuộc họp từ đặt phòng nhanh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.meeting_room, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                booking.roomName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (isUrgent) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Hoàn thành ngay để xác nhận đặt phòng!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _sectionIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: _kSectionLabel),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: _placeholder, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.description_outlined,
                  bg: const Color(0xFFF1ECFF)),
              const SizedBox(width: 12),
              Text('MÔ TẢ / AGENDA', style: _kSectionLabel),
              const Spacer(),
              // ─── Nút gợi ý agenda AI ───
              GestureDetector(
                onTap: _isLoadingAgenda ? null : _suggestAgenda,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFC), Color(0xFF9B7CFF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isLoadingAgenda
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🤖', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'Gợi ý AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 15, color: _textPrimary),
            decoration: const InputDecoration(
              hintText: 'Thêm mô tả hoặc dùng AI để gợi ý agenda...',
              hintStyle: TextStyle(color: _placeholder),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    final title = _locationType == MeetingLocationType.physical
        ? '\u0110\u1ecba \u0111i\u1ec3m'
        : _locationType == MeetingLocationType.virtual
            ? 'Link cu\u1ed9c h\u1ecdp'
            : 'Cu\u1ed9c h\u1ecdp k\u1ebft h\u1ee3p';
    final icon = _locationType == MeetingLocationType.physical
        ? Icons.location_on_outlined
        : _locationType == MeetingLocationType.virtual
            ? Icons.videocam_outlined
            : Icons.hub_outlined;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(icon, bg: const Color(0xFFF2F4F7)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary))),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLocationTypeButton(
                        Icons.location_on, MeetingLocationType.physical),
                    _buildLocationTypeButton(
                        Icons.videocam, MeetingLocationType.virtual),
                    _buildLocationTypeButton(
                        Icons.hub, MeetingLocationType.hybrid),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_locationType == MeetingLocationType.physical ||
              _locationType == MeetingLocationType.hybrid)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    style: const TextStyle(fontSize: 15, color: _textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter room or address...',
                      hintStyle: TextStyle(color: _placeholder),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.navigation_rounded, color: _headerTeal),
                  onPressed: _showRoomSuggestions,
                  tooltip: 'Suggest rooms',
                ),
              ],
            ),
          if (_locationType == MeetingLocationType.virtual ||
              _locationType == MeetingLocationType.hybrid)
            Padding(
              padding: EdgeInsets.only(
                  top: _locationType == MeetingLocationType.hybrid ? 10 : 0),
              child: TextField(
                controller: _virtualLinkController,
                style: const TextStyle(fontSize: 15, color: _textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Paste Zoom/Meet/Teams link...',
                  hintStyle: TextStyle(color: _placeholder),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  prefixIcon: Icon(Icons.link, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationTypeButton(IconData icon, MeetingLocationType type) {
    final isSelected = _locationType == type;
    return InkWell(
      onTap: () => setState(() => _locationType = type),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? _headerTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : const Color(0xFF667085),
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Participants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _showParticipantSelector,
              child: const Text(
                'Add',
                style: TextStyle(
                  color: _headerTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        _card(
          child: Column(
            children: [
              _buildParticipantTile(
                currentUser?.displayName ?? 'You',
                'Creator',
                (currentUser?.displayName ?? 'Y').substring(0, 1).toUpperCase(),
                isCreator: true,
              ),
              const Divider(height: 20, color: Color(0xFFE4E7EC)),
              _buildSecretarySection(inCard: true),
              if (_selectedParticipants.isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFE4E7EC)),
                ...(_selectedParticipants.take(3).map(
                      (user) => _buildParticipantTile(
                        user.displayName,
                        user.email,
                        user.displayName.substring(0, 1).toUpperCase(),
                      ),
                    )),
                if (_selectedParticipants.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 52, top: 4),
                      child: Text(
                        '+${_selectedParticipants.length - 3} more',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(String name, String subtitle, String initial,
      {bool isCreator = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isCreator ? _headerTeal : const Color(0xFFE4E7EC),
            child: Text(
              initial,
              style: TextStyle(
                color: isCreator ? Colors.white : const Color(0xFF475467),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretarySection({bool inCard = false}) {
    final content = InkWell(
      onTap: _showSecretarySelector,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: inCard ? 0 : 6),
        child: Row(
          children: [
            _sectionIcon(Icons.assignment_ind_outlined,
                bg: const Color(0xFFEFF6FF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Th\u01b0 k\u00fd', style: _kSectionLabel),
                  const SizedBox(height: 4),
                  Text(
                    _selectedSecretary?.displayName ?? 'T\u00f9y ch\u1ecdn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedSecretary != null
                          ? _textPrimary
                          : _placeholder,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedSecretary != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _selectedSecretary = null),
                color: _placeholder,
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: _placeholder, size: 22),
          ],
        ),
      ),
    );

    if (inCard) return content;
    return _card(child: content);
  }

  Widget _buildPrioritySection() {
    return _card(
      child: InkWell(
        onTap: _showPrioritySelector,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _sectionIcon(Icons.flag_outlined, bg: const Color(0xFFFFF4E5)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mức độ ưu tiên',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            Text(
              _getPriorityText(_priority),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _getPriorityColor(_priority),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: _placeholder, size: 22),
          ],
        ),
      ),
    );
  }

  String _getPriorityText(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return 'Thấp';
      case MeetingPriority.medium:
        return 'Trung bình';
      case MeetingPriority.high:
        return 'Cao';
      case MeetingPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  Color _getPriorityColor(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return Colors.green;
      case MeetingPriority.medium:
        return Colors.orange;
      case MeetingPriority.high:
        return Colors.deepOrange;
      case MeetingPriority.urgent:
        return Colors.red;
    }
  }

  void _showPrioritySelector() {
    final initial = _priority;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PriorityPickerSheet(
          initial: initial,
          accentBlue: _accentBlue,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          placeholder: _placeholder,
          getColor: _getPriorityColor,
          onConfirm: (val) => setState(() => _priority = val),
        );
      },
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7BE9).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D1E),
          ),
        ),
      ],
    );
  }

  // 1. Info Card
  Widget _buildMeetingTypeField() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.category_rounded, bg: const Color(0xFFF3E8FF)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Loại cuộc họp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MeetingType>(
                value: _meetingType,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                onChanged: (MeetingType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _meetingType = newValue;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: MeetingType.personal,
                    child: Text('Cá nhân'),
                  ),
                  DropdownMenuItem(
                    value: MeetingType.team,
                    child: Text('Team'),
                  ),
                  DropdownMenuItem(
                    value: MeetingType.department,
                    child: Text('Phòng ban'),
                  ),
                  DropdownMenuItem(
                    value: MeetingType.company,
                    child: Text('Công ty'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Thông tin cuộc họp', Icons.edit_note_rounded, Colors.blue),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Tiêu đề cuộc họp',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          _buildMeetingTypeSelector(),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Thêm mô tả...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.sort, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // --- Start Added Meeting Type Selector ---
  Widget _buildMeetingTypeSelector() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    // Determine allowed types
    List<MeetingType> allowedTypes = [];
    if (currentUser?.isEmployee == true) {
      allowedTypes = [MeetingType.personal];
      // Force personal if they are an employee
      if (_meetingType != MeetingType.personal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _meetingType = MeetingType.personal);
        });
      }
    } else {
      allowedTypes = MeetingType.values;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionIcon(Icons.category_outlined, bg: const Color(0xFFE3F2FD)),
            const SizedBox(width: 12),
            Text('TYPE', style: _kSectionLabel),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MeetingType>(
              value: _meetingType,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(Icons.arrow_drop_down_rounded,
                  color: _placeholder),
              items: allowedTypes.map((type) {
                return DropdownMenuItem<MeetingType>(
                  value: type,
                  child: Text(
                    _getMeetingTypeText(type),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _meetingType = val);
                }
              },
            ),
          ),
        ),
      ],
    );
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
  // --- End Added Meeting Type Selector ---

  // 2. Time Card
  Widget _buildTimeCard() {
    final startDt = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    final endDt = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _endTime.hour, _endTime.minute);
    final duration = endDt.difference(startDt).inMinutes;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Thời gian', Icons.access_time_filled_rounded, Colors.orange),
          const SizedBox(height: 20),
          InkWell(
            onTap: _showDateTimePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_selectedDate),
                              style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatTime(_startTime)} – ${_formatTime(_endTime)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$duration phút',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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

  // 3. Location Card
  Widget _buildLocationCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Địa điểm', Icons.location_on_rounded, Colors.pink),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MeetingLocationType>(
                value: _locationType,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                icon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.black87),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onChanged: (val) => setState(() => _locationType = val!),
                items: [
                  DropdownMenuItem(
                    value: MeetingLocationType.physical,
                    child: Row(
                      children: [
                        Icon(Icons.business_rounded,
                            size: 20, color: Colors.pink[400]),
                        const SizedBox(width: 12),
                        const Text('Trực tiếp tại văn phòng',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: MeetingLocationType.virtual,
                    child: Row(
                      children: [
                        Icon(Icons.videocam_rounded,
                            size: 20, color: Colors.pink[400]),
                        const SizedBox(width: 12),
                        const Text('Họp Online (Virtual)',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _locationType == MeetingLocationType.physical
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên phòng hoặc địa chỉ...',
                        prefixIcon: Icon(Icons.meeting_room_rounded,
                            color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _virtualLinkController,
                      decoration: const InputDecoration(
                        hintText: 'Dán link Zoom/Meet/Teams...',
                        prefixIcon: Icon(Icons.link_rounded,
                            color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 4. Participants Card
  Widget _buildParticipantsCard() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Người tham gia', Icons.people_alt_rounded, Colors.teal),
          const SizedBox(height: 20),

          // Host
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    currentUser?.displayName.substring(0, 1).toUpperCase() ??
                        'M',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'Tôi',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Text('Chủ trì cuộc họp',
                          style: TextStyle(fontSize: 12, color: Colors.teal)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Host',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Participants Button
          InkWell(
            onTap: _showParticipantSelector,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4)
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thêm người tham gia',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        if (_selectedParticipants.isEmpty)
                          const Text('Chưa chọn ai',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13))
                        else
                          _buildParticipantChips(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 24),

          // Secretary Selector
          InkWell(
            onTap: _showSecretarySelector,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                const Icon(Icons.assignment_ind_rounded,
                    color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thư ký cuộc họp',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                      if (_selectedSecretary != null)
                        Text(_selectedSecretary!.displayName,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.teal))
                    ],
                  ),
                ),
                if (_selectedSecretary != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _selectedSecretary = null),
                  )
                else
                  const Text('Tuỳ chọn',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantChips() {
    final count = _selectedParticipants.length;
    final names = _selectedParticipants
        .take(2)
        .map((u) => u.displayName.split(' ').last)
        .join(', ');
    final remaining = count - 2;

    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        children: [
          TextSpan(
              text: names,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (remaining > 0)
            TextSpan(
                text: ' và $remaining người khác',
                style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 5. Advanced Card
  Widget _buildAdvancedCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, size: 22, color: Colors.black54),
              SizedBox(width: 12),
              Text('Cấu hình nâng cao',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            // Priority
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mức độ ưu tiên',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        _priority == MeetingPriority.urgent
                            ? 'Quan trọng & Khẩn cấp'
                            : _priority == MeetingPriority.high
                                ? 'Cao'
                                : 'Bình thường',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MeetingPriority>(
                      value: _priority,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: const [
                        DropdownMenuItem(
                            value: MeetingPriority.low, child: Text('Thấp')),
                        DropdownMenuItem(
                            value: MeetingPriority.medium,
                            child: Text('Trung bình')),
                        DropdownMenuItem(
                            value: MeetingPriority.high, child: Text('Cao')),
                        DropdownMenuItem(
                            value: MeetingPriority.urgent,
                            child: Text('Khẩn cấp',
                                style: TextStyle(color: Colors.red))),
                      ],
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Public Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Công khai danh sách',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Mọi người có thể thấy ai tham gia',
                  style: TextStyle(fontSize: 13)),
              value: _isPublic,
              activeColor: const Color(0xFF2E7BE9),
              onChanged: (val) => setState(() => _isPublic = val),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Helpers ---

  Future<void> _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C5F6F)), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _showTimePicker(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C5F6F)),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      if (isStartTime) {
        _startTime = time;
        // Auto-adjust end time if it's before start time
        final startDt = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, time.hour, time.minute);
        final endDt = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, _endTime.hour, _endTime.minute);
        if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
          _endTime =
              TimeOfDay.fromDateTime(startDt.add(const Duration(hours: 1)));
        }
      } else {
        _endTime = time;
      }
    });
  }

  String _formatDateFull(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'H\u00f4m nay, ${DateFormat('dd MMM yyyy').format(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Ng\u00e0y mai, ${DateFormat('dd MMM yyyy').format(date)}';
    }
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  String _formatDate(DateTime date) {
    if (date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day) {
      return 'Hôm nay';
    }
    return DateFormat('EEEE, dd/MM', 'vi').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  void _showParticipantSelector() async {
    final orgProvider = context.read<OrganizationProvider>();

    // Load departments if not already loaded
    if (orgProvider.availableDepartments.isEmpty) {
      await orgProvider.loadDepartments();
    }

    if (!mounted) return;

    _showDepartmentParticipantDialog(orgProvider);
  }

  void _showDepartmentParticipantDialog(OrganizationProvider orgProvider) {
    final departments = orgProvider.availableDepartments;

    // Track expanded departments and their users
    Map<String, List<UserModel>> departmentUsersMap = {};
    Set<String> expandedDepartments = {};
    Map<String, String> teamNamesMap = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_rounded,
                              color: Color(0xFF2C5F6F), size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Chọn người tham gia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm người dùng...',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Department list
                    Expanded(
                      child: departments.isEmpty
                          ? const Center(child: Text('Không có phòng ban nào'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: departments.length,
                              itemBuilder: (context, index) {
                                final dept = departments[index];
                                final isExpanded =
                                    expandedDepartments.contains(dept.id);
                                final users = departmentUsersMap[dept.id] ?? [];
                                final memberCount = dept.memberIds.length;

                                // Calculate selection state
                                int selectedCount = 0;
                                for (var user in users) {
                                  if (_selectedParticipants
                                      .any((p) => p.id == user.id)) {
                                    selectedCount++;
                                  }
                                }

                                bool isDeptFullySelected = users.isNotEmpty &&
                                    selectedCount == users.length;

                                return Column(
                                  children: [
                                    // Department header
                                    InkWell(
                                      onTap: () async {
                                        setStateDialog(() {
                                          if (isExpanded) {
                                            expandedDepartments.remove(dept.id);
                                          } else {
                                            expandedDepartments.add(dept.id);
                                          }
                                        });

                                        // Load users if not loaded
                                        if (!departmentUsersMap
                                            .containsKey(dept.id)) {
                                          await orgProvider
                                              .loadTeamsByDepartment(dept.id);
                                          for (var t
                                              in orgProvider.availableTeams) {
                                            teamNamesMap[t.id] = t.name;
                                          }
                                          await orgProvider
                                              .loadDepartmentUsers(dept.id);
                                          setStateDialog(() {
                                            departmentUsersMap[dept.id] =
                                                List.from(orgProvider
                                                    .departmentUsers);
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_down
                                                  : Icons.chevron_right,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.folder,
                                              color: Colors.blue[400],
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    dept.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$memberCount người',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isDeptFullySelected
                                                      ? const Color(0xFF2C5F6F)
                                                      : Colors.grey[400]!,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color: isDeptFullySelected
                                                    ? const Color(0xFF2C5F6F)
                                                    : Colors.transparent,
                                              ),
                                              child: isDeptFullySelected
                                                  ? const Icon(Icons.check,
                                                      size: 14,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // User list (when expanded)
                                    if (isExpanded)
                                      ...() {
                                        final groupedUsers =
                                            <String, List<UserModel>>{};
                                        for (var user in users) {
                                          final tId =
                                              user.teamId?.isNotEmpty == true
                                                  ? user.teamId!
                                                  : 'unassigned';
                                          groupedUsers
                                              .putIfAbsent(tId, () => [])
                                              .add(user);
                                        }

                                        final sortedTeamIds = groupedUsers.keys
                                            .toList()
                                          ..sort((a, b) {
                                            if (a == 'unassigned') return 1;
                                            if (b == 'unassigned') return -1;
                                            final nameA = teamNamesMap[a] ?? a;
                                            final nameB = teamNamesMap[b] ?? b;
                                            return nameA.compareTo(nameB);
                                          });

                                        final widgets = <Widget>[];
                                        for (var teamId in sortedTeamIds) {
                                          final teamName = teamId ==
                                                      'unassigned' ||
                                                  teamId.endsWith('__general')
                                              ? 'Chung (Chưa phân team)'
                                              : (teamNamesMap[teamId] ??
                                                  teamId);

                                          widgets.add(
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 44, top: 8, bottom: 4),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  teamName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );

                                          widgets.addAll(
                                              groupedUsers[teamId]!.map((user) {
                                            final isSelected =
                                                _selectedParticipants.any(
                                                    (p) => p.id == user.id);
                                            return InkWell(
                                              onTap: () {
                                                setStateDialog(() {
                                                  if (isSelected) {
                                                    _selectedParticipants
                                                        .removeWhere((p) =>
                                                            p.id == user.id);
                                                  } else {
                                                    _selectedParticipants
                                                        .add(user);
                                                  }
                                                });
                                                setState(() {});
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    left: 44, bottom: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      child: Text(
                                                        user.displayName
                                                                .isNotEmpty
                                                            ? user.displayName
                                                                .substring(0, 1)
                                                                .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            user.displayName,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          Text(
                                                            user.email,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xFFFF9800),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color: Colors
                                                                  .grey[300]!,
                                                              width: 2),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }));
                                        }
                                        return widgets;
                                      }(),

                                    if (index < departments.length - 1)
                                      Divider(
                                          height: 1, color: Colors.grey[200]),
                                  ],
                                );
                              },
                            ),
                    ),

                    // Footer buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Hủy',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5F6F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Xác nhận (${_selectedParticipants.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
        );
      },
    );
  }

  void _showSecretarySelector() async {
    final orgProvider = context.read<OrganizationProvider>();

    // Load departments if not already loaded
    if (orgProvider.availableDepartments.isEmpty) {
      await orgProvider.loadDepartments();
    }

    if (!mounted) return;

    _showDepartmentSecretaryDialog(orgProvider);
  }

  void _showDepartmentSecretaryDialog(OrganizationProvider orgProvider) {
    final departments = orgProvider.availableDepartments;

    // Track expanded departments and their users
    Map<String, List<UserModel>> departmentUsersMap = {};
    Set<String> expandedDepartments = {};
    Map<String, String> teamNamesMap = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_ind_rounded,
                              color: Color(0xFF2C5F6F), size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Chọn thư ký',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm người dùng...',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Department list
                    Expanded(
                      child: departments.isEmpty
                          ? const Center(child: Text('Không có phòng ban nào'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: departments.length,
                              itemBuilder: (context, index) {
                                final dept = departments[index];
                                final isExpanded =
                                    expandedDepartments.contains(dept.id);
                                final users = departmentUsersMap[dept.id] ?? [];
                                final memberCount = dept.memberIds.length;

                                return Column(
                                  children: [
                                    // Department header
                                    InkWell(
                                      onTap: () async {
                                        setStateDialog(() {
                                          if (isExpanded) {
                                            expandedDepartments.remove(dept.id);
                                          } else {
                                            expandedDepartments.add(dept.id);
                                          }
                                        });

                                        // Load users if not loaded
                                        if (!departmentUsersMap
                                            .containsKey(dept.id)) {
                                          await orgProvider
                                              .loadTeamsByDepartment(dept.id);
                                          for (var t
                                              in orgProvider.availableTeams) {
                                            teamNamesMap[t.id] = t.name;
                                          }
                                          await orgProvider
                                              .loadDepartmentUsers(dept.id);
                                          setStateDialog(() {
                                            departmentUsersMap[dept.id] =
                                                List.from(orgProvider
                                                    .departmentUsers);
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_down
                                                  : Icons.chevron_right,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.folder,
                                              color: Colors.blue[400],
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    dept.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$memberCount người',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // User list (when expanded)
                                    if (isExpanded)
                                      ...() {
                                        final groupedUsers =
                                            <String, List<UserModel>>{};
                                        for (var user in users) {
                                          final tId =
                                              user.teamId?.isNotEmpty == true
                                                  ? user.teamId!
                                                  : 'unassigned';
                                          groupedUsers
                                              .putIfAbsent(tId, () => [])
                                              .add(user);
                                        }

                                        final sortedTeamIds = groupedUsers.keys
                                            .toList()
                                          ..sort((a, b) {
                                            if (a == 'unassigned') return 1;
                                            if (b == 'unassigned') return -1;
                                            final nameA = teamNamesMap[a] ?? a;
                                            final nameB = teamNamesMap[b] ?? b;
                                            return nameA.compareTo(nameB);
                                          });

                                        final widgets = <Widget>[];
                                        for (var teamId in sortedTeamIds) {
                                          final teamName = teamId ==
                                                      'unassigned' ||
                                                  teamId.endsWith('__general')
                                              ? 'Chung (Chưa phân team)'
                                              : (teamNamesMap[teamId] ??
                                                  teamId);

                                          widgets.add(
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 44, top: 8, bottom: 4),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  teamName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );

                                          widgets.addAll(
                                              groupedUsers[teamId]!.map((user) {
                                            final isSelected =
                                                _selectedSecretary?.id ==
                                                    user.id;
                                            return InkWell(
                                              onTap: () {
                                                setState(() =>
                                                    _selectedSecretary = user);
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    left: 44, bottom: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      child: Text(
                                                        user.displayName
                                                                .isNotEmpty
                                                            ? user.displayName
                                                                .substring(0, 1)
                                                                .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            user.displayName,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          Text(
                                                            user.email,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xFFFF9800),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color: Colors
                                                                  .grey[300]!,
                                                              width: 2),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }));
                                        }
                                        return widgets;
                                      }(),

                                    if (index < departments.length - 1)
                                      Divider(
                                          height: 1, color: Colors.grey[200]),
                                  ],
                                );
                              },
                            ),
                    ),

                    // Footer button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Đóng',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
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
        );
      },
    );
  }

  bool _useRecommendation = false;

  void _showRoomSuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator:
          true, // Fix shadow overlay bug by ensuring 1 root navigator modal
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room,
                              color: Color(0xFF2C5F6F), size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Phòng họp',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Filters (Recommendation Toggle)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  _useRecommendation = !_useRecommendation;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _useRecommendation
                                      ? const Color(0xFF2C5F6F).withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _useRecommendation
                                        ? const Color(0xFF2C5F6F)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        size: 16,
                                        color: _useRecommendation
                                            ? const Color(0xFF2C5F6F)
                                            : Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('Gợi ý phòng phù hợp',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _useRecommendation
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _useRecommendation
                                              ? const Color(0xFF2C5F6F)
                                              : Colors.black87,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Room list from RoomProvider with time-range availability
                    Expanded(
                      child: Consumer2<RoomProvider, MeetingProvider>(
                        builder:
                            (context, roomProvider, meetingProvider, child) {
                          if (roomProvider.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          // Only show bookable rooms (available status, not maintenance/disabled)
                          List<RoomModel> bookableRooms =
                              List.from(roomProvider.bookableRooms);

                          if (bookableRooms.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.meeting_room_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không có phòng họp khả dụng',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Get time range for availability check
                          final startDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _startTime.hour,
                            _startTime.minute,
                          );
                          final endDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _endTime.hour,
                            _endTime.minute,
                          );

                          // Check room availability for the selected time range
                          return FutureBuilder<Map<String, RoomBookingStatus>>(
                            future:
                                meetingProvider.getRoomAvailabilityForTimeRange(
                              startTime: startDateTime,
                              endTime: endDateTime,
                              roomIds: bookableRooms.map((r) => r.id).toList(),
                            ),
                            builder: (context, snapshot) {
                              final availability = snapshot.data ?? {};
                              List<dynamic> displayRooms = bookableRooms;

                              if (_useRecommendation) {
                                print(
                                    '[RECOMMENDATION] Running recommendation engine for ${bookableRooms.length} rooms.');
                                final results =
                                    RoomRecommendationEngine.recommendRooms(
                                  participantsCount:
                                      (_selectedParticipants.length + 1)
                                          .clamp(1, 999),
                                  requiredAmenities: [], // Can implement further amenity selection logic later
                                  locationType: _locationType,
                                  startTime: startDateTime,
                                  endTime: endDateTime,
                                  allRooms: bookableRooms,
                                  availabilityData: availability,
                                );

                                // Show top 5 rooms log
                                int count = 0;
                                for (var res in results) {
                                  if (count++ < 5) {
                                    print(
                                        '[RECOMMENDATION] Rank $count: ${res.room.name} | Score: ${res.score} | Available: ${res.isAvailable}');
                                  }
                                }

                                displayRooms = results;
                              }

                              return ListView.builder(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: displayRooms.length,
                                itemBuilder: (context, index) {
                                  final item = displayRooms[index];
                                  if (item is RoomRecommendationResult) {
                                    return _buildRoomItemWithStatus(
                                        item.room,
                                        availability[item.room.id] ??
                                            RoomBookingStatus.available,
                                        recommendation: item);
                                  } else {
                                    final room = item as RoomModel;
                                    final status = availability[room.id] ??
                                        RoomBookingStatus.available;
                                    return _buildRoomItemWithStatus(
                                        room, status);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRoomItem(RoomModel room) {
    return _buildRoomItemWithStatus(room, RoomBookingStatus.available);
  }

  Widget _buildRoomItemWithStatus(RoomModel room, RoomBookingStatus status,
      {RoomRecommendationResult? recommendation}) {
    final bool isSelected = _selectedRoom?.id == room.id;
    final bool isAvailable = status == RoomBookingStatus.available;
    final bool isPending = status == RoomBookingStatus.pendingReserved;
    final bool isBooked = status == RoomBookingStatus.booked;

    // Determine colors and states based on availability
    Color backgroundColor = isSelected
        ? const Color(0xFF2C5F6F).withOpacity(0.1)
        : (isAvailable ? Colors.white : Colors.grey[100]!);
    Color borderColor = isSelected
        ? const Color(0xFF2C5F6F)
        : (isAvailable ? Colors.grey[200]! : Colors.grey[300]!);
    Color textColor = isAvailable
        ? (isSelected ? const Color(0xFF2C5F6F) : Colors.black87)
        : Colors.grey[500]!;

    return InkWell(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedRoom = room;
                _locationController.text =
                    '${room.name} - ${room.floor} - ${room.building}';
              });
              Navigator.pop(context);
            }
          : null, // Disable tap for unavailable rooms
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.meeting_room,
              color: isAvailable
                  ? (isSelected ? const Color(0xFF2C5F6F) : Colors.grey[600])
                  : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                      ),
                      // Status badge
                      if (!isAvailable) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPending
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isPending ? Colors.orange : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isPending ? 'Đang chờ duyệt' : 'Đã đặt',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isPending
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room.capacity} người • ${room.building} • Tầng ${room.floor}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? Colors.grey[600] : Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (room.amenities.isNotEmpty && isAvailable) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: room.amenities.take(3).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getAmenityName(amenity),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (recommendation != null &&
                      recommendation.reasons.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Vì sao gợi ý: ${recommendation.reasons.join(" • ")}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF2C5F6F), size: 24)
                else if (isAvailable)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Chọn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Icon(Icons.block, color: Colors.grey[400], size: 24),

                const SizedBox(height: 8),

                // Button to open Time slots timeline Bottom Sheet
                InkWell(
                  onTap: () async {
                    Navigator.pop(
                        context); // Close suggestion bottom sheet first

                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.white,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return FractionallySizedBox(
                          heightFactor: 0.8,
                          child: RoomTimeSlotsBottomSheet(
                            roomId: room.id,
                            roomName: room.name,
                            selectedDate: _selectedDate,
                            currentStart: DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _startTime.hour,
                              _startTime.minute,
                            ),
                            currentEnd: DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _endTime.hour,
                              _endTime.minute,
                            ),
                            fetchSchedule: Provider.of<MeetingProvider>(context,
                                    listen: false)
                                .getRoomSchedule,
                          ),
                        );
                      },
                    );

                    if (result != null && result is Map<String, dynamic>) {
                      final newStart = result['start'] as DateTime;
                      final newEnd = result['end'] as DateTime;
                      if (mounted) {
                        setState(() {
                          _startTime = TimeOfDay(
                              hour: newStart.hour, minute: newStart.minute);
                          _endTime = TimeOfDay(
                              hour: newEnd.hour, minute: newEnd.minute);

                          // Auto-select room too if they picked a slot
                          _selectedRoom = room;
                          _locationController.text =
                              '${room.name} - ${room.floor} - ${room.building}';
                        });
                      }
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.blue[800]),
                        const SizedBox(width: 4),
                        Text('Xem lịch',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600)),
                      ],
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

  String _getAmenityName(RoomAmenity amenity) {
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
        return 'Nước';
      case RoomAmenity.powerOutlet:
        return 'Ổ điện';
      case RoomAmenity.videoConference:
        return 'Video call';
    }
  }
}

class _PriorityPickerSheet extends StatefulWidget {
  final MeetingPriority initial;
  final Color accentBlue;
  final Color textPrimary;
  final Color textSecondary;
  final Color placeholder;
  final Color Function(MeetingPriority) getColor;
  final ValueChanged<MeetingPriority> onConfirm;

  const _PriorityPickerSheet({
    required this.initial,
    required this.accentBlue,
    required this.textPrimary,
    required this.textSecondary,
    required this.placeholder,
    required this.getColor,
    required this.onConfirm,
  });

  @override
  State<_PriorityPickerSheet> createState() => _PriorityPickerSheetState();
}

class _PriorityPickerSheetState extends State<_PriorityPickerSheet> {
  late MeetingPriority _temp;

  @override
  void initState() {
    super.initState();
    _temp = widget.initial;
  }

  _PriorityOptionData _data(MeetingPriority p) {
    switch (p) {
      case MeetingPriority.low:
        return const _PriorityOptionData(
          title: 'Thấp',
          subtitle: 'Công việc thường nhật, không gấp',
          icon: Icons.spa_rounded,
        );
      case MeetingPriority.medium:
        return const _PriorityOptionData(
          title: 'Trung bình',
          subtitle: 'Cần xử lý trong tuần này',
          icon: Icons.horizontal_rule_rounded,
        );
      case MeetingPriority.high:
        return const _PriorityOptionData(
          title: 'Cao',
          subtitle: 'Quan trọng, deadline gần',
          icon: Icons.keyboard_arrow_up_rounded,
        );
      case MeetingPriority.urgent:
        return const _PriorityOptionData(
          title: 'Khẩn cấp',
          subtitle: 'Cần hành động ngay lập tức',
          icon: Icons.priority_high_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Mức độ ưu tiên',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: widget.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn mức độ quan trọng cho cuộc họp này',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _optionCard(MeetingPriority.low),
                      const SizedBox(height: 12),
                      _optionCard(MeetingPriority.medium),
                      const SizedBox(height: 12),
                      _optionCard(MeetingPriority.high),
                      const SizedBox(height: 12),
                      _optionCard(MeetingPriority.urgent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_temp);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(MeetingPriority p) {
    final isSelected = _temp == p;
    final data = _data(p);
    final color = widget.getColor(p);
    final bg = isSelected
        ? Color.alphaBlend(color.withOpacity(0.12), const Color(0xFFF7F9FC))
        : const Color(0xFFF7F9FC);

    return InkWell(
      onTap: () => setState(() => _temp = p),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: widget.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? color : widget.placeholder.withOpacity(0.6),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityOptionData {
  final String title;
  final String subtitle;
  final IconData icon;
  const _PriorityOptionData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Time Suggestion Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Bottom sheet hiển thị 3 khung giờ gợi ý từ Gemini AI.
class _AiTimeSuggestionSheet extends StatelessWidget {
  final List<SuggestedTimeSlot> slots;
  final DateTime targetDate;
  final void Function(SuggestedTimeSlot slot) onSelect;

  const _AiTimeSuggestionSheet({
    required this.slots,
    required this.targetDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('dd/MM/yyyy', 'vi_VN').format(targetDate);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Tối ưu hóa thời gian\n',
                      style: TextStyle(
                        fontSize: 20, // Thu nhỏ
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'với AI.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // Bo góc nhỏ hơn
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // AI Icon
              Container(
                padding: const EdgeInsets.all(10), // Nhỏ hơn
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1C8EF9), Color(0xFF7C5CFC)],
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Slot cards (Sửa lỗi overflow ở đây)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: slots.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'Không tìm được khung giờ phù hợp.\nVui lòng chọn thủ công.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: slots.asMap().entries.map((entry) {
                          final i = entry.key;
                          final slot = entry.value;
                          return _SlotCard(
                            slot: slot,
                            index: i,
                            isRecommended: i == 0,
                            onTap: () => onSelect(slot),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SuggestedTimeSlot slot;
  final int index;
  final bool isRecommended;
  final VoidCallback onTap;

  const _SlotCard({
    required this.slot,
    required this.index,
    this.isRecommended = false,
    required this.onTap,
  });

  static const List<List<Color>> _badgeGradients = [
    [Color(0xFF1C8EF9), Color(0xFF7C5CFC)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  ];

  @override
  Widget build(BuildContext context) {
    final title = _getTitle(slot);
    final gradientColors = _badgeGradients[index % _badgeGradients.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12), // Giảm spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Giảm bo góc
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000), // Shadow cực mềm
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: gradientColors[0].withOpacity(0.04),
          splashColor: gradientColors[1].withOpacity(0.08),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  gradientColors[0].withOpacity(0.015),
                  gradientColors[1].withOpacity(0.015),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16), // Padding nhỏ gọn
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Layout Cột trái: Thời gian + Nút giữ chỗ
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        slot.start,
                        style: const TextStyle(
                          fontSize: 22, // Size vừa đủ
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'đến',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot.end,
                        style: const TextStyle(
                          fontSize: 22, // Size vừa đủ
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Giữ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider (Đường kẻ mờ)
                Container(
                  width: 1,
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0xFFF1F5F9),
                ),

                // Layout Cột phải: Title + Reason + Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [gradientColors[0], gradientColors[1]],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors[0].withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Khuyên dùng',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 8),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15, // Title gọn hơn
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slot.reason.isNotEmpty ? slot.reason : 'Khung giờ gợi ý lý tưởng cho cuộc họp của bạn.',
                        style: const TextStyle(
                          fontSize: 13, // Reason gọn hơn
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle(SuggestedTimeSlot slot) {
    if (slot.startHour < 12) return 'Trước giờ trưa';
    if (slot.startHour < 15) return 'Đầu giờ chiều';
    if (slot.startHour < 18) return 'Cuối giờ chiều';
    return 'Buổi tối';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Agenda Timeline Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AgendaItemData {
  final String title;
  final String description;
  final String timeText;

  _AgendaItemData({
    required this.title,
    required this.description,
    required this.timeText,
  });
}

class _AiAgendaBottomSheet extends StatelessWidget {
  final String agendaRawText;
  final String meetingTitle;
  final int durationMinutes;
  final int participantsCount;
  final void Function(String) onApply;

  const _AiAgendaBottomSheet({
    required this.agendaRawText,
    required this.meetingTitle,
    required this.durationMinutes,
    required this.participantsCount,
    required this.onApply,
  });

  List<_AgendaItemData> _parseAgenda(String text) {
    final lines = text.split('\n');
    final result = <_AgendaItemData>[];
    
    String currentTitle = '';
    String currentDesc = '';
    String currentTime = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final isListItem = trimmed.startsWith('- ') || 
                         trimmed.startsWith('* ') || 
                         RegExp(r'^\d+\.').hasMatch(trimmed);
      
      if (isListItem) {
        if (currentTitle.isNotEmpty) {
          result.add(_AgendaItemData(
            title: currentTitle,
            description: currentDesc.trim(),
            timeText: currentTime.isNotEmpty ? currentTime : '...',
          ));
          currentDesc = '';
          currentTime = '';
        }

        String rawTitle = trimmed.replaceFirst(RegExp(r'^[\*\-\d\.\s]+'), '').trim();
        
        final timeMatch = RegExp(r'(\d+\s*phút)').firstMatch(rawTitle.toLowerCase());
        if (timeMatch != null) {
          currentTime = timeMatch.group(1)!;
          final timeStrRegex = RegExp(r'\(\s*\d+\s*phút\s*\)|\d+\s*phút\s*:\s*|\d+\s*phút', caseSensitive: false);
          rawTitle = rawTitle.replaceAll(timeStrRegex, '').trim();
          if (rawTitle.startsWith('-')) rawTitle = rawTitle.substring(1).trim();
          if (rawTitle.startsWith(':')) rawTitle = rawTitle.substring(1).trim();
        } else {
          final enMatch = RegExp(r'(\d+\s*min(s|utes)?|\d+m)').firstMatch(rawTitle.toLowerCase());
          if (enMatch != null) {
            currentTime = enMatch.group(1)!;
            rawTitle = rawTitle.replaceAll(RegExp(r'\(\s*\d+\s*min[a-z]*\s*\)|\d+\s*min[a-z]*\s*:\s*', caseSensitive: false), '').trim();
          }
        }
        
        currentTitle = rawTitle;
      } else {
        if (currentTitle.isNotEmpty) {
          currentDesc += '$trimmed\n';
        } else {
          currentTitle = trimmed;
        }
      }
    }

    if (currentTitle.isNotEmpty) {
      result.add(_AgendaItemData(
        title: currentTitle,
        description: currentDesc.trim(),
        timeText: currentTime.isNotEmpty ? currentTime : '...',
      ));
    }

    if (result.isEmpty) {
      result.add(_AgendaItemData(
        title: 'Nội dung Agenda',
        description: text,
        timeText: '${durationMinutes} phút',
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final items = _parseAgenda(agendaRawText);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: const Color(0xFFF8F9FB), // Nền đặc hoàn toàn, không trong suốt
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: Color(0xFF7C5CFC), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Agenda AI gợi ý',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C5CFC),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.grey),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey, size: 20),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intro Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.05)), // Optional viền nhẹ
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C5CFC), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dưới đây là gợi ý agenda cho cuộc họp "$meetingTitle" của bạn:',
                            style: const TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1F2937), // Title color
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, // Fix card bên trong
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), // Nhẹ nhàng cho card con
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.black.withOpacity(0.05)), // Viền nhẹ
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        const Text(
                          'AI GENERATED STRATEGY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF7C5CFC),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          'Agenda Cuộc họp:\n$meetingTitle',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937), // Title
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Info Row
                        Row(
                          children: [
                            _buildInfoChip(Icons.access_time_rounded, '$durationMinutes phút'),
                            const SizedBox(width: 12),
                            _buildInfoChip(Icons.people_outline_rounded, '$participantsCount người'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Timeline
                        ...items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final isLast = i == items.length - 1;
                          return _buildTimelineItem(item, isLast);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section giải thích
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tại sao lại là Agenda này?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937), // Title
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'AI đã phân tích tính chất cuộc họp của bạn. Chúng tôi đề xuất phân bổ thời gian này để giải quyết các vấn đề một cách hiệu quả nhất.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280), // Subtitle
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildTag('TỐI ƯU HÓA'),
                            const SizedBox(width: 8),
                            _buildTag('DỰA TRÊN DỮ LIỆU'),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  ElevatedButton(
                    onPressed: () => onApply(agendaRawText),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF5A45ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Dùng agenda này',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7C5CFC),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(_AgendaItemData item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line & Dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF5A45ED),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937), // Title
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.timeText != '...')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.timeText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A45ED),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: Color(0xFF64748B)), // Darkened icon
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF6B7280), // Subtitle
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

