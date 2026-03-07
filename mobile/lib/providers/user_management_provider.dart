import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/team_model.dart';

/// Provider quản lý user dành cho Admin / Director / Manager.
/// Mỗi thao tác đều enforce scope trước khi thực thi.
class UserManagementProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  // Actor (current admin / director / manager)
  UserModel? _actor;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Initialise actor ─────────────────────────────────────────────────
  void setActor(UserModel? actor) {
    _actor = actor;
  }

  // ── Load all users (scope-aware) ──────────────────────────────────────
  Future<void> loadUsers() async {
    if (_actor == null) return;
    _setLoading(true);
    _error = null;
    try {
      QuerySnapshot snap;
      if (_actor!.isAdmin) {
        snap = await _db.collection('users').get();
      } else if (_actor!.isDirector && _actor!.departmentId != null) {
        snap = await _db
            .collection('users')
            .where('departmentId', isEqualTo: _actor!.departmentId)
            .get();
      } else if (_actor!.isManager && _actor!.teamId != null) {
        snap = await _db
            .collection('users')
            .where('teamId', isEqualTo: _actor!.teamId)
            .get();
      } else {
        _users = [];
        _setLoading(false);
        return;
      }

      _users = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        final u = UserModel.fromMap(data, d.id);
        // Self-healing: sync teamIds with teamId if mismatch
        return _healTeamFields(u, data);
      }).toList();

      // Sort: role hierarchy → displayName
      const order = {
        UserRole.admin: 1,
        UserRole.director: 2,
        UserRole.manager: 3,
        UserRole.employee: 4,
        UserRole.guest: 5,
      };
      _users.sort((a, b) {
        final ro =
            (order[a.role] ?? 6).compareTo(order[b.role] ?? 6);
        return ro != 0 ? ro : a.displayName.compareTo(b.displayName);
      });
    } catch (e) {
      _error = 'Lỗi tải danh sách người dùng: $e';
      debugPrint('[UMP] loadUsers error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Update display name ───────────────────────────────────────────────
  Future<void> updateDisplayName(String uid, String newName) async {
    _assertActor();
    if (newName.trim().isEmpty) throw Exception('Tên không được để trống');
    await _db.collection('users').doc(uid).update({
      'displayName': newName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _patchLocal(uid, (u) => u.copyWith(displayName: newName.trim()));
  }

  // ── Update department ─────────────────────────────────────────────────
  /// Đổi phòng ban: auto-assign general team của dept mới,
  /// sync tất cả legacy fields (teamId / teamIds / teamNames / teamName).
  Future<void> updateDepartment(
    String uid,
    String newDeptId,
    String newDeptName,
  ) async {
    _assertActor();
    if (_actor!.isDirector && !_actor!.isAdmin) {
      throw Exception('Director không có quyền đổi phòng ban');
    }

    // Tìm first real team (order=1, non-general) hoặc fallback general
    final TeamModel? firstTeam = await _fetchFirstTeam(newDeptId);
    final String? teamId = firstTeam?.id;
    final String? teamName = firstTeam?.name;

    await _db.collection('users').doc(uid).update({
      'departmentId': newDeptId,
      'departmentName': newDeptName,
      // Single truth fields
      'teamId': teamId,
      'teamName': teamName, // singular — keep in sync
      // Legacy arrays
      'teamIds': teamId != null ? [teamId] : [],
      'teamNames': teamName != null ? [teamName] : [],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _patchLocal(
      uid,
      (u) => u.copyWith(
        departmentId: newDeptId,
        departmentName: newDeptName,
        teamId: teamId,
        teamIds: teamId != null ? [teamId] : [],
        teamNames: teamName != null ? [teamName] : [],
      ),
    );
  }

  // ── Update team ───────────────────────────────────────────────────────
  /// Đổi team: validate rằng team thuộc đúng department của user.
  Future<void> updateTeam(
    String uid,
    String userDeptId,
    String newTeamId,
    String newTeamName,
  ) async {
    _assertActor();

    // Validate: fetch team doc và check departmentId
    final teamDoc = await _db.collection('teams').doc(newTeamId).get();
    if (!teamDoc.exists) throw Exception('Team không tồn tại');
    final teamData = teamDoc.data() as Map<String, dynamic>;
    final teamDept = teamData['departmentId']?.toString() ?? '';
    if (teamDept != userDeptId) {
      throw Exception('Team không thuộc phòng ban hiện tại của người dùng');
    }

    // Director can only update team within own dept
    if (_actor!.isDirector && !_actor!.isAdmin) {
      if (userDeptId != _actor!.departmentId) {
        throw Exception('Không có quyền cập nhật team của phòng ban khác');
      }
    }

    await _db.collection('users').doc(uid).update({
      'teamId': newTeamId,
      'teamName': newTeamName, // singular — keep in sync
      'teamIds': [newTeamId],
      'teamNames': [newTeamName],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _patchLocal(
      uid,
      (u) => u.copyWith(
        teamId: newTeamId,
        teamIds: [newTeamId],
        teamNames: [newTeamName],
      ),
    );
  }

  // ── Update role ───────────────────────────────────────────────────────
  Future<void> updateRole(String uid, UserRole newRole) async {
    _assertActor();

    final target = _findLocal(uid);

    // ═══════════════════════════════════════════════════════════════════
    // PERMISSION MATRIX
    // ═══════════════════════════════════════════════════════════════════

    // 0. Không cho phép thay đổi role của chính mình
    if (_actor!.id == uid) {
      throw Exception('Không thể thay đổi vai trò của chính mình');
    }

    if (_actor!.isAdmin) {
      // ── Admin ──────────────────────────────────────────────────────
      // Admin KHÔNG thể chạm vào admin khác
      if (target != null && target.role == UserRole.admin) {
        throw Exception('Không thể thay đổi vai trò của Admin khác');
      }
      // Admin KHÔNG thể promote bất kỳ ai lên admin
      if (newRole == UserRole.admin) {
        throw Exception('Không thể promote lên role Admin');
      }

    } else if (_actor!.isDirector) {
      // ── Director ───────────────────────────────────────────────────
      // Director KHÔNG được chạm vào: Admin, Director khác
      if (target != null &&
          (target.role == UserRole.admin || target.role == UserRole.director)) {
        throw Exception(
          'Director không có quyền thay đổi vai trò của Admin hoặc Director khác',
        );
      }
      // Director KHÔNG được promote lên: Admin, Director, Manager
      if (newRole == UserRole.admin ||
          newRole == UserRole.director ||
          newRole == UserRole.manager) {
        throw Exception(
          'Director chỉ được thay đổi role xuống Employee hoặc Guest',
        );
      }

    } else if (_actor!.isManager) {
      // ── Manager ────────────────────────────────────────────────────
      // Manager KHÔNG được chạm vào: Admin, Director, Manager khác
      if (target != null &&
          (target.role == UserRole.admin ||
           target.role == UserRole.director ||
           target.role == UserRole.manager)) {
        throw Exception(
          'Manager không có quyền thay đổi vai trò của Admin, Director hoặc Manager khác',
        );
      }
      // Manager KHÔNG được promote lên: Admin, Director, Manager
      if (newRole == UserRole.admin ||
          newRole == UserRole.director ||
          newRole == UserRole.manager) {
        throw Exception(
          'Manager chỉ được thay đổi role xuống Employee hoặc Guest',
        );
      }

    } else {
      // Employee / Guest → không có quyền thay đổi bất kỳ ai
      throw Exception('Bạn không có quyền thay đổi vai trò người dùng');
    }

    await _db.collection('users').doc(uid).update({
      'role': newRole.name,
      'isRoleApproved': true,
      'status': 'active',
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _patchLocal(uid, (u) => u.copyWith(
      role: newRole,
      isRoleApproved: true,
      status: 'active',
      isActive: true,
    ));
  }

  // ── Update status ─────────────────────────────────────────────────────
  Future<void> updateStatus(String uid, String newStatus) async {
    _assertActor();
    assert(['active', 'disabled', 'pending'].contains(newStatus));
    await _db.collection('users').doc(uid).update({
      'status': newStatus,
      'isActive': newStatus == 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _patchLocal(
      uid,
      (u) => u.copyWith(
        status: newStatus,
        isActive: newStatus == 'active',
      ),
    );
  }

  // ── Approve pending request ───────────────────────────────────────────
  Future<void> approveUser(String uid) async {
    _assertActor();
    final userDoc = _db.collection('users').doc(uid);
    final snap = await userDoc.get();
    if (!snap.exists) throw Exception('User không tồn tại');

    final data = snap.data() as Map<String, dynamic>;
    final reqRole = data['requestedRole'] ?? data['pendingRole'];
    final reqDept = data['requestedDepartmentId'] ?? data['pendingDepartment'];
    final reqTeam = data['requestedTeamId'];
    final reqDeptName = _mapDeptIdToName(reqDept?.toString() ?? '');

    if (reqRole == null || reqDept == null) {
      throw Exception('Không có yêu cầu chờ duyệt');
    }

    // Kiểm tra quyền duyệt theo actor role (nhất quán với updateRole)
    if (_actor!.isAdmin) {
      // Admin: không thể duyệt lên admin
      if (reqRole == 'admin') {
        throw Exception('Không thể phê duyệt role Admin');
      }
    } else if (_actor!.isDirector) {
      // Director: chỉ duyệt employee/guest - không duyệt admin/director/manager
      if (reqRole == 'admin' || reqRole == 'director' || reqRole == 'manager') {
        throw Exception('Director chỉ có thể phê duyệt Employee hoặc Guest');
      }
    } else if (_actor!.isManager) {
      // Manager: chỉ duyệt employee/guest
      if (reqRole != 'employee' && reqRole != 'guest') {
        throw Exception('Manager chỉ có thể phê duyệt Employee hoặc Guest');
      }
    }

    await userDoc.update({
      'role': reqRole,
      'departmentId': reqDept,
      'departmentName': reqDeptName,
      if (reqTeam != null) 'teamId': reqTeam,
      if (reqTeam != null) 'teamIds': [reqTeam],
      'status': 'active',
      'isActive': true,
      'isRoleApproved': true,
      'requestedRole': FieldValue.delete(),
      'requestedDepartmentId': FieldValue.delete(),
      'requestedTeamId': FieldValue.delete(),
      'requestedRoleReason': FieldValue.delete(),
      'pendingRole': FieldValue.delete(),
      'pendingDepartment': FieldValue.delete(),
    });
    await loadUsers();
  }

  // ── Reject pending request ────────────────────────────────────────────
  Future<void> rejectUser(String uid) async {
    _assertActor();
    await _db.collection('users').doc(uid).update({
      'status': 'disabled',
      'isRoleApproved': false,
      'requestedRole': FieldValue.delete(),
      'requestedDepartmentId': FieldValue.delete(),
      'requestedTeamId': FieldValue.delete(),
      'requestedRoleReason': FieldValue.delete(),
      'pendingRole': FieldValue.delete(),
      'pendingDepartment': FieldValue.delete(),
    });
    await loadUsers();
  }

  // ── Soft delete ───────────────────────────────────────────────────────
  Future<void> disableUser(String uid) async {
    _assertActor();
    if (_actor!.id == uid) throw Exception('Không thể vô hiệu hoá chính mình');
    final target = _findLocal(uid);
    if (target != null && target.role == UserRole.admin) {
      throw Exception('Không thể vô hiệu hoá Admin khác');
    }
    await _db.collection('users').doc(uid).update({
      'status': 'disabled',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _patchLocal(uid, (u) => u.copyWith(status: 'disabled', isActive: false));
  }

  // ── Hard delete (Admin only) ──────────────────────────────────────────
  Future<void> hardDeleteUser(String uid) async {
    if (_actor == null || !_actor!.isAdmin) {
      throw Exception('Chỉ Admin mới có thể xoá vĩnh viễn');
    }
    if (_actor!.id == uid) throw Exception('Không thể xoá chính mình');
    await _db.collection('users').doc(uid).delete();
    _users.removeWhere((u) => u.id == uid);
    notifyListeners();
  }

  // ── Fetch teams for a department (for UI selectors) ───────────────────
  Future<List<TeamModel>> fetchTeamsForDepartment(String deptId) async {
    final snap = await _db
        .collection('teams')
        .where('departmentId', isEqualTo: deptId)
        .where('isActive', isEqualTo: true)
        .get();
    final teams = snap.docs.map((d) {
      return TeamModel.fromMap(d.data(), d.id);
    }).toList();
    teams.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      return a.name.compareTo(b.name);
    });
    return teams;
  }

  // ── Private helpers ───────────────────────────────────────────────────
  void _assertActor() {
    if (_actor == null) throw Exception('Actor chưa được khởi tạo');
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  UserModel? _findLocal(String uid) {
    try {
      return _users.firstWhere((u) => u.id == uid);
    } catch (_) {
      return null;
    }
  }

  void _patchLocal(String uid, UserModel Function(UserModel) patch) {
    final idx = _users.indexWhere((u) => u.id == uid);
    if (idx >= 0) {
      _users[idx] = patch(_users[idx]);
      notifyListeners();
    }
  }

  /// Self-heal: if teamId exists but teamIds is empty or mismatched, sync locally
  /// and trigger a silent background Firestore write to persist the fix.
  UserModel _healTeamFields(UserModel u, Map<String, dynamic> raw) {
    final teamId = u.teamId;
    if (teamId == null || teamId.isEmpty) return u;
    final teamIds = u.teamIds;
    final needsHeal = teamIds.isEmpty || teamIds.first != teamId;
    if (!needsHeal) return u;

    debugPrint('[UMP] Self-healing teamIds for uid=${u.id}: teamId=$teamId');
    // Background async fix (fire-and-forget — no await)
    _db.collection('users').doc(u.id).update({
      'teamIds': [teamId],
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint('[UMP] heal write error: $e'));

    return u.copyWith(teamIds: [teamId]);
  }

  Future<TeamModel?> _fetchFirstTeam(String deptId) async {
    final teams = await fetchTeamsForDepartment(deptId);
    // Prefer non-general with lowest order
    final nonGeneral = teams.where((t) => !t.isGeneralTeam).toList();
    if (nonGeneral.isNotEmpty) return nonGeneral.first;
    if (teams.isNotEmpty) return teams.first;
    return null;
  }

  String _mapDeptIdToName(String deptId) {
    // departmentId == departmentName in current schema
    return deptId;
  }
}
