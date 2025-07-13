import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../providers/meeting_provider.dart';
import '../providers/organization_provider.dart';
import '../components/meeting_basic_form.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class MeetingCreateScreen extends StatefulWidget {
  const MeetingCreateScreen({Key? key}) : super(key: key);

  @override
  State<MeetingCreateScreen> createState() => _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends State<MeetingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _virtualLinkController = TextEditingController();
  final _virtualPasswordController = TextEditingController();

  MeetingType _selectedType = MeetingType.personal;
  MeetingPriority _selectedPriority = MeetingPriority.medium;
  MeetingLocationType _selectedLocationType = MeetingLocationType.physical;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  bool _requirePassword = false;

  List<UserModel> _selectedParticipants = [];
  List<UserModel> _availableParticipants = [];
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String? _selectedTeamId;
  String? _selectedTeamName;
  List<DepartmentModel> _availableDepartments = [];
  bool _isLoadingParticipants = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final orgProvider =
        Provider.of<OrganizationProvider>(context, listen: false);
    await orgProvider.loadDepartments();
    setState(() {
      _availableDepartments = orgProvider.availableDepartments;
    });
  }

  void _onTypeChanged(MeetingType type) {
    setState(() {
      _selectedType = type;
      if (type != MeetingType.department) {
        _selectedDepartmentId = null;
        _selectedDepartmentName = null;
        _selectedParticipants = [];
      }
    });
  }

  void _onDepartmentChanged(String? departmentId) {
    setState(() {
      _selectedDepartmentId = departmentId;
      final dept = _availableDepartments.firstWhere(
        (d) => d.id == departmentId,
        orElse: () => DepartmentModel(
          id: departmentId ?? '',
          name: 'Phòng ban',
          description: '',
          memberIds: [],
          teamIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _selectedDepartmentName = dept.name;
    });
  }

  void _onParticipantsChanged(List<UserModel> participants) {
    setState(() {
      _selectedParticipants = participants;
    });
  }

  void _onPriorityChanged(MeetingPriority priority) {
    setState(() {
      _selectedPriority = priority;
    });
  }

  void _onLocationTypeChanged(MeetingLocationType type) {
    setState(() {
      _selectedLocationType = type;
    });
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _onStartTimeChanged(TimeOfDay time) {
    setState(() {
      _selectedStartTime = time;
    });
  }

  void _onEndTimeChanged(TimeOfDay time) {
    setState(() {
      _selectedEndTime = time;
    });
  }

  void _onRequirePasswordChanged(bool value) {
    setState(() {
      _requirePassword = value;
    });
  }

  void _createMeeting() async {
    if (_formKey.currentState?.validate() != true) return;
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người dùng!')),
      );
      return;
    }
    // Tạo participants list
    final participants = _selectedParticipants
        .map((user) => MeetingParticipant(
              userId: user.id,
              userName: user.displayName,
              userEmail: user.email,
              role: 'participant',
              isRequired: true,
              hasConfirmed: false,
            ))
        .toList();
    // Tạo MeetingModel
    final now = DateTime.now();
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedStartTime.hour,
      _selectedStartTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );
    final meeting = MeetingModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      status: MeetingStatus.pending,
      locationType: _selectedLocationType,
      priority: _selectedPriority,
      startTime: startDateTime,
      endTime: endDateTime,
      durationMinutes: endDateTime.difference(startDateTime).inMinutes,
      physicalLocation: _selectedLocationType == MeetingLocationType.physical
          ? _locationController.text.trim()
          : null,
      virtualMeetingLink: _selectedLocationType == MeetingLocationType.virtual
          ? _virtualLinkController.text.trim()
          : null,
      virtualMeetingPassword:
          _requirePassword ? _virtualPasswordController.text.trim() : null,
      creatorId: currentUser.id,
      creatorName: currentUser.displayName,
      participants: participants,
      createdAt: now,
      updatedAt: now,
      departmentId: _selectedDepartmentId,
      departmentName: _selectedDepartmentName,
      tags: [],
      isRecurring: false,
      scope: MeetingScope.company,
      approvalStatus: MeetingApprovalStatus.pending,
      attachments: [],
      actionItems: [],
      allowJoinBeforeHost: true,
      muteOnEntry: false,
      recordMeeting: false,
      requirePassword: _requirePassword,
    );
    final result = await meetingProvider.createMeeting(
        meeting, currentUser, notificationProvider);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo cuộc họp thành công!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(meetingProvider.error ?? 'Tạo cuộc họp thất bại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDepartments =
        Provider.of<OrganizationProvider>(context).availableDepartments;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        title: const Text('Tạo cuộc họp mới'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _createMeeting,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7BE9),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tạo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MeetingBasicForm(
          formKey: _formKey,
          titleController: _titleController,
          descriptionController: _descriptionController,
          locationController: _locationController,
          virtualLinkController: _virtualLinkController,
          virtualPasswordController: _virtualPasswordController,
          selectedType: _selectedType,
          selectedPriority: _selectedPriority,
          selectedLocationType: _selectedLocationType,
          selectedDate: _selectedDate,
          selectedStartTime: _selectedStartTime,
          selectedEndTime: _selectedEndTime,
          requirePassword: _requirePassword,
          selectedParticipants: _selectedParticipants,
          availableParticipants: _availableParticipants,
          selectedDepartmentName: _selectedDepartmentName,
          selectedTeamName: _selectedTeamName,
          selectedDepartmentId: _selectedDepartmentId,
          selectedTeamId: _selectedTeamId,
          availableDepartments: availableDepartments,
          isLoadingParticipants: _isLoadingParticipants,
          onTypeChanged: _onTypeChanged,
          onPriorityChanged: _onPriorityChanged,
          onLocationTypeChanged: _onLocationTypeChanged,
          onDateChanged: _onDateChanged,
          onStartTimeChanged: _onStartTimeChanged,
          onEndTimeChanged: _onEndTimeChanged,
          onRequirePasswordChanged: _onRequirePasswordChanged,
          onParticipantsChanged: _onParticipantsChanged,
          onDepartmentChanged: _onDepartmentChanged,
          onTeamChanged: (String? teamId) {},
        ),
      ),
    );
  }
}
