import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to seed default teams for each department directly from the app.
/// This is meant to be called ONCE by an admin user.
/// 
/// Usage:
///   await TeamSeeder.seedAllTeams();
/// 
/// This is idempotent — running multiple times is safe.
class TeamSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mapping: departmentId → list of {teamId, name}
  static final Map<String, List<Map<String, String>>> _seedData = {
    'Công nghệ thông tin': [
      {'teamId': 'Công nghệ thông tin__general', 'name': 'Chung (Chưa phân team)'},
      {'teamId': 'Công nghệ thông tin__backend', 'name': 'Backend'},
      {'teamId': 'Công nghệ thông tin__mobile', 'name': 'Mobile'},
      {'teamId': 'Công nghệ thông tin__frontend', 'name': 'Frontend'},
      {'teamId': 'Công nghệ thông tin__qa', 'name': 'QA'},
      {'teamId': 'Công nghệ thông tin__devops', 'name': 'DevOps'},
    ],
    'Nhân sự': [
      {'teamId': 'Nhân sự__general', 'name': 'Chung (Chưa phân team)'},
      {'teamId': 'Nhân sự__tuyen_dung', 'name': 'Tuyển dụng'},
      {'teamId': 'Nhân sự__cnb', 'name': 'C&B'},
      {'teamId': 'Nhân sự__hanh_chinh', 'name': 'Hành chính'},
    ],
    'Marketing': [
      {'teamId': 'Marketing__general', 'name': 'Chung (Chưa phân team)'},
      {'teamId': 'Marketing__content', 'name': 'Content'},
      {'teamId': 'Marketing__performance', 'name': 'Performance'},
      {'teamId': 'Marketing__design', 'name': 'Design'},
    ],
    'Kế toán': [
      {'teamId': 'Kế toán__general', 'name': 'Chung (Chưa phân team)'},
      {'teamId': 'Kế toán__noi_bo', 'name': 'Kế toán nội bộ'},
      {'teamId': 'Kế toán__thue', 'name': 'Thuế'},
    ],
    'Kinh doanh': [
      {'teamId': 'Kinh doanh__general', 'name': 'Chung (Chưa phân team)'},
      {'teamId': 'Kinh doanh__b2b', 'name': 'Sales B2B'},
      {'teamId': 'Kinh doanh__b2c', 'name': 'Sales B2C'},
    ],
    'Vận hành': [
      {'teamId': 'Vận hành__general', 'name': 'Chung (Chưa phân team)'},
      {'teamId': 'Vận hành__cskh', 'name': 'CSKH'},
      {'teamId': 'Vận hành__logistics', 'name': 'Logistics'},
    ],
    'Khác': [
      {'teamId': 'Khác__general', 'name': 'Chung (Chưa phân team)'},
    ],
  };

  /// Seed all teams. Returns a summary message.
  static Future<String> seedAllTeams() async {
    int created = 0;
    int updated = 0;
    int skipped = 0;

    for (final entry in _seedData.entries) {
      final departmentId = entry.key;
      final teams = entry.value;

      for (final team in teams) {
        final teamId = team['teamId']!;
        final teamName = team['name']!;
        final docRef = _firestore.collection('teams').doc(teamId);
        final doc = await docRef.get();

        final teamData = {
          'name': teamName,
          'departmentId': departmentId,
          'departmentName': departmentId,
          'description': 'Team $teamName thuộc $departmentId',
          'isActive': true,
          'managerIds': <String>[],
          'memberIds': <String>[],
          'memberNames': <String>[],
        };

        if (!doc.exists) {
          await docRef.set({
            ...teamData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          created++;
          print('✅ Created team: $teamId');
        } else {
          final existing = doc.data()!;
          final needsUpdate = existing['name'] != teamName ||
              existing['departmentId'] != departmentId ||
              existing['isActive'] != true;

          if (needsUpdate) {
            await docRef.update({
              'name': teamName,
              'departmentId': departmentId,
              'departmentName': departmentId,
              'isActive': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            updated++;
            print('🔄 Updated team: $teamId');
          } else {
            skipped++;
          }
        }
      }
    }

    final summary = 'Seed hoàn tất: $created tạo mới, $updated cập nhật, $skipped bỏ qua';
    print('📊 $summary');
    return summary;
  }

  /// Backfill users who have departmentId but missing teamId.
  /// NEVER touches: role, status, isRoleApproved, accountType, departmentId, email, displayName.
  /// Only updates: teamId, teamIds, teamNames, updatedAt.
  static Future<String> backfillUserTeams() async {
    int backfilled = 0;
    int skipped = 0;
    int errors = 0;

    final usersSnapshot = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    int batchCount = 0;

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final departmentId = data['departmentId'] as String?;
      final currentTeamId = data['teamId'] as String?;

      // Skip users without department
      if (departmentId == null || departmentId.isEmpty) {
        skipped++;
        continue;
      }

      // Skip users who already have teamId
      if (currentTeamId != null && currentTeamId.isNotEmpty) {
        skipped++;
        continue;
      }

      try {
        // Determine teamId
        String newTeamId;
        String newTeamName;

        final legacyTeamIds = List<String>.from(data['teamIds'] ?? []);
        final legacyTeamNames = List<String>.from(data['teamNames'] ?? []);

        if (legacyTeamIds.isNotEmpty && legacyTeamIds.first.isNotEmpty) {
          newTeamId = legacyTeamIds.first;
          newTeamName = legacyTeamNames.isNotEmpty ? legacyTeamNames.first : 'Unknown';
        } else {
          newTeamId = '${departmentId}__general';
          newTeamName = 'Chung (Chưa phân team)';
        }

        final updateData = <String, dynamic>{
          'teamId': newTeamId,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Sync arrays if empty
        if (legacyTeamIds.isEmpty || legacyTeamIds.first.isEmpty) {
          updateData['teamIds'] = [newTeamId];
        }
        if (legacyTeamNames.isEmpty || legacyTeamNames.first.isEmpty) {
          updateData['teamNames'] = [newTeamName];
        }

        batch.update(doc.reference, updateData);
        batchCount++;
        backfilled++;

        // Commit batch at 450 to stay under 500 limit
        if (batchCount >= 450) {
          await batch.commit();
          batchCount = 0;
        }
      } catch (e) {
        errors++;
        print('❌ Error backfilling ${doc.id}: $e');
      }
    }

    // Commit remaining
    if (batchCount > 0) {
      await batch.commit();
    }

    final summary = 'Backfill hoàn tất: $backfilled cập nhật, $skipped bỏ qua, $errors lỗi';
    print('📊 $summary');
    return summary;
  }

  /// Run both seed and backfill in sequence
  static Future<String> seedAndMigrate() async {
    final seedResult = await seedAllTeams();
    final backfillResult = await backfillUserTeams();
    return '$seedResult\n$backfillResult';
  }
}
