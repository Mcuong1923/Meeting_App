import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../models/user_role.dart';
import '../providers/meeting_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

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
  bool _isPublic = false;
  // bool _isAdvancedExpanded = false; // Removed as ExpansionTile handles it

  List<UserModel> _selectedParticipants = [];
  UserModel? _selectedSecretary;

  // Mock room data for suggestions
  final List<Map<String, dynamic>> _mockRooms = [
    {
      'id': 'A2-301',
      'name': 'A2-301',
      'capacity': 25,
      'equipment': 'Tòa nhà chính',
      'floor': 'Tầng A2',
      'address': '123 Đường ABC, Quận XYZ',
      'isAvailable': true,
    },
    {
      'id': 'A2-302',
      'name': 'A2-302',
      'capacity': 23,
      'equipment': 'Tòa nhà chính',
      'floor': 'Tầng A2',
      'address': '123 Đường ABC, Quận XYZ',
      'isAvailable': true,
    },
    {
      'id': 'A2-303',
      'name': 'A2-303',
      'capacity': 13,
      'equipment': 'Tòa nhà chính',
      'floor': 'Tầng A2',
      'address': '123 Đường ABC, Quận XYZ',
      'isAvailable': true,
    },
    {
      'id': 'B1-101',
      'name': 'B1-101',
      'capacity': 28,
      'equipment': 'Tòa nhà chính',
      'floor': 'Tầng B1',
      'address': '123 Đường ABC, Quận XYZ',
      'isAvailable': true,
    },
    { 
      'id': 'B1-102',
      'name': 'B1-102',
      'capacity': 20,
      'equipment': 'Tòa nhà chính',
      'floor': 'Tầng B1',
      'address': '123 Đường ABC, Quận XYZ',
      'isAvailable': true,
    },
  ];

  bool _isCreating = false;

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

  bool get _canCreate {
    return _titleController.text.trim().isNotEmpty &&
           _selectedParticipants.isNotEmpty;
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
          const SnackBar(content: Text('Vui lòng chọn ít nhất một người tham gia')),
        );
      }
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
        return MeetingParticipant(
          userId: u.id,
          userName: u.displayName,
          userEmail: u.email,
          role: role,
          isRequired: true,
          hasConfirmed: true, // Auto-confirm: mời là join luôn
          confirmedAt: DateTime.now(),
        );
      }).toList();

      if (!participants.any((p) => p.userId == currentUser.id)) {
        participants.insert(0, MeetingParticipant(
          userId: currentUser.id,
          userName: currentUser.displayName,
          userEmail: currentUser.email,
          role: 'chair',
          isRequired: true,
          hasConfirmed: true,
        ));
      }

      final startDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 
        _startTime.hour, _startTime.minute
      );
      
      final endDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 
        _endTime.hour, _endTime.minute
      );

      final meeting = MeetingModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: MeetingType.team,
        status: MeetingStatus.pending,
        locationType: _locationType,
        priority: _priority,
        startTime: startDateTime,
        endTime: endDateTime,
        durationMinutes: endDateTime.difference(startDateTime).inMinutes,
        physicalLocation: _locationType == MeetingLocationType.physical 
            ? _locationController.text.trim() : null,
        virtualMeetingLink: _locationType == MeetingLocationType.virtual
            ? _virtualLinkController.text.trim() : null,
        creatorId: currentUser.id,
        creatorName: currentUser.displayName,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRecurring: false,
        scope: _isPublic ? MeetingScope.company : MeetingScope.team,
        approvalStatus: MeetingApprovalStatus.pending,
      );

      final result = await meetingProvider.createMeeting(
          meeting, currentUser, notificationProvider);

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo cuộc họp thành công!')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Dark teal header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2C5F6F),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ),
                          const Text(
                            'Meeting',
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Save',
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
                          hintText: 'Add title',
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Date',
                      _formatDateFull(_selectedDate),
                      onTap: _showDateTimePicker,
                    ),
                    const SizedBox(height: 20),
                    
                    // Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.access_time,
                            'Start',
                            _formatTime(_startTime),
                            onTap: () => _showTimePicker(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                            Icons.access_time,
                            'End',
                            _formatTime(_endTime),
                            onTap: () => _showTimePicker(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    _buildDescriptionField(),
                    const SizedBox(height: 20),
                    
                    // Location
                    _buildLocationField(),
                    const SizedBox(height: 20),
                    
                    // Participants
                    _buildParticipantsSection(),
                    const SizedBox(height: 20),
                    
                    // Secretary (optional)
                    _buildSecretarySection(),
                    const SizedBox(height: 20),
                    
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

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2C5F6F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 20, color: Color(0xFF2C5F6F)),
            const SizedBox(width: 12),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Add description...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(left: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _locationType == MeetingLocationType.physical 
                ? Icons.location_on_outlined 
                : _locationType == MeetingLocationType.virtual
                  ? Icons.videocam_outlined
                  : Icons.hub_outlined,
              size: 20,
              color: const Color(0xFF2C5F6F),
            ),
            const SizedBox(width: 12),
            Text(
              _locationType == MeetingLocationType.physical 
                ? 'Location' 
                : _locationType == MeetingLocationType.virtual
                  ? 'Meeting URL'
                  : 'Hybrid Meeting',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            // Toggle buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLocationTypeButton(
                    Icons.location_on,
                    MeetingLocationType.physical,
                  ),
                  _buildLocationTypeButton(
                    Icons.videocam,
                    MeetingLocationType.virtual,
                  ),
                  _buildLocationTypeButton(
                    Icons.hub,
                    MeetingLocationType.hybrid,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Physical location field
        if (_locationType == MeetingLocationType.physical || _locationType == MeetingLocationType.hybrid)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter room or address...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(left: 32),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.location_on, color: Color(0xFF2C5F6F)),
                onPressed: _showRoomSuggestions,
                tooltip: 'Suggest rooms',
              ),
            ],
          ),
        
        // Virtual link field
        if (_locationType == MeetingLocationType.virtual || _locationType == MeetingLocationType.hybrid)
          Padding(
            padding: EdgeInsets.only(top: _locationType == MeetingLocationType.hybrid ? 8 : 0),
            child: TextField(
              controller: _virtualLinkController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Paste Zoom/Meet/Teams link...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(left: 32),
                prefixIcon: const Icon(Icons.link, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationTypeButton(IconData icon, MeetingLocationType type) {
    final isSelected = _locationType == type;
    return InkWell(
      onTap: () => setState(() => _locationType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C5F6F) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey[600],
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _showParticipantSelector,
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFF2C5F6F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Creator
        _buildParticipantTile(
          currentUser?.displayName ?? 'You',
          'Creator',
          currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'Y',
          isCreator: true,
        ),
        
        // Selected participants
        if (_selectedParticipants.isNotEmpty)
          ...(_selectedParticipants.take(3).map((user) => _buildParticipantTile(
            user.displayName,
            user.email,
            user.displayName.substring(0, 1).toUpperCase(),
          ))),
        
        // Show more indicator
        if (_selectedParticipants.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Text(
              '+${_selectedParticipants.length - 3} more',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantTile(String name, String subtitle, String initial, {bool isCreator = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isCreator ? const Color(0xFF2C5F6F) : Colors.grey[300],
            child: Text(
              initial,
              style: TextStyle(
                color: isCreator ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretarySection() {
    return InkWell(
      onTap: _showSecretarySelector,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.assignment_ind_outlined, size: 20, color: Color(0xFF2C5F6F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secretary',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedSecretary?.displayName ?? 'Optional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedSecretary != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedSecretary != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedSecretary = null),
                color: Colors.grey[400],
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return InkWell(
      onTap: _showPrioritySelector,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, size: 20, color: Color(0xFF2C5F6F)),
            const SizedBox(width: 12),
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Text(
              _getPriorityText(_priority),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _getPriorityColor(_priority),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  String _getPriorityText(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.low:
        return 'Low';
      case MeetingPriority.medium:
        return 'Medium';
      case MeetingPriority.high:
        return 'High';
      case MeetingPriority.urgent:
        return 'Urgent';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Select Priority',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D1E),
                ),
              ),
              const SizedBox(height: 24),
              // Options
              _buildPriorityOption(MeetingPriority.low, 'Low', Colors.green),
              _buildPriorityOption(MeetingPriority.medium, 'Medium', Colors.orange),
              _buildPriorityOption(MeetingPriority.high, 'High', Colors.deepOrange),
              _buildPriorityOption(MeetingPriority.urgent, 'Urgent', Colors.red),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityOption(MeetingPriority priority, String label, Color color) {
    final isSelected = _priority == priority;
    return InkWell(
      onTap: () {
        setState(() => _priority = priority);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              Icons.flag_rounded,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
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
  Widget _buildInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Thông tin cuộc họp', Icons.edit_note_rounded, Colors.blue),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
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

  // 2. Time Card
  Widget _buildTimeCard() {
    final startDt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, 
      _startTime.hour, _startTime.minute
    );
    final endDt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, 
      _endTime.hour, _endTime.minute
    );
    final duration = endDt.difference(startDt).inMinutes;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Thời gian', Icons.access_time_filled_rounded, Colors.orange),
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
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_selectedDate),
                              style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          _buildSectionHeader('Địa điểm', Icons.location_on_rounded, Colors.pink),
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
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onChanged: (val) => setState(() => _locationType = val!),
                items: [
                  DropdownMenuItem(
                    value: MeetingLocationType.physical,
                    child: Row(
                      children: [
                        Icon(Icons.business_rounded, size: 20, color: Colors.pink[400]),
                        const SizedBox(width: 12),
                        const Text('Trực tiếp tại văn phòng', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: MeetingLocationType.virtual,
                    child: Row(
                      children: [
                        Icon(Icons.videocam_rounded, size: 20, color: Colors.pink[400]),
                        const SizedBox(width: 12),
                        const Text('Họp Online (Virtual)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                        prefixIcon: Icon(Icons.meeting_room_rounded, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        prefixIcon: Icon(Icons.link_rounded, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
           _buildSectionHeader('Người tham gia', Icons.people_alt_rounded, Colors.teal),
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
                    currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'M',
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'Tôi',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Text('Chủ trì cuộc họp', style: TextStyle(fontSize: 12, color: Colors.teal)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Host', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
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
                     width: 40, height: 40,
                     decoration: BoxDecoration(
                       color: const Color(0xFFF0F2F5),
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.white, width: 2),
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                     ),
                     child: const Icon(Icons.add, color: Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thêm người tham gia', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        if (_selectedParticipants.isEmpty)
                          const Text('Chưa chọn ai', style: TextStyle(color: Colors.grey, fontSize: 13))
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
                const Icon(Icons.assignment_ind_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thư ký cuộc họp', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      if (_selectedSecretary != null)
                        Text(_selectedSecretary!.displayName, style: const TextStyle(fontSize: 13, color: Colors.teal))
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
                   const Text('Tuỳ chọn', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantChips() {
    final count = _selectedParticipants.length;
    final names = _selectedParticipants.take(2).map((u) => u.displayName.split(' ').last).join(', ');
    final remaining = count - 2;

    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        children: [
          TextSpan(text: '$names', style: const TextStyle(fontWeight: FontWeight.w500)),
          if (remaining > 0)
            TextSpan(text: ' và $remaining người khác', style: const TextStyle(color: Colors.grey)),
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
              Text('Cấu hình nâng cao', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
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
                      const Text('Mức độ ưu tiên', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        _priority == MeetingPriority.urgent ? 'Quan trọng & Khẩn cấp' 
                        : _priority == MeetingPriority.high ? 'Cao' 
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
                        DropdownMenuItem(value: MeetingPriority.low, child: Text('Thấp')),
                        DropdownMenuItem(value: MeetingPriority.medium, child: Text('Trung bình')),
                        DropdownMenuItem(value: MeetingPriority.high, child: Text('Cao')),
                        DropdownMenuItem(value: MeetingPriority.urgent, child: Text('Khẩn cấp', style: TextStyle(color: Colors.red))),
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
              title: const Text('Công khai danh sách', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Mọi người có thể thấy ai tham gia', style: TextStyle(fontSize: 13)),
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
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C5F6F)),
            dialogBackgroundColor: Colors.white,
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
        final startDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour, time.minute);
        final endDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
        if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
          _endTime = TimeOfDay.fromDateTime(startDt.add(const Duration(hours: 1)));
        }
      } else {
        _endTime = time;
      }
    });
  }

  String _formatDateFull(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${DateFormat('dd MMM yyyy').format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow, ${DateFormat('dd MMM yyyy').format(date)}';
    }
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  String _formatDate(DateTime date) {
    if (date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day) {
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
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Color(0xFF2C5F6F), size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
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
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: departments.length,
                            itemBuilder: (context, index) {
                              final dept = departments[index];
                              final isExpanded = expandedDepartments.contains(dept.id);
                              final users = departmentUsersMap[dept.id] ?? [];
                              final memberCount = dept.memberIds.length;
                              
                              // Calculate selection state
                              int selectedCount = 0;
                              for (var user in users) {
                                if (_selectedParticipants.any((p) => p.id == user.id)) {
                                  selectedCount++;
                                }
                              }
                              
                              bool isDeptFullySelected = users.isNotEmpty && selectedCount == users.length;
                              
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
                                      if (!departmentUsersMap.containsKey(dept.id)) {
                                        await orgProvider.loadDepartmentUsers(dept.id);
                                        setStateDialog(() {
                                          departmentUsersMap[dept.id] = List.from(orgProvider.departmentUsers);
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
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
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dept.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
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
                                                color: isDeptFullySelected ? const Color(0xFF2C5F6F) : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                              color: isDeptFullySelected ? const Color(0xFF2C5F6F) : Colors.transparent,
                                            ),
                                            child: isDeptFullySelected
                                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                                              : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // User list (when expanded)
                                  if (isExpanded)
                                    ...users.map((user) {
                                      final isSelected = _selectedParticipants.any((p) => p.id == user.id);
                                      return InkWell(
                                        onTap: () {
                                          setStateDialog(() {
                                            if (isSelected) {
                                              _selectedParticipants.removeWhere((p) => p.id == user.id);
                                            } else {
                                              _selectedParticipants.add(user);
                                            }
                                          });
                                          this.setState(() {});
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(left: 44, bottom: 8),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: Colors.grey[200],
                                                child: Text(
                                                  user.displayName.isNotEmpty 
                                                    ? user.displayName.substring(0, 1).toUpperCase()
                                                    : '?',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w600,
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
                                                      user.displayName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      user.email,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFFF9800),
                                                    shape: BoxShape.circle,
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
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey[300]!, width: 2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  
                                  if (index < departments.length - 1)
                                    Divider(height: 1, color: Colors.grey[200]),
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
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5F6F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_ind_rounded, color: Color(0xFF2C5F6F), size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
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
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: departments.length,
                            itemBuilder: (context, index) {
                              final dept = departments[index];
                              final isExpanded = expandedDepartments.contains(dept.id);
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
                                      if (!departmentUsersMap.containsKey(dept.id)) {
                                        await orgProvider.loadDepartmentUsers(dept.id);
                                        setStateDialog(() {
                                          departmentUsersMap[dept.id] = List.from(orgProvider.departmentUsers);
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
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
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dept.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
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
                                    ...users.map((user) {
                                      final isSelected = _selectedSecretary?.id == user.id;
                                      return InkWell(
                                        onTap: () {
                                          setState(() => _selectedSecretary = user);
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(left: 44, bottom: 8),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: Colors.grey[200],
                                                child: Text(
                                                  user.displayName.isNotEmpty 
                                                    ? user.displayName.substring(0, 1).toUpperCase()
                                                    : '?',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w600,
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
                                                      user.displayName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      user.email,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFFF9800),
                                                    shape: BoxShape.circle,
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
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey[300]!, width: 2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  
                                  if (index < departments.length - 1)
                                    Divider(height: 1, color: Colors.grey[200]),
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
                              style: TextStyle(color: Colors.grey, fontSize: 16),
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

  void _showRoomSuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                      const Icon(Icons.meeting_room, color: Color(0xFF2C5F6F), size: 24),
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
                
                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.category, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Text('Trực tiếp', style: TextStyle(fontSize: 14)),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Text('Trung bình', style: TextStyle(fontSize: 14)),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Room list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _mockRooms.length,
                    itemBuilder: (context, index) {
                      final room = _mockRooms[index];
                      return _buildRoomItem(room);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoomItem(Map<String, dynamic> room) {
    return InkWell(
      onTap: () {
        setState(() {
          _locationController.text = '${room['name']} - ${room['floor']} - ${room['address']}';
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF2C5F6F), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room['capacity']} người • ${room['equipment']} • ${room['floor']} - ${room['address']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Khả dụng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

