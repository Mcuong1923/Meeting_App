import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';

class AddEditRoomScreen extends StatefulWidget {
  final RoomModel? room;

  const AddEditRoomScreen({Key? key, this.room}) : super(key: key);

  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _floorController = TextEditingController();
  final _buildingController = TextEditingController();
  final _capacityController = TextEditingController();
  final _areaController = TextEditingController();

  RoomStatus _selectedStatus = RoomStatus.available;
  List<RoomAmenity> _selectedAmenities = [];
  bool _isLoading = false;

  bool get isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadRoomData();
    }
  }

  void _loadRoomData() {
    final room = widget.room!;
    _nameController.text = room.name;
    _descriptionController.text = room.description;
    _locationController.text = room.location;
    _floorController.text = room.floor;
    _buildingController.text = room.building;
    _capacityController.text = room.capacity.toString();
    _areaController.text = room.area.toString();
    _selectedStatus = room.status;
    _selectedAmenities = List.from(room.amenities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _floorController.dispose();
    _buildingController.dispose();
    _capacityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa phòng' : 'Thêm phòng mới'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRoom,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildDetailsSection(),
                    const SizedBox(height: 24),
                    _buildStatusSection(),
                    const SizedBox(height: 24),
                    _buildAmenitiesSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin cơ bản',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên phòng *',
                hintText: 'Ví dụ: Phòng họp A1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên phòng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả về phòng họp...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vị trí',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buildingController,
              decoration: const InputDecoration(
                labelText: 'Tòa nhà',
                hintText: 'Ví dụ: Tòa A, Tòa chính',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Tầng',
                hintText: 'Ví dụ: 1, 2, 3...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Vị trí cụ thể',
                hintText: 'Ví dụ: Cạnh thang máy, cuối hành lang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Sức chứa *',
                      hintText: 'Số người',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                      suffixText: 'người',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập sức chứa';
                      }
                      final capacity = int.tryParse(value);
                      if (capacity == null || capacity <= 0) {
                        return 'Sức chứa phải là số dương';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Diện tích',
                      hintText: 'Diện tích',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.square_foot),
                      suffixText: 'm²',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final area = double.tryParse(value);
                        if (area == null || area <= 0) {
                          return 'Diện tích phải là số dương';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: RoomStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                return FilterChip(
                  label: Text(_getStatusText(status)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  selectedColor: _getStatusColor(status).withOpacity(0.2),
                  checkmarkColor: _getStatusColor(status),
                  avatar: isSelected
                      ? null
                      : Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiện ích',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 4,
              ),
              itemCount: RoomAmenity.values.length,
              itemBuilder: (context, index) {
                final amenity = RoomAmenity.values[index];
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        size: 16,
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _getAmenityName(amenity),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                  selectedColor: Colors.blue.withOpacity(0.1),
                  checkmarkColor: Colors.blue,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditing ? 'Cập nhật phòng' : 'Tạo phòng mới',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Sẵn sàng';
      case RoomStatus.occupied:
        return 'Đang sử dụng';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.disabled:
        return 'Tạm ngưng';
    }
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.orange;
      case RoomStatus.maintenance:
        return Colors.red;
      case RoomStatus.disabled:
        return Colors.grey;
    }
  }

  IconData _getAmenityIcon(RoomAmenity amenity) {
    switch (amenity) {
      case RoomAmenity.projector:
        return Icons.slideshow;
      case RoomAmenity.whiteboard:
        return Icons.dashboard;
      case RoomAmenity.wifi:
        return Icons.wifi;
      case RoomAmenity.airConditioner:
        return Icons.ac_unit;
      case RoomAmenity.microphone:
        return Icons.mic;
      case RoomAmenity.speaker:
        return Icons.speaker;
      case RoomAmenity.camera:
        return Icons.camera_alt;
      case RoomAmenity.monitor:
        return Icons.monitor;
      case RoomAmenity.flipChart:
        return Icons.flip_to_front;
      case RoomAmenity.waterDispenser:
        return Icons.water_drop;
      case RoomAmenity.powerOutlet:
        return Icons.power;
      case RoomAmenity.videoConference:
        return Icons.video_call;
    }
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
        return 'Cây nước';
      case RoomAmenity.powerOutlet:
        return 'Ổ cắm điện';
      case RoomAmenity.videoConference:
        return 'Họp online';
    }
  }

  void _saveRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final roomData = RoomModel(
        id: isEditing ? widget.room!.id : '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        floor: _floorController.text.trim(),
        building: _buildingController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        status: _selectedStatus,
        amenities: _selectedAmenities,
        area: double.tryParse(_areaController.text.trim()) ?? 0.0,
        createdAt: isEditing ? widget.room!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: isEditing ? widget.room!.createdBy : currentUser.id,
        updatedBy: currentUser.id,
      );

      final roomProvider = context.read<RoomProvider>();

      if (isEditing) {
        await roomProvider.updateRoom(roomData, currentUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật phòng thành công')),
          );
        }
      } else {
        await roomProvider.createRoom(roomData, currentUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo phòng mới thành công')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
