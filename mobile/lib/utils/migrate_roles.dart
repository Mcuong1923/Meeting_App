import 'package:cloud_firestore/cloud_firestore.dart';

class MigrateRoles {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate role từ superAdmin->admin và admin->director
  static Future<void> migrateAllRoles() async {
    try {
      print('🔄 Bắt đầu migrate roles...');

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      if (snapshot.docs.isEmpty) {
        print('✅ Không có user nào trong hệ thống');
        return;
      }

      int migratedCount = 0;
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final currentRole = data['role']?.toString() ?? '';

          String? newRole;
          switch (currentRole.toLowerCase().trim()) {
            case 'super admin':
            case 'superadmin':
            case 'superAdmin':
              newRole = 'admin'; // superAdmin -> admin
              break;
            case 'admin':
              newRole = 'director'; // admin -> director
              break;
            // Các role khác giữ nguyên
            case 'manager':
              newRole = 'manager';
              break;
            case 'employee':
              newRole = 'employee';
              break;
            case 'guest':
              newRole = 'guest';
              break;
          }

          if (newRole != null && newRole != currentRole) {
            await doc.reference.update({
              'role': newRole,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            final email = data['email'] ?? 'Unknown';
            print('✅ Migrated: $email ($currentRole → $newRole)');
            migratedCount++;
          }
        } catch (e) {
          print('❌ Lỗi migrate role cho user ${doc.id}: $e');
        }
      }

      print('🎉 Hoàn thành! Đã migrate $migratedCount user roles');
      print('📋 Mapping:');
      print('   Super Admin/superAdmin → Admin (quyền cao nhất)');
      print('   Admin → Director (quản lý cấp trung)');
      print('   Manager, Employee, Guest → giữ nguyên');
    } catch (e) {
      print('❌ Lỗi migrate roles: $e');
      rethrow;
    }
  }

  /// Kiểm tra và in ra tất cả role sau khi migrate
  static Future<void> checkRolesAfterMigration() async {
    try {
      print('📋 Kiểm tra roles sau migration...');

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      if (snapshot.docs.isEmpty) {
        print('✅ Không có user nào trong hệ thống');
        return;
      }

      Map<String, int> roleCount = {};
      print('📊 Danh sách user và role:');

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final email = data['email'] ?? 'Unknown';
        final role = data['role'] ?? 'Unknown';
        final isRoleApproved = data['isRoleApproved'] ?? true;

        roleCount[role] = (roleCount[role] ?? 0) + 1;
        print('  📧 $email: role="$role", approved=$isRoleApproved');
      }

      print('\n📈 Thống kê role:');
      roleCount.forEach((role, count) {
        print('  $role: $count user(s)');
      });
    } catch (e) {
      print('❌ Lỗi check roles: $e');
    }
  }
}
