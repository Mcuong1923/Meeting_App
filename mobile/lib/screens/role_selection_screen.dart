import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../constants.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;
  String? _selectedDepartment;
  bool _isSubmitting = false;

  final List<String> _departments = [
    'Công nghệ thông tin',
    'Nhân sự',
    'Marketing',
    'Kế toán',
    'Kinh doanh',
    'Vận hành',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập vai trò'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Không cho phép back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Chào mừng bạn đến với hệ thống quản lý cuộc họp!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vui lòng chọn vai trò và phòng ban của bạn để tiếp tục sử dụng ứng dụng.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 30),

            // Chọn vai trò
            Text(
              'Vai trò của bạn:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 15),
            _buildRoleSelection(),

            const SizedBox(height: 30),

            // Chọn phòng ban
            Text(
              'Phòng ban:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 15),
            _buildDepartmentSelection(),

            const SizedBox(height: 40),

            // Nút gửi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedRole != null && !_isSubmitting
                    ? _submitRoleAndDepartment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xác nhận',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Thông báo
            if (_selectedRole != null && _selectedRole != UserRole.guest)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vai trò của bạn sẽ được Super Admin phê duyệt. Trong thời gian chờ, bạn sẽ có quyền Guest.',
                        style: TextStyle(color: Colors.orange[800]),
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

  Widget _buildRoleSelection() {
    return Column(
      children: UserRole.values
          .where((role) =>
              role != UserRole.admin) // Loại bỏ Admin (quyền cao nhất)
          .map((role) => _buildRoleCard(role))
          .toList(),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              _getRoleIcon(role),
              color: isSelected ? kPrimaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRoleName(role),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? kPrimaryColor : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _getRoleDescription(role),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: kPrimaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSelection() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        hintText: 'Chọn phòng ban',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
      items: _departments.map((department) {
        return DropdownMenuItem(
          value: department,
          child: Text(department),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value;
        });
      },
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.director:
        return 'Director';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
      case UserRole.guest:
        return 'Guest';
      default:
        return 'Unknown';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.director:
        return 'Giám đốc - Có quyền quản lý phòng ban và nhân sự';
      case UserRole.manager:
        return 'Quản lý - Có quyền quản lý team và phê duyệt cuộc họp';
      case UserRole.employee:
        return 'Nhân viên - Có quyền tạo và tham gia cuộc họp';
      case UserRole.guest:
        return 'Khách - Chỉ có quyền xem thông tin cơ bản (không cần phê duyệt)';
      default:
        return '';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.director:
        return Icons.manage_accounts;
      case UserRole.manager:
        return Icons.people;
      case UserRole.employee:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
      default:
        return Icons.help;
    }
  }

  Future<void> _submitRoleAndDepartment() async {
    if (_selectedRole == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.submitRoleAndDepartment(
        selectedRole: _selectedRole!,
        selectedDepartment: _selectedDepartment,
      );

      if (mounted) {
        // Chuyển về màn hình chính
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );

        // Hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedRole == UserRole.guest
                ? 'Đã thiết lập vai trò thành công!'
                : 'Đã gửi yêu cầu phê duyệt vai trò. Vui lòng chờ Super Admin xác nhận.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
