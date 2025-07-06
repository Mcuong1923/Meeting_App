import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/calendar_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../components/rounded_input_field.dart';
import '../components/rounded_password_field.dart';
import '../components/text_field_container.dart';

class MeetingCreateScreen extends StatefulWidget {
  const MeetingCreateScreen({Key? key}) : super(key: key);

  @override
  State<MeetingCreateScreen> createState() => _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends State<MeetingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _agendaController = TextEditingController();
  final _locationController = TextEditingController();
  final _virtualLinkController = TextEditingController();
  final _virtualPasswordController = TextEditingController();
  final _notesController = TextEditingController();

  MeetingType _selectedType = MeetingType.personal;
  MeetingScope _selectedScope = MeetingScope.company;
  MeetingLocationType _selectedLocationType = MeetingLocationType.physical;
  MeetingPriority _selectedPriority = MeetingPriority.medium;
  String? _selectedDepartmentId;
  String? _selectedTeamId;
  bool _needsApproval = false;

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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      // Set default meeting type based on user role
      final allowedTypes = authProvider.userModel!.getAllowedMeetingTypes();
      if (allowedTypes.isNotEmpty) {
        _selectedType = allowedTypes.first;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _agendaController.dispose();
    _locationController.dispose();
    _virtualLinkController.dispose();
    _virtualPasswordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo cuộc họp mới'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 20),
                  _buildDateTimeSection(),
                  const SizedBox(height: 20),
                  _buildLocationSection(),
                  const SizedBox(height: 20),
                  _buildParticipantsSection(),
                  const SizedBox(height: 20),
                  _buildScopeSection(),
                  const SizedBox(height: 20),
                  _buildNotesAndActionsSection(),
                  const SizedBox(height: 20),
                  _buildAttachmentsSection(),
                  const SizedBox(height: 20),
                  _buildSettingsSection(),
                  const SizedBox(height: 30),
                  _buildCreateButton(authProvider.userModel!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            RoundedInputField(
              controller: _titleController,
              hintText: 'Tiêu đề cuộc họp',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiêu đề cuộc họp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mô tả
            RoundedInputField(
              controller: _descriptionController,
              hintText: 'Mô tả cuộc họp',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Loại cuộc họp
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final allowedTypes =
                    authProvider.userModel?.getAllowedMeetingTypes() ?? [];
                return DropdownButtonFormField<MeetingType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại cuộc họp',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: allowedTypes.map((type) {
                    String label = '';
                    switch (type) {
                      case MeetingType.personal:
                        label = 'Cá nhân';
                        break;
                      case MeetingType.team:
                        label = 'Team';
                        break;
                      case MeetingType.department:
                        label = 'Phòng ban';
                        break;
                      case MeetingType.company:
                        label = 'Công ty';
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Độ ưu tiên
            DropdownButtonFormField<MeetingPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Độ ưu tiên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: MeetingPriority.values.map((priority) {
                String label = '';
                IconData icon = Icons.flag;
                Color color = Colors.grey;

                switch (priority) {
                  case MeetingPriority.low:
                    label = 'Thấp';
                    icon = Icons.flag;
                    color = Colors.green;
                    break;
                  case MeetingPriority.medium:
                    label = 'Trung bình';
                    icon = Icons.flag;
                    color = Colors.orange;
                    break;
                  case MeetingPriority.high:
                    label = 'Cao';
                    icon = Icons.flag;
                    color = Colors.red;
                    break;
                  case MeetingPriority.urgent:
                    label = 'Khẩn cấp';
                    icon = Icons.warning;
                    color = Colors.red;
                    break;
                }

                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Ngày
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              onTap: () => _selectDate(context),
            ),

            // Giờ bắt đầu
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Giờ bắt đầu'),
              subtitle: Text(_selectedStartTime.format(context)),
              onTap: () => _selectStartTime(context),
            ),

            // Giờ kết thúc
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('Giờ kết thúc'),
              subtitle: Text(_selectedEndTime.format(context)),
              onTap: () => _selectEndTime(context),
            ),

            // Cuộc họp định kỳ
            CheckboxListTile(
              title: const Text('Cuộc họp định kỳ'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value ?? false;
                });
              },
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurringPattern,
                decoration: const InputDecoration(
                  labelText: 'Tần suất',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                  DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                  DropdownMenuItem(value: 'monthly', child: Text('Hàng tháng')),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurringPattern = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa điểm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Loại địa điểm
            DropdownButtonFormField<MeetingLocationType>(
              value: _selectedLocationType,
              decoration: const InputDecoration(
                labelText: 'Loại địa điểm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: MeetingLocationType.values.map((type) {
                String label = '';
                switch (type) {
                  case MeetingLocationType.physical:
                    label = 'Trực tiếp';
                    break;
                  case MeetingLocationType.virtual:
                    label = 'Trực tuyến';
                    break;
                  case MeetingLocationType.hybrid:
                    label = 'Kết hợp';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLocationType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Địa điểm vật lý
            if (_selectedLocationType == MeetingLocationType.physical ||
                _selectedLocationType == MeetingLocationType.hybrid) ...[
              RoundedInputField(
                controller: _locationController,
                hintText: 'Địa điểm (phòng họp, địa chỉ...)',
                icon: Icons.room,
              ),
              const SizedBox(height: 16),
            ],

            // Link trực tuyến
            if (_selectedLocationType == MeetingLocationType.virtual ||
                _selectedLocationType == MeetingLocationType.hybrid) ...[
              RoundedInputField(
                controller: _virtualLinkController,
                hintText: 'Link cuộc họp trực tuyến',
                icon: Icons.link,
              ),
              const SizedBox(height: 16),
              if (_requirePassword) ...[
                RoundedPasswordField(
                  controller: _virtualPasswordController,
                  hintText: 'Mật khẩu cuộc họp',
                ),
                const SizedBox(height: 16),
              ],
              CheckboxListTile(
                title: const Text('Yêu cầu mật khẩu'),
                value: _requirePassword,
                onChanged: (value) {
                  setState(() {
                    _requirePassword = value ?? false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Người tham gia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _addParticipant(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_participants.isEmpty)
              const Center(
                child: Text(
                  'Chưa có người tham gia',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final participant = _participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participant.userName[0].toUpperCase()),
                    ),
                    title: Text(participant.userName),
                    subtitle:
                        Text('${participant.userEmail} - ${participant.role}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeParticipant(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phạm vi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Phạm vi
            DropdownButtonFormField<MeetingScope>(
              value: _selectedScope,
              decoration: const InputDecoration(
                labelText: 'Phạm vi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              items: MeetingScope.values.map((scope) {
                String label = '';
                switch (scope) {
                  case MeetingScope.personal:
                    label = 'Cá nhân';
                    break;
                  case MeetingScope.team:
                    label = 'Team';
                    break;
                  case MeetingScope.department:
                    label = 'Phòng ban';
                    break;
                  case MeetingScope.company:
                    label = 'Công ty';
                    break;
                }
                return DropdownMenuItem(
                  value: scope,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedScope = value;
                    _updateApprovalRequirement();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Department selection (nếu chọn department)
            if (_selectedScope == MeetingScope.department)
              DropdownButtonFormField<String>(
                value: _selectedDepartmentId,
                decoration: const InputDecoration(
                  labelText: 'Chọn phòng ban',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: _getDepartmentOptions(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartmentId = value;
                  });
                },
              ),

            // Team selection (nếu chọn team)
            if (_selectedScope == MeetingScope.team)
              DropdownButtonFormField<String>(
                value: _selectedTeamId,
                decoration: const InputDecoration(
                  labelText: 'Chọn team',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                items: _getTeamOptions(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeamId = value;
                  });
                },
              ),

            // Thông báo cần phê duyệt
            if (_needsApproval)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cuộc họp này cần được phê duyệt do phạm vi vượt quyền hạn của bạn.',
                        style: TextStyle(color: Colors.orange.shade800),
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

  Widget _buildNotesAndActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú & Việc cần làm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Meeting Notes
            RoundedInputField(
              controller: _notesController,
              hintText: 'Ghi chú cuộc họp (nội dung, mục tiêu, yêu cầu...)',
              icon: Icons.note_alt,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Action Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Việc cần làm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _addActionItem,
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Thêm việc'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action Items List
            if (_actionItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có việc cần làm nào\nNhấn "Thêm việc" để thêm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _actionItems.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: index > 0
                            ? Border(
                                top: BorderSide(color: Colors.grey.shade200))
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.radio_button_unchecked,
                              size: 12, color: Colors.blue),
                        ),
                        title: Text(
                          _actionItems[index],
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          onPressed: () => _removeActionItem(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài liệu đính kèm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Upload button
            ElevatedButton.icon(
              onPressed: _addAttachment,
              icon: const Icon(Icons.upload_file),
              label: const Text('Chọn file để đính kèm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Attachments List
            if (_attachments.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có tài liệu đính kèm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: index > 0
                            ? Border(
                                top: BorderSide(color: Colors.grey.shade200))
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.attach_file,
                              size: 12, color: Colors.blue),
                        ),
                        title: Text(
                          _attachments[index].name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          onPressed: () => _removeAttachment(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Cho phép tham gia trước chủ tọa'),
              value: _allowJoinBeforeHost,
              onChanged: (value) {
                setState(() {
                  _allowJoinBeforeHost = value ?? true;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Tắt mic khi vào cuộc họp'),
              value: _muteOnEntry,
              onChanged: (value) {
                setState(() {
                  _muteOnEntry = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Ghi lại cuộc họp'),
              value: _recordMeeting,
              onChanged: (value) {
                setState(() {
                  _recordMeeting = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(UserModel currentUser) {
    return Consumer<MeetingProvider>(
      builder: (context, meetingProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: meetingProvider.isLoading ? null : _createMeeting,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: meetingProvider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Tạo cuộc họp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
        // Tự động cập nhật giờ kết thúc (tránh overflow hour)
        _selectedEndTime = TimeOfDay(
          hour: (picked.hour + 1) % 24,
          minute: picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  void _addParticipant() {
    showDialog(
      context: context,
      builder: (context) => _AddParticipantDialog(
        onParticipantAdded: (participant) {
          setState(() {
            _participants.add(participant);
          });
        },
        existingParticipants: _participants,
      ),
    );
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  void _addActionItem() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm việc cần làm'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập nội dung công việc...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _actionItems.add(text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _removeActionItem(int index) {
    setState(() {
      _actionItems.removeAt(index);
    });
  }

  void _addAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'jpg',
          'png'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachments.addAll(result.files);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${result.files.length} file(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    // Tạo thời gian bắt đầu và kết thúc
    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedStartTime.hour,
      _selectedStartTime.minute,
    );

    // Xử lý trường hợp endTime có thể là ngày hôm sau
    final endTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    ).add(_selectedEndTime.hour < _selectedStartTime.hour
        ? const Duration(days: 1)
        : Duration.zero);

    // Kiểm tra thời gian
    if (endTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thời gian kết thúc phải sau thời gian bắt đầu')),
      );
      return;
    }

    // Tạo cuộc họp mới
    final meeting = MeetingModel(
      id: '', // Sẽ được tạo bởi Firestore
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      status: MeetingStatus.pending, // Sẽ được cập nhật bởi provider
      locationType: _selectedLocationType,
      priority: _selectedPriority,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: endTime.difference(startTime).inMinutes,
      physicalLocation: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      virtualMeetingLink: _virtualLinkController.text.trim().isEmpty
          ? null
          : _virtualLinkController.text.trim(),
      virtualMeetingPassword: _virtualPasswordController.text.trim().isEmpty
          ? null
          : _virtualPasswordController.text.trim(),
      creatorId: authProvider.userModel!.id,
      creatorName: authProvider.userModel!.displayName,
      participants: _participants,
      agenda: _agendaController.text.trim().isEmpty
          ? null
          : _agendaController.text.trim(),
      meetingNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      actionItems: _actionItems,
      attachments: _attachments.map((file) => file.name).toList(),
      scope: _selectedScope,
      approvalStatus: _needsApproval
          ? MeetingApprovalStatus.pending
          : MeetingApprovalStatus.auto_approved,
      targetDepartmentId: _selectedDepartmentId,
      targetTeamId: _selectedTeamId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      departmentId: authProvider.userModel!.departmentId,
      departmentName: authProvider.userModel!.departmentName,
      isRecurring: _isRecurring,
      recurringPattern: _recurringPattern,
      recurringEndDate: _recurringEndDate,
      allowJoinBeforeHost: _allowJoinBeforeHost,
      muteOnEntry: _muteOnEntry,
      recordMeeting: _recordMeeting,
      requirePassword: _requirePassword,
    );

    final result = await meetingProvider.createMeeting(
        meeting, authProvider.userModel!, notificationProvider);

    if (result != null) {
      // Refresh calendar để hiển thị meeting mới
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);
      calendarProvider.loadEvents(
        authProvider.userModel!.id,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 60)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.isPending
                ? 'Cuộc họp đã được tạo và chờ phê duyệt'
                : 'Cuộc họp đã được tạo thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(meetingProvider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateApprovalRequirement() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    setState(() {
      // Admin và Director không cần phê duyệt
      if (currentUser.isAdmin || currentUser.isDirector) {
        _needsApproval = false;
      }
      // Manager cần phê duyệt cho company scope
      else if (currentUser.isManager) {
        _needsApproval = _selectedScope == MeetingScope.company;
      }
      // Employee cần phê duyệt cho department và company
      else {
        _needsApproval = _selectedScope == MeetingScope.department ||
            _selectedScope == MeetingScope.company;
      }
    });
  }

  List<DropdownMenuItem<String>> _getDepartmentOptions() {
    return [
      const DropdownMenuItem(value: 'tech', child: Text('Phòng Kỹ thuật')),
      const DropdownMenuItem(value: 'hr', child: Text('Phòng Nhân sự')),
      const DropdownMenuItem(
          value: 'marketing', child: Text('Phòng Marketing')),
      const DropdownMenuItem(value: 'sales', child: Text('Phòng Kinh doanh')),
      const DropdownMenuItem(value: 'finance', child: Text('Phòng Tài chính')),
      const DropdownMenuItem(value: 'admin', child: Text('Phòng Hành chính')),
    ];
  }

  List<DropdownMenuItem<String>> _getTeamOptions() {
    return [
      const DropdownMenuItem(value: 'dev_team', child: Text('Team Phát triển')),
      const DropdownMenuItem(value: 'qa_team', child: Text('Team QA')),
      const DropdownMenuItem(value: 'ui_team', child: Text('Team UI/UX')),
      const DropdownMenuItem(
          value: 'product_team', child: Text('Team Product')),
      const DropdownMenuItem(value: 'data_team', child: Text('Team Data')),
      const DropdownMenuItem(value: 'mobile_team', child: Text('Team Mobile')),
    ];
  }
}

// Add Participant Dialog
class _AddParticipantDialog extends StatefulWidget {
  final Function(MeetingParticipant) onParticipantAdded;
  final List<MeetingParticipant> existingParticipants;

  const _AddParticipantDialog({
    Key? key,
    required this.onParticipantAdded,
    required this.existingParticipants,
  }) : super(key: key);

  @override
  State<_AddParticipantDialog> createState() => _AddParticipantDialogState();
}

class _AddParticipantDialogState extends State<_AddParticipantDialog> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'participant';
  bool _isRequired = true;
  bool _isLoading = false;
  List<UserModel> _searchResults = [];

  final List<String> _participantRoles = [
    'participant',
    'presenter',
    'secretary',
    'chair',
  ];

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'chair':
        return 'Chủ tọa';
      case 'secretary':
        return 'Thư ký';
      case 'presenter':
        return 'Người thuyết trình';
      case 'participant':
        return 'Người tham gia';
      default:
        return 'Người tham gia';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm người tham gia'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search users
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email người tham gia',
                hintText: 'Nhập email để tìm kiếm',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),

            // Search results
            if (_searchResults.isNotEmpty) ...[
              const Text('Kết quả tìm kiếm:'),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isAlreadyAdded = widget.existingParticipants
                        .any((p) => p.userEmail == user.email);

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.displayName[0].toUpperCase()),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                      trailing: isAlreadyAdded
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: isAlreadyAdded
                          ? null
                          : () {
                              _emailController.text = user.email;
                              _nameController.text = user.displayName;
                              setState(() {
                                _searchResults.clear();
                              });
                            },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manual input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên người tham gia',
                hintText: 'Nhập tên hiển thị',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Role selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Vai trò trong cuộc họp',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment_ind),
              ),
              items: _participantRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(_getRoleDisplayName(role)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value ?? 'participant';
                });
              },
            ),
            const SizedBox(height: 16),

            // Required checkbox
            CheckboxListTile(
              title: const Text('Bắt buộc tham gia'),
              value: _isRequired,
              onChanged: (value) {
                setState(() {
                  _isRequired = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addParticipant,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }

  void _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final allUsers = await authProvider.getAllUsers();

      final results = allUsers
          .where((user) =>
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.displayName.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
    }
  }

  void _addParticipant() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    // Check if participant already exists
    final exists = widget.existingParticipants
        .any((p) => p.userEmail.toLowerCase() == email.toLowerCase());

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người này đã được thêm vào cuộc họp')),
      );
      return;
    }

    final participant = MeetingParticipant(
      userId: '', // Will be resolved later
      userName: name,
      userEmail: email,
      role: _selectedRole,
      isRequired: _isRequired,
    );

    widget.onParticipantAdded(participant);
    Navigator.pop(context);
  }
}
