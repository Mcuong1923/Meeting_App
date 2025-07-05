import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../components/rounded_input_field.dart';
import '../components/rounded_password_field.dart';

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

  MeetingType _selectedType = MeetingType.personal;
  MeetingLocationType _selectedLocationType = MeetingLocationType.physical;
  MeetingPriority _selectedPriority = MeetingPriority.medium;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime =
      TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

  bool _isRecurring = false;
  String? _recurringPattern;
  DateTime? _recurringEndDate;

  bool _allowJoinBeforeHost = true;
  bool _muteOnEntry = false;
  bool _recordMeeting = false;
  bool _requirePassword = false;

  List<MeetingParticipant> _participants = [];

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
        // Tự động cập nhật giờ kết thúc
        _selectedEndTime = picked.replacing(hour: picked.hour + 1);
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
    // TODO: Implement add participant dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm người tham gia'),
        content: const Text('Tính năng này sẽ được implement sau'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  void _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider =
        Provider.of<MeetingProvider>(context, listen: false);

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

    final endTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );

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

    final result =
        await meetingProvider.createMeeting(meeting, authProvider.userModel!);

    if (result != null) {
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
}
