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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: Text(
          isEditing ? 'Chỉnh sửa phòng' : 'Thêm phòng mới',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveRoom,
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
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Lưu',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF2E7BE9),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing
                          ? 'Đang cập nhật phòng...'
                          : 'Đang tạo phòng mới...',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernHeader(),
                    const SizedBox(height: 24),
                    _buildModernBasicInfoSection(),
                    const SizedBox(height: 20),
                    _buildModernLocationSection(),
                    const SizedBox(height: 20),
                    _buildModernDetailsSection(),
                    const SizedBox(height: 20),
                    _buildModernStatusSection(),
                    const SizedBox(height: 20),
                    _buildModernAmenitiesSection(),
                    const SizedBox(height: 32),
                    _buildModernSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7BE9),
            const Color(0xFF2E7BE9).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7BE9).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add_business,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa phòng họp' : 'Tạo phòng họp mới',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Cập nhật thông tin phòng họp hiện tại'
                      : 'Điền thông tin để tạo phòng họp mới',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thông tin cơ bản',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _nameController,
            label: 'Tên phòng',
            hint: 'Ví dụ: Phòng họp A1',
            icon: Icons.meeting_room,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên phòng';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _descriptionController,
            label: 'Mô tả',
            hint: 'Mô tả về phòng họp...',
            icon: Icons.description,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7BE9), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernLocationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Vị trí',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _buildingController,
            label: 'Tòa nhà',
            hint: 'Ví dụ: Tòa A, Tòa chính',
            icon: Icons.business,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _floorController,
            label: 'Tầng',
            hint: 'Ví dụ: 1, 2, 3...',
            icon: Icons.layers,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _locationController,
            label: 'Vị trí cụ thể',
            hint: 'Ví dụ: Cạnh thang máy, cuối hành lang',
            icon: Icons.room,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Chi tiết',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _capacityController,
                  label: 'Sức chứa',
                  hint: 'Số người',
                  icon: Icons.people,
                  suffix: 'người',
                  isRequired: true,
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
                child: _buildModernTextField(
                  controller: _areaController,
                  label: 'Diện tích',
                  hint: 'Diện tích',
                  icon: Icons.square_foot,
                  suffix: 'm²',
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

  Widget _buildModernSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7BE9),
            const Color(0xFF2E7BE9).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7BE9).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.update : Icons.add,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Cập nhật phòng' : 'Tạo phòng mới',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModernStatusSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Trạng thái',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: RoomStatus.values.length,
            itemBuilder: (context, index) {
              final status = RoomStatus.values[index];
              final isSelected = _selectedStatus == status;
              final statusColor = _getStatusColor(status);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? statusColor.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? statusColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected ? statusColor : Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: statusColor,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernAmenitiesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.devices,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tiện ích',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemCount: RoomAmenity.values.length,
            itemBuilder: (context, index) {
              final amenity = RoomAmenity.values[index];
              final isSelected = _selectedAmenities.contains(amenity);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAmenities.remove(amenity);
                    } else {
                      _selectedAmenities.add(amenity);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        size: 18,
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getAmenityName(amenity),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
