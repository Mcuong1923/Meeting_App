import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/organization_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/participant_suggestion_service.dart';

class MeetingFormController extends ChangeNotifier {
  // Form controllers
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final agendaController = TextEditingController();
  final locationController = TextEditingController();
  final virtualLinkController = TextEditingController();
  final virtualPasswordController = TextEditingController();
  final notesController = TextEditingController();

  // Form state
  MeetingType _selectedType = MeetingType.personal;
  MeetingScope _selectedScope = MeetingScope.personal;
  MeetingLocationType _selectedLocationType = MeetingLocationType.physical;
  MeetingPriority _selectedPriority = MeetingPriority.medium;
  String? _selectedDepartmentId;
  String? _selectedTeamId;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );

  bool _isRecurring = false;
  String? _recurringPattern;
  DateTime? _recurringEndDate;

  bool _allowJoinBeforeHost = true;
  bool _muteOnEntry = false;
  bool _recordMeeting = false;
  bool _requirePassword = false;

  List<MeetingParticipant> _participants = [];
  List<String> _actionItems = [];
  List<PlatformFile> _attachments = [];

  // Participant management
  List<UserModel> _availableParticipants = [];
  List<UserModel> _selectedParticipants = [];
  List<UserModel> _suggestedParticipants = [];
  bool _isLoadingParticipants = false;
  bool _showParticipantSelection = false;

  // Services
  OrganizationProvider? _organizationProvider;
  ParticipantSuggestionService? _participantService;

  // Getters
  MeetingType get selectedType => _selectedType;
  MeetingScope get selectedScope => _selectedScope;
  MeetingLocationType get selectedLocationType => _selectedLocationType;
  MeetingPriority get selectedPriority => _selectedPriority;
  String? get selectedDepartmentId => _selectedDepartmentId;
  String? get selectedTeamId => _selectedTeamId;
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedStartTime => _selectedStartTime;
  TimeOfDay get selectedEndTime => _selectedEndTime;
  bool get isRecurring => _isRecurring;
  String? get recurringPattern => _recurringPattern;
  DateTime? get recurringEndDate => _recurringEndDate;
  bool get allowJoinBeforeHost => _allowJoinBeforeHost;
  bool get muteOnEntry => _muteOnEntry;
  bool get recordMeeting => _recordMeeting;
  bool get requirePassword => _requirePassword;
  List<MeetingParticipant> get participants => _participants;
  List<String> get actionItems => _actionItems;
  List<PlatformFile> get attachments => _attachments;
  List<UserModel> get availableParticipants => _availableParticipants;
  List<UserModel> get selectedParticipants => _selectedParticipants;
  List<UserModel> get suggestedParticipants => _suggestedParticipants;
  bool get isLoadingParticipants => _isLoadingParticipants;
  bool get showParticipantSelection => _showParticipantSelection;

  void initializeServices(BuildContext context) {
    _organizationProvider =
        Provider.of<OrganizationProvider>(context, listen: false);
    _participantService = ParticipantSuggestionService(_organizationProvider!);
  }

  Future<void> preloadDepartments() async {
    if (_organizationProvider == null) return;

    try {
      print('🔄 Preloading departments...');
      await _organizationProvider!.loadDepartments();
      print(
          '✅ Departments loaded: ${_organizationProvider!.availableDepartments.length}');
      notifyListeners();
    } catch (e) {
      print('❌ Error preloading departments: $e');
    }
  }

  void loadCurrentUser(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final allowedTypes = authProvider.userModel!.getAllowedMeetingTypes();
        if (allowedTypes.isNotEmpty) {
          _selectedType = allowedTypes.first;
          switch (_selectedType) {
            case MeetingType.personal:
              _selectedScope = MeetingScope.personal;
              break;
            case MeetingType.team:
              _selectedScope = MeetingScope.team;
              break;
            case MeetingType.department:
              _selectedScope = MeetingScope.department;
              break;
            case MeetingType.company:
              _selectedScope = MeetingScope.company;
              break;
          }
          notifyListeners();
          loadParticipantSuggestions(context);
        }
      }
    } catch (e) {
      print('Error in loadCurrentUser: $e');
    }
  }

  Future<void> loadParticipantSuggestions(BuildContext context) async {
    if (_participantService == null) return;

    _isLoadingParticipants = true;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.userModel;

      if (currentUser != null) {
        print(
            '🔄 Loading suggestions for ${_selectedType.toString()} - Dept: $_selectedDepartmentId, Team: $_selectedTeamId');

        _suggestedParticipants =
            await _participantService!.getSuggestedParticipants(
          meetingType: _selectedType,
          selectedDepartmentId: _selectedDepartmentId,
          selectedTeamId: _selectedTeamId,
          currentUserId: currentUser.id,
        );

        _availableParticipants = _suggestedParticipants;
        print(
            '✅ Loaded ${_suggestedParticipants.length} participants for selection');

        // For department and team meetings, auto-select all participants
        if (_selectedType == MeetingType.department ||
            _selectedType == MeetingType.team) {
          _selectedParticipants = List.from(_suggestedParticipants);
          _updateParticipantsList();
          print(
              '🔄 Auto-selected ${_selectedParticipants.length} participants');
        }
      }
    } catch (e) {
      print('❌ Error loading participant suggestions: $e');
    } finally {
      _isLoadingParticipants = false;
      notifyListeners();
    }
  }

  void _updateParticipantsList() {
    if (_participantService != null) {
      _participants = _participantService!
          .convertToMeetingParticipants(_selectedParticipants);
    }
  }

  // Setters
  void setSelectedType(MeetingType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSelectedPriority(MeetingPriority priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setSelectedLocationType(MeetingLocationType type) {
    _selectedLocationType = type;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedStartTime(TimeOfDay time) {
    _selectedStartTime = time;
    notifyListeners();
  }

  void setSelectedEndTime(TimeOfDay time) {
    _selectedEndTime = time;
    notifyListeners();
  }

  void setIsRecurring(bool value) {
    _isRecurring = value;
    notifyListeners();
  }

  void setRecurringPattern(String? pattern) {
    _recurringPattern = pattern;
    notifyListeners();
  }

  void setRecurringEndDate(DateTime? date) {
    _recurringEndDate = date;
    notifyListeners();
  }

  void setAllowJoinBeforeHost(bool value) {
    _allowJoinBeforeHost = value;
    notifyListeners();
  }

  void setMuteOnEntry(bool value) {
    _muteOnEntry = value;
    notifyListeners();
  }

  void setRecordMeeting(bool value) {
    _recordMeeting = value;
    notifyListeners();
  }

  void setRequirePassword(bool value) {
    _requirePassword = value;
    notifyListeners();
  }

  void setActionItems(List<String> items) {
    _actionItems = items;
    notifyListeners();
  }

  void setSelectedDepartmentId(String? id) {
    _selectedDepartmentId = id;
    notifyListeners();
  }

  void setSelectedTeamId(String? id) {
    _selectedTeamId = id;
    notifyListeners();
  }

  void setSelectedParticipants(List<UserModel> participants) {
    _selectedParticipants = participants;
    _updateParticipantsList();
    notifyListeners();
  }

  void setShowParticipantSelection(bool value) {
    _showParticipantSelection = value;
    notifyListeners();
  }

  Future<bool> createMeeting(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final meetingProvider =
          Provider.of<MeetingProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final currentUser = authProvider.userModel;

      if (currentUser == null) {
        return false;
      }

      // Check if approval is needed
      bool needsApproval = currentUser.needsApproval(_selectedType);

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
      final durationMinutes = endDateTime.difference(startDateTime).inMinutes;

      final meeting = MeetingModel(
        id: '',
        title: titleController.text,
        description: descriptionController.text,
        type: _selectedType,
        status: needsApproval ? MeetingStatus.pending : MeetingStatus.approved,
        locationType: _selectedLocationType,
        priority: _selectedPriority,
        startTime: startDateTime,
        endTime: endDateTime,
        durationMinutes: durationMinutes,
        physicalLocation:
            locationController.text.isNotEmpty ? locationController.text : null,
        virtualMeetingLink: virtualLinkController.text.isNotEmpty
            ? virtualLinkController.text
            : null,
        virtualMeetingPassword: virtualPasswordController.text.isNotEmpty
            ? virtualPasswordController.text
            : null,
        creatorId: currentUser.id,
        creatorName: currentUser.displayName,
        participants: _participants,
        agenda: agendaController.text.isNotEmpty ? agendaController.text : null,
        meetingNotes:
            notesController.text.isNotEmpty ? notesController.text : null,
        actionItems: _actionItems,
        attachments: const [],
        scope: _selectedScope,
        approvalStatus: needsApproval
            ? MeetingApprovalStatus.pending
            : MeetingApprovalStatus.auto_approved,
        targetDepartmentId: _selectedDepartmentId,
        targetTeamId: _selectedTeamId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        departmentId: currentUser.departmentId,
        departmentName: currentUser.departmentName,
        isRecurring: _isRecurring,
        recurringPattern: _recurringPattern,
        recurringEndDate: _recurringEndDate,
        allowJoinBeforeHost: _allowJoinBeforeHost,
        muteOnEntry: _muteOnEntry,
        recordMeeting: _recordMeeting,
        requirePassword: _requirePassword,
      );

      final result = await meetingProvider.createMeeting(
          meeting, currentUser, notificationProvider);
      return result != null;
    } catch (e) {
      print('❌ Error creating meeting: $e');
      return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    agendaController.dispose();
    locationController.dispose();
    virtualLinkController.dispose();
    virtualPasswordController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
 