import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../models/user_role.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../components/datetime_picker_card.dart';

class MeetingBasicForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController virtualLinkController;
  final TextEditingController virtualPasswordController;
  final MeetingType selectedType;
  final MeetingPriority selectedPriority;
  final MeetingLocationType selectedLocationType;
  final DateTime selectedDate;
  final TimeOfDay selectedStartTime;
  final TimeOfDay selectedEndTime;
  final bool requirePassword;
  final List<UserModel> selectedParticipants;
  final List<UserModel> availableParticipants;
  final String? selectedDepartmentName;
  final String? selectedTeamName;
  final String? selectedDepartmentId;
  final String? selectedTeamId;
  final List<DepartmentModel> availableDepartments;
  final bool isLoadingParticipants;
  final ValueChanged<MeetingType> onTypeChanged;
  final ValueChanged<MeetingPriority> onPriorityChanged;
  final ValueChanged<MeetingLocationType> onLocationTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final ValueChanged<bool> onRequirePasswordChanged;
  final ValueChanged<List<UserModel>> onParticipantsChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<List<MeetingParticipant>>? onParticipantsWithRolesChanged;

  const MeetingBasicForm({
    Key? key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.virtualLinkController,
    required this.virtualPasswordController,
    required this.selectedType,
    required this.selectedPriority,
    required this.selectedLocationType,
    required this.selectedDate,
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.requirePassword,
    required this.selectedParticipants,
    required this.availableParticipants,
    this.selectedDepartmentName,
    this.selectedTeamName,
    this.selectedDepartmentId,
    this.selectedTeamId,
    this.availableDepartments = const <DepartmentModel>[],
    this.isLoadingParticipants = false,
    required this.onTypeChanged,
    required this.onPriorityChanged,
    required this.onLocationTypeChanged,
    required this.onDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onRequirePasswordChanged,
    required this.onParticipantsChanged,
    required this.onDepartmentChanged,
    required this.onTeamChanged,
    this.onParticipantsWithRolesChanged,
  }) : super(key: key);

  Widget _buildMeetingTypeButton(BuildContext context) {
    final color = _getMeetingTypeColor(selectedType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMeetingTypeSelectionDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMeetingTypeIcon(selectedType),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại cuộc họp',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getMeetingTypeLabel(selectedType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMeetingTypeColor(MeetingType type) {
    switch (type) {
      case MeetingType.personal:
        return Colors.blue;
      case MeetingType.team:
        return Colors.green;
      case MeetingType.department:
        return Colors.orange;
      case MeetingType.company:
        return Colors.purple;
    }
  }

  IconData _getMeetingTypeIcon(MeetingType type) {
    switch (type) {
      case MeetingType.personal:
        return Icons.person;
      case MeetingType.team:
        return Icons.group;
      case MeetingType.department:
        return Icons.business;
      case MeetingType.company:
        return Icons.domain;
    }
  }

  void _showMeetingTypeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn loại cuộc họp',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lựa chọn loại cuộc họp và thiết lập',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Meeting Types
                      ...MeetingType.values.map((type) {
                        final isSelected = selectedType == type;
                        final color = _getMeetingTypeColor(type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (type == MeetingType.department) {
                                  // ✅ Fix: Cập nhật meeting type trước khi mở dialog phòng ban
                                  onTypeChanged(MeetingType.department);
                                  Navigator.of(context).pop();
                                  _showDepartmentSelectionDialog(context);
                                } else {
                                  onTypeChanged(type);
                                  Navigator.of(context).pop();
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isSelected ? color : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected
                                      ? color.withOpacity(0.1)
                                      : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getMeetingTypeIcon(type),
                                        color: color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _getMeetingTypeLabel(type),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      Icon(
                                        Icons.check_circle,
                                        color: color,
                                        size: 24,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepartmentSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn phòng ban',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Chọn phòng ban để mời người tham gia',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Department List
              Flexible(
                child: availableDepartments.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_center_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Không có phòng ban nào',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: availableDepartments.length,
                        itemBuilder: (context, index) {
                          final department = availableDepartments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // ✅ Fix: Store context before navigation and show dialog immediately
                                  final dialogContext = context;
                                  onDepartmentChanged(department.id);
                                  Navigator.of(context).pop();

                                  // ✅ Show dialog immediately without delay to avoid context issues
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _showParticipantRoleDialog(
                                        dialogContext, department);
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.group,
                                          color: Colors.orange[700]),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              department.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (department
                                                .description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                department.description,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600]),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${department.memberIds.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParticipantRoleDialog(
      BuildContext context, DepartmentModel department) {
    try {
      // Debug: Print information for troubleshooting
      print('🔍 DEBUG: _showParticipantRoleDialog called!');
      print('🔍 DEBUG: Context is mounted: ${context.mounted}');
      print(
          '🔍 DEBUG: Department selected: ${department.name} (ID: ${department.id})');
      print(
          '🔍 DEBUG: Available participants count: ${availableParticipants.length}');
      print(
          '🔍 DEBUG: Available participants: ${availableParticipants.map((u) => '${u.displayName} (deptId: ${u.departmentId})').join(', ')}');

      // ✅ Khôi phục: Show participant selection dialog directly
      _showActualParticipantDialog(context, department);
    } catch (e, stackTrace) {
      print('❌ ERROR in _showParticipantRoleDialog: $e');
      print('❌ Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi mở dialog: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showActualParticipantDialog(
      BuildContext context, DepartmentModel department) {
    try {
      // Filter available participants by department - try multiple matching methods
      var departmentUsers = availableParticipants
          .where((user) => user.departmentId == department.id)
          .toList();

      print(
          '🔍 DEBUG: Department users after ID filter: ${departmentUsers.length}');

      // ✅ Fallback: If ID matching fails, try matching by department name
      if (departmentUsers.isEmpty) {
        departmentUsers = availableParticipants
            .where((user) =>
                user.departmentId?.toString().toLowerCase() ==
                department.name.toLowerCase())
            .toList();
        print(
            '🔍 DEBUG: Department users after name filter: ${departmentUsers.length}');
      }

      // ✅ Another fallback: Try partial matching
      if (departmentUsers.isEmpty) {
        departmentUsers = availableParticipants
            .where((user) =>
                user.departmentId?.toString().contains(department.id) == true ||
                department.id.contains(user.departmentId?.toString() ?? ''))
            .toList();
        print(
            '🔍 DEBUG: Department users after partial filter: ${departmentUsers.length}');
      }

      // ✅ **KHÔI PHỤC**: Create mock users for testing since availableParticipants is empty
      List<UserModel> mockUsers = [
        UserModel(
          id: 'user1',
          email: 'user1@company.com',
          displayName: 'Nguyễn Văn A',
          role: UserRole.employee,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: 'user2',
          email: 'user2@company.com',
          displayName: 'Trần Thị B',
          role: UserRole.employee,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: 'user3',
          email: 'user3@company.com',
          displayName: 'Lê Minh C',
          role: UserRole.manager,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: 'user4',
          email: 'user4@company.com',
          displayName: 'Phạm Thị D',
          role: UserRole.employee,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: 'user5',
          email: 'user5@company.com',
          displayName: 'Hoàng Văn E',
          role: UserRole.employee,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: 'user6',
          email: 'user6@company.com',
          displayName: 'Vũ Thị F',
          role: UserRole.employee,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: 'user7',
          email: 'user7@company.com',
          displayName: 'Đỗ Văn G',
          role: UserRole.manager,
          departmentId: department.id,
          departmentName: department.name,
          teamIds: [],
          teamNames: [],
          photoURL: null,
          lastLoginAt: DateTime.now(),
          createdAt: DateTime.now(),
          isActive: true,
        ),
      ];

      print(
          '🔍 DEBUG: Created ${mockUsers.length} mock users for department ${department.name}');

      // ✅ Fix: Use mock data if no real participants available, otherwise use filtered data
      final usersToShow = departmentUsers.isNotEmpty
          ? departmentUsers
          : (availableParticipants.isNotEmpty
              ? availableParticipants
              : mockUsers);

      print('🔍 DEBUG: Final users to show: ${usersToShow.length}');

      if (usersToShow.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Không có người dùng nào để chọn. Vui lòng kiểm tra dữ liệu.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ✅ KHÔI PHỤC: Show info about data source
      if (usersToShow == mockUsers) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Sử dụng dữ liệu test cho phòng ban ${department.name} (${usersToShow.length} người)'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // ✅ KHÔI PHỤC: Show warning if using fallback data
      if (departmentUsers.isEmpty && availableParticipants.isNotEmpty) {
        print(
            '⚠️ WARNING: Department filter failed, showing all available participants');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ Hiển thị tất cả người dùng do không tìm thấy thành viên phòng ban'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('🔍 DEBUG: About to show EnhancedParticipantDialog');

      // ✅ KHÔI PHỤC: Show enhanced participant dialog with role assignment
      showDialog(
        context: context,
        builder: (context) => EnhancedParticipantDialog(
          departmentUsers: usersToShow,
          departmentName: department.name,
          selectedParticipants: selectedParticipants,
          onParticipantsChanged: (participants) {
            print('🔍 DEBUG: Participants changed: ${participants.length}');
            print(
                '🔍 DEBUG: Selected participants: ${participants.map((u) => u.displayName).join(', ')}');

            // ✅ KHÔI PHỤC: Convert UserModel list to MeetingParticipant list with roles
            final meetingParticipants = participants.map((user) {
              return MeetingParticipant(
                userId: user.id,
                userName: user.displayName,
                userEmail: user.email,
                role:
                    'participant', // Default role - will be updated with actual roles
                isRequired: true,
                hasConfirmed: false,
              );
            }).toList();

            onParticipantsChanged(participants);
            if (onParticipantsWithRolesChanged != null) {
              onParticipantsWithRolesChanged!(meetingParticipants);
            }

            // ✅ KHÔI PHỤC: Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã chọn ${participants.length} người tham gia'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR in _showActualParticipantDialog: $e');
      print('❌ Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi hiển thị dialog chọn người: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Meeting Info Section
          _buildSection(
            context,
            title: 'Thông tin cuộc họp',
            icon: Icons.info_outline,
            color: Colors.blue,
            child: Column(
              children: [
                // Title
                _buildModernTextField(
                  controller: titleController,
                  label: 'Tiêu đề cuộc họp',
                  hint: 'Nhập tiêu đề cuộc họp',
                  icon: Icons.title,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tiêu đề cuộc họp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                _buildModernTextField(
                  controller: descriptionController,
                  label: 'Mô tả',
                  hint: 'Mô tả chi tiết về cuộc họp',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Meeting Type & Priority
                Row(
                  children: [
                    Expanded(
                      child: _buildMeetingTypeButton(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernDropdown<MeetingPriority>(
                        value: selectedPriority,
                        label: 'Mức độ ưu tiên',
                        icon: Icons.flag,
                        items: MeetingPriority.values
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(_getPriorityLabel(priority)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onPriorityChanged(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Department/Team Selection
                if (selectedType == MeetingType.department) ...[
                  _buildDepartmentDropdown(),
                  const SizedBox(height: 16),
                ] else if (selectedType == MeetingType.team) ...[
                  _buildTeamDropdown(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // DateTime Section
          _buildSection(
            context,
            title: 'Thời gian',
            icon: Icons.schedule,
            color: Colors.orange,
            child: DateTimePickerCard(
              selectedDate: selectedDate,
              selectedStartTime: selectedStartTime,
              selectedEndTime: selectedEndTime,
              onDateChanged: onDateChanged,
              onStartTimeChanged: onStartTimeChanged,
              onEndTimeChanged: onEndTimeChanged,
            ),
          ),
          const SizedBox(height: 24),

          // Location Section
          _buildSection(
            context,
            title: 'Địa điểm',
            icon: Icons.place,
            color: Colors.green,
            child: Column(
              children: [
                _buildModernDropdown<MeetingLocationType>(
                  value: selectedLocationType,
                  label: 'Loại địa điểm',
                  icon: Icons.location_on,
                  items: MeetingLocationType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getLocationTypeLabel(type)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onLocationTypeChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (selectedLocationType == MeetingLocationType.physical) ...[
                  _buildModernTextField(
                    controller: locationController,
                    label: 'Địa điểm',
                    hint: 'Nhập địa điểm cuộc họp',
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa điểm';
                      }
                      return null;
                    },
                  ),
                ] else if (selectedLocationType ==
                    MeetingLocationType.virtual) ...[
                  _buildModernTextField(
                    controller: virtualLinkController,
                    label: 'Link meeting',
                    hint: 'https://meet.google.com/xxx-xxx-xxx',
                    icon: Icons.link,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập link meeting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildModernSwitch(
                    value: requirePassword,
                    title: 'Yêu cầu mật khẩu',
                    subtitle: 'Bảo mật cuộc họp bằng mật khẩu',
                    onChanged: onRequirePasswordChanged,
                  ),
                  if (requirePassword) ...[
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: virtualPasswordController,
                      label: 'Mật khẩu meeting',
                      hint: 'Nhập mật khẩu',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (requirePassword &&
                            (value == null || value.isEmpty)) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ✅ KHÔI PHỤC: Enhanced Participant Summary Section (only show if participants selected)
          if (selectedParticipants.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'Người tham gia (${selectedParticipants.length})',
              icon: Icons.people,
              color: Colors.purple,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedDepartmentName != null) ...[
                      Row(
                        children: [
                          Icon(Icons.business,
                              color: Colors.orange[700], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Phòng ban: $selectedDepartmentName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedParticipants.take(6).map((user) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.purple.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.purple.withOpacity(0.2),
                                child: user.photoURL != null &&
                                        user.photoURL!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          user.photoURL!,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(Icons.person,
                                                color: Colors.purple[700],
                                                size: 12);
                                          },
                                        ),
                                      )
                                    : Icon(Icons.person,
                                        color: Colors.purple[700], size: 12),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.displayName.split(' ').first,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (selectedParticipants.length > 6) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${selectedParticipants.length - 6} người khác',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // ✅ KHÔI PHỤC: Action buttons for participant management
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Show participant details modal
                              showDialog(
                                context: context,
                                builder: (context) => ParticipantDetailModal(
                                  departmentName:
                                      selectedDepartmentName ?? 'Phòng ban',
                                  participants: selectedParticipants,
                                  userRoles: Map.fromEntries(
                                    selectedParticipants.map((user) =>
                                        MapEntry(user.id, 'participant')),
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.visibility, size: 16),
                            label: const Text('Xem chi tiết'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple[700],
                              side: BorderSide(color: Colors.purple[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Reopen participant selection dialog
                              if (selectedDepartmentId != null) {
                                final department =
                                    availableDepartments.firstWhere(
                                  (dept) => dept.id == selectedDepartmentId,
                                  orElse: () => DepartmentModel(
                                    id: selectedDepartmentId!,
                                    name: selectedDepartmentName ?? 'Phòng ban',
                                    description: '',
                                    memberIds: [],
                                    teamIds: [],
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                                _showParticipantRoleDialog(context, department);
                              }
                            },
                            icon: Icon(Icons.edit, size: 16),
                            label: const Text('Chỉnh sửa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModernSwitch({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _getMeetingTypeLabel(MeetingType type) {
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

  String _getPriorityLabel(MeetingPriority priority) {
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

  String _getLocationTypeLabel(MeetingLocationType type) {
    switch (type) {
      case MeetingLocationType.physical:
        return 'Trực tiếp';
      case MeetingLocationType.virtual:
        return 'Trực tuyến';
      case MeetingLocationType.hybrid:
        return 'Kết hợp';
    }
  }

  Widget _buildDepartmentDropdown() {
    if (availableDepartments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Text(
              'Đang tải danh sách phòng ban...',
              style: TextStyle(color: Colors.orange[600]),
            ),
          ],
        ),
      );
    }

    return _buildModernDropdown<String?>(
      value: selectedDepartmentId,
      label: 'Chọn phòng ban',
      icon: Icons.business,
      items: availableDepartments
          .map((dept) => DropdownMenuItem<String?>(
                value: dept.id,
                child: Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(dept.name)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${dept.memberIds?.length ?? 0}',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: onDepartmentChanged,
    );
  }

  Widget _buildTeamDropdown() {
    // This will be implemented based on current user's teams
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(
            'Chức năng chọn team đang được phát triển',
            style: TextStyle(color: Colors.green[600]),
          ),
        ],
      ),
    );
  }
}

class EnhancedParticipantDialog extends StatefulWidget {
  final List<UserModel> departmentUsers;
  final String departmentName;
  final List<UserModel> selectedParticipants;
  final ValueChanged<List<UserModel>> onParticipantsChanged;

  const EnhancedParticipantDialog({
    Key? key,
    required this.departmentUsers,
    required this.departmentName,
    required this.selectedParticipants,
    required this.onParticipantsChanged,
  }) : super(key: key);

  @override
  State<EnhancedParticipantDialog> createState() =>
      _EnhancedParticipantDialogState();
}

class _EnhancedParticipantDialogState extends State<EnhancedParticipantDialog> {
  Map<String, bool> _selectedUsers = {};
  Map<String, String> _userRoles = {}; // userId -> role
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Initialize selection state
    for (var user in widget.departmentUsers) {
      _selectedUsers[user.id] = widget.selectedParticipants.contains(user);
      _userRoles[user.id] = 'participant'; // Default role
    }
    _updateSelectAllState();
  }

  void _updateSelectAllState() {
    final selectedCount =
        _selectedUsers.values.where((selected) => selected).length;
    _selectAll = selectedCount == widget.departmentUsers.length;
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var user in widget.departmentUsers) {
        _selectedUsers[user.id] = _selectAll;
        if (_selectAll && !_userRoles.containsKey(user.id)) {
          _userRoles[user.id] = 'participant';
        }
      }
    });
  }

  void _toggleUser(UserModel user) {
    setState(() {
      _selectedUsers[user.id] = !(_selectedUsers[user.id] ?? false);
      if (_selectedUsers[user.id] == true && !_userRoles.containsKey(user.id)) {
        _userRoles[user.id] = 'participant';
      }
      _updateSelectAllState();
    });
  }

  void _changeUserRole(UserModel user, String role) {
    setState(() {
      _userRoles[user.id] = role;

      // ✅ KHÔI PHỤC: If assigning secretary role, remove it from others
      if (role == 'secretary') {
        for (var entry in _userRoles.entries) {
          if (entry.key != user.id && entry.value == 'secretary') {
            _userRoles[entry.key] = 'participant';
          }
        }
      }

      // ✅ KHÔI PHỤC: If assigning presenter role, allow multiple presenters
      // (No restrictions for presenter role)
    });
  }

  List<UserModel> _getSelectedUsers() {
    return widget.departmentUsers
        .where((user) => _selectedUsers[user.id] == true)
        .toList();
  }

  Map<String, List<UserModel>> _getUsersByRole() {
    final result = <String, List<UserModel>>{
      'presenter': <UserModel>[],
      'secretary': <UserModel>[],
      'participant': <UserModel>[],
    };

    for (var user in _getSelectedUsers()) {
      final role = _userRoles[user.id] ?? 'participant';
      result[role]?.add(user);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = _getSelectedUsers();
    final usersByRole = _getUsersByRole();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chọn người tham gia',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Phòng ban: ${widget.departmentName}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Select All Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(_selectAll
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                      label:
                          Text(_selectAll ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectAll ? Colors.orange : Colors.grey[200],
                        foregroundColor:
                            _selectAll ? Colors.white : Colors.grey[800],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Role Summary (if any users selected)
            if (selectedUsers.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tóm tắt vai trò (${selectedUsers.length} người):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRoleSummary('Trình bày',
                            usersByRole['presenter']?.length ?? 0, Colors.red),
                        const SizedBox(width: 16),
                        _buildRoleSummary('Thư ký',
                            usersByRole['secretary']?.length ?? 0, Colors.teal),
                        const SizedBox(width: 16),
                        _buildRoleSummary(
                            'Tham gia',
                            usersByRole['participant']?.length ?? 0,
                            Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Users List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.departmentUsers.length,
                itemBuilder: (context, index) {
                  final user = widget.departmentUsers[index];
                  final isSelected = _selectedUsers[user.id] ?? false;
                  final userRole = _userRoles[user.id] ?? 'participant';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? Colors.orange.withOpacity(0.05)
                          : Colors.white,
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        user.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Vai trò:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildRoleButton('presenter', 'Trình bày',
                                    Icons.slideshow, Colors.red, user),
                                const SizedBox(width: 8),
                                _buildRoleButton('secretary', 'Thư ký',
                                    Icons.edit_note, Colors.teal, user),
                                const SizedBox(width: 8),
                                _buildRoleButton('participant', 'Tham gia',
                                    Icons.person, Colors.blue, user),
                              ],
                            ),
                            // ✅ KHÔI PHỤC: Show current role indicator
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                        _userRoles[user.id] ?? 'participant')
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRoleColor(
                                          _userRoles[user.id] ?? 'participant')
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Vai trò hiện tại: ${_getRoleDisplayName(_userRoles[user.id] ?? 'participant')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getRoleColor(
                                      _userRoles[user.id] ?? 'participant'),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleUser(user);
                      },
                      activeColor: Colors.orange,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedUsers.isNotEmpty
                          ? () {
                              widget.onParticipantsChanged(selectedUsers);
                              Navigator.of(context).pop();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Lưu (${selectedUsers.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSummary(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton(
      String role, String label, IconData icon, Color color, UserModel user) {
    final isSelected = _userRoles[user.id] == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeUserRole(user, role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? color : Colors.grey[600]),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ KHÔI PHỤC: Helper methods for role management
  Color _getRoleColor(String role) {
    switch (role) {
      case 'presenter':
        return Colors.red;
      case 'secretary':
        return Colors.teal;
      case 'participant':
      default:
        return Colors.blue;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'presenter':
        return 'Trình bày';
      case 'secretary':
        return 'Thư ký';
      case 'participant':
      default:
        return 'Tham gia';
    }
  }
}

class DepartmentParticipantSummary extends StatelessWidget {
  final String departmentName;
  final List<UserModel> participants;
  final Map<String, String> userRoles;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;

  const DepartmentParticipantSummary({
    Key? key,
    required this.departmentName,
    required this.participants,
    required this.userRoles,
    required this.onViewDetails,
    required this.onEdit,
  }) : super(key: key);

  Map<String, List<UserModel>> _getUsersByRole() {
    final result = <String, List<UserModel>>{
      'presenter': <UserModel>[],
      'secretary': <UserModel>[],
      'participant': <UserModel>[],
    };

    for (var user in participants) {
      final role = userRoles[user.id] ?? 'participant';
      result[role]?.add(user);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final usersByRole = _getUsersByRole();
    final presenters = usersByRole['presenter'] ?? [];
    final secretaries = usersByRole['secretary'] ?? [];
    final participantsList = usersByRole['participant'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ban: $departmentName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      '${participants.length} người được chọn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Đã setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Role Summary
          Row(
            children: [
              if (presenters.isNotEmpty) ...[
                _buildRoleChip('Trình bày', presenters.length, Colors.red,
                    Icons.slideshow),
                const SizedBox(width: 12),
              ],
              if (secretaries.isNotEmpty) ...[
                _buildRoleChip(
                    'Thư ký', secretaries.length, Colors.teal, Icons.edit_note),
                const SizedBox(width: 12),
              ],
              _buildRoleChip('Tham gia', participantsList.length, Colors.blue,
                  Icons.person),
            ],
          ),
          const SizedBox(height: 20),

          // Participant Avatars
          Row(
            children: [
              Text(
                'Thành viên:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: participants.take(6).length +
                        (participants.length > 6 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 6) {
                        // "+X more" indicator
                        return Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '+${participants.length - 6}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      }

                      final user = participants[index];
                      final role = userRoles[user.id] ?? 'participant';
                      final roleColor = _getRoleColor(role);

                      return Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: roleColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: roleColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: roleColor.withOpacity(0.1),
                          child: user.photoURL != null &&
                                  user.photoURL!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    user.photoURL!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person,
                                          color: roleColor, size: 20);
                                    },
                                  ),
                                )
                              : Icon(Icons.person, color: roleColor, size: 20),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: Icon(Icons.visibility, size: 18),
                  label: const Text('Xem chi tiết'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, size: 18),
                  label: const Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'presenter':
        return Colors.red;
      case 'secretary':
        return Colors.teal;
      case 'participant':
      default:
        return Colors.blue;
    }
  }
}

class ParticipantDetailModal extends StatelessWidget {
  final String departmentName;
  final List<UserModel> participants;
  final Map<String, String> userRoles;

  const ParticipantDetailModal({
    Key? key,
    required this.departmentName,
    required this.participants,
    required this.userRoles,
  }) : super(key: key);

  Map<String, List<UserModel>> _getUsersByRole() {
    final result = <String, List<UserModel>>{
      'presenter': <UserModel>[],
      'secretary': <UserModel>[],
      'participant': <UserModel>[],
    };

    for (var user in participants) {
      final role = userRoles[user.id] ?? 'participant';
      result[role]?.add(user);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final usersByRole = _getUsersByRole();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết người tham gia',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Phòng ban: $departmentName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                              'Tổng số', participants.length, Colors.blue),
                          _buildStatCard(
                              'Trình bày',
                              usersByRole['presenter']?.length ?? 0,
                              Colors.red),
                          _buildStatCard(
                              'Thư ký',
                              usersByRole['secretary']?.length ?? 0,
                              Colors.teal),
                          _buildStatCard(
                              'Tham gia',
                              usersByRole['participant']?.length ?? 0,
                              Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Presenters
                    if (usersByRole['presenter']?.isNotEmpty == true) ...[
                      _buildRoleSection(
                          'Người trình bày',
                          usersByRole['presenter']!,
                          Colors.red,
                          Icons.slideshow),
                      const SizedBox(height: 20),
                    ],

                    // Secretary
                    if (usersByRole['secretary']?.isNotEmpty == true) ...[
                      _buildRoleSection('Thư ký', usersByRole['secretary']!,
                          Colors.teal, Icons.edit_note),
                      const SizedBox(height: 20),
                    ],

                    // Participants
                    if (usersByRole['participant']?.isNotEmpty == true) ...[
                      _buildRoleSection(
                          'Người tham gia',
                          usersByRole['participant']!,
                          Colors.blue,
                          Icons.person),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSection(
      String title, List<UserModel> users, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              '$title (${users.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Users List
        ...users
            .map((user) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: color.withOpacity(0.2),
                        child: user.photoURL != null &&
                                user.photoURL!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.photoURL!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person,
                                        color: color, size: 25);
                                  },
                                ),
                              )
                            : Icon(Icons.person, color: color, size: 25),
                      ),
                      const SizedBox(width: 16),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              title.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}
