import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class CreateSuperAdmin {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo tài khoản Super Admin thô trong Firestore
  /// UID: super_admin_default
  /// Email: admin@meetingapp.com
  /// Password: admin123456 (cần tạo thủ công trên Firebase Authentication)
  static Future<void> createDefaultSuperAdmin() async {
    try {
      // Kiểm tra xem đã có Admin chưa
      QuerySnapshot adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.admin.toString().split('.').last)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        print('✅ Super Admin đã tồn tại trong hệ thống');
        return;
      }

      // Tạo Super Admin thô với UID cố định
      const String defaultAdminId = 'super_admin_default';
      await _firestore.collection('users').doc(defaultAdminId).set({
        'email': 'admin@meetingapp.com',
        'displayName': 'Super Admin',
        'role': UserRole.admin.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
        'isActive': true,
        'isRoleApproved': true,
        'pendingRole': null,
        'pendingDepartment': null,
        'departmentId': 'SYSTEM',
        'departmentName': 'Hệ thống',
        'photoURL': null,
        'teamIds': [],
        'teamNames': [],
        'managerId': null,
        'managerName': null,
        'additionalData': {
          'isDefaultAdmin': true,
          'createdBy': 'system_auto',
          'description': 'Tài khoản Super Admin mặc định được tạo tự động',
        },
      });

      print('start! create admin');
    } catch (e) {
      print('❌ Lỗi tạo Admin: $e');
      rethrow;
    }
  }

  /// Xóa Super Admin mặc định (chỉ dùng khi cần thiết)
  static Future<void> removeDefaultSuperAdmin() async {
    try {
      await _firestore.collection('users').doc('super_admin_default').delete();
      print('✅ Đã xóa  Admin mặc định');
    } catch (e) {
      print('❌ Lỗi xóa  Admin: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem có Admin nào trong hệ thống không
  static Future<bool> hasAdmin() async {
    try {
      QuerySnapshot adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.admin.toString().split('.').last)
          .limit(1)
          .get();

      return adminSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Lỗi kiểm tra Admin: $e');
      return false;
    }
  }

  // Backward compatibility
  static Future<bool> hasSuperAdmin() async => hasAdmin();

  /// Tạo Super Admin ngay lập tức và in hướng dẫn
  static Future<void> createSuperAdminNow() async {
    print('🚀 ĐANG TẠO SUPER ADMIN THÔ...');
    print('');

    await createDefaultSuperAdmin();

    print('');
    print('📖 HƯỚNG DẪN CHI TIẾT:');
    printDetailedInstructions();
  }

  /// Hướng dẫn chi tiết tạo Super Admin
  static void printDetailedInstructions() {
    print('''
🔥 HƯỚNG DẪN TẠO SUPER ADMIN HOÀN CHỈNH

📱 BƯỚC 1: TẠO USER TRÊN FIREBASE CONSOLE
1. Mở Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào Authentication > Users
4. Nhấn "Add user"
5. Nhập:
   📧 Email: admin@meetingapp.com
   🔑 Password: admin123456
   🆔 User UID: super_admin_default (QUAN TRỌNG!)

🎯 BƯỚC 2: ĐĂNG NHẬP VÀO APP
1. Mở app Meeting
2. Đăng nhập với:
   - Email: admin@meetingapp.com
   - Password: admin123456
3. Bạn sẽ tự động có quyền Super Admin!

✨ BƯỚC 3: KIỂM TRA QUYỀN
1. Vào Settings > Quản trị
2. Bạn sẽ thấy:
   - Quản lý vai trò
   - Phê duyệt vai trò
   - Thiết lập Super Admin

🔒 BẢO MẬT:
- Đổi password ngay sau khi đăng nhập lần đầu
- Không chia sẻ thông tin này với người khác
- Tạo thêm Super Admin khác qua app nếu cần

💡 LƯU Ý:
- Tài khoản này đã được tạo sẵn trong Firestore
- Chỉ cần tạo trên Firebase Authentication là xong
- Nếu quên password, reset qua Firebase Console
''');
  }
}
