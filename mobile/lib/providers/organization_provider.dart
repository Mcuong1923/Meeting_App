import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/department_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/meeting_model.dart';

class OrganizationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Department related
  List<DepartmentModel> _departments = [];
  List<DepartmentModel> _availableDepartments = [];

  // Team related
  List<TeamModel> _teams = [];
  List<TeamModel> _availableTeams = [];

  // User related
  List<UserModel> _departmentUsers = [];
  List<UserModel> _teamUsers = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingTeams = false;
  String? _error;

  // Cache
  bool _departmentsLoaded = false;
  DateTime? _lastLoadTime;
  String? _lastTeamsDepartmentId; // Cache key for teams

  // Getters
  List<DepartmentModel> get departments => _departments;
  List<DepartmentModel> get availableDepartments => _availableDepartments;
  List<TeamModel> get teams => _teams;
  List<TeamModel> get availableTeams => _availableTeams;
  List<UserModel> get departmentUsers => _departmentUsers;
  List<UserModel> get teamUsers => _teamUsers;
  bool get isLoading => _isLoading;
  bool get isLoadingTeams => _isLoadingTeams;
  String? get error => _error;

  /// Load tất cả departments với cache
  Future<void> loadDepartments({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _departmentsLoaded && _lastLoadTime != null) {
      final cacheAge = DateTime.now().difference(_lastLoadTime!);
      if (cacheAge.inMinutes < 5) {
        // Cache for 5 minutes
        return;
      }
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load từ predefined departments hoặc database
      _departments = await _loadDepartmentsFromPredefinedList();
      _availableDepartments =
          _departments.where((dept) => dept.isActive).toList();

      // Giả lập lấy từ Firestore, nếu rỗng thì thêm mock data
      if (_availableDepartments.isEmpty) {
        _availableDepartments = [
          DepartmentModel(
            id: 'dept1',
            name: 'Phòng Kỹ thuật',
            description: 'Phòng phát triển sản phẩm',
            memberIds: ['user1', 'user2', 'user3'],
            teamIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          DepartmentModel(
            id: 'dept2',
            name: 'Phòng Nhân sự',
            description: 'Quản lý nhân sự',
            memberIds: ['user4', 'user5'],
            teamIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      }
      notifyListeners();

      // Update cache
      _departmentsLoaded = true;
      _lastLoadTime = DateTime.now();

      print('✅ Loaded ${_departments.length} departments');
    } catch (e) {
      _error = 'Lỗi tải danh sách phòng ban: $e';
      print('❌ Error loading departments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load departments từ predefined list với optimization
  Future<List<DepartmentModel>> _loadDepartmentsFromPredefinedList() async {
    final predefinedDepartments = [
      'Công nghệ thông tin',
      'Nhân sự',
      'Marketing',
      'Kế toán',
      'Kinh doanh',
      'Vận hành',
      'Khác'
    ];

    try {
      // 🚀 Optimization: Load tất cả users một lần thay vì query từng department
      QuerySnapshot allUsersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      // Group users theo departmentId
      Map<String, List<DocumentSnapshot>> usersByDepartment = {};
      Map<String, DocumentSnapshot> managersByDepartment = {};

      for (var doc in allUsersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final departmentId = userData['departmentId']?.toString() ?? 'Khác';
        final role = userData['role']?.toString() ?? 'guest';

        // Group users
        if (!usersByDepartment.containsKey(departmentId)) {
          usersByDepartment[departmentId] = [];
        }
        usersByDepartment[departmentId]!.add(doc);

        // Tìm manager cho department
        if ((role == 'manager' || role == 'director') &&
            !managersByDepartment.containsKey(departmentId)) {
          managersByDepartment[departmentId] = doc;
        }
      }

      // Tạo departments từ grouped data
      List<DepartmentModel> departments = [];

      for (String deptName in predefinedDepartments) {
        final users = usersByDepartment[deptName] ?? [];
        final manager = managersByDepartment[deptName];

        List<String> memberIds = users.map((doc) => doc.id).toList();

        String? managerId;
        String? managerName;
        if (manager != null) {
          managerId = manager.id;
          final managerData = manager.data() as Map<String, dynamic>;
          managerName = managerData['displayName'];
        }

        departments.add(DepartmentModel(
          id: deptName,
          name: deptName,
          description: 'Phòng ban $deptName',
          managerId: managerId,
          managerName: managerName,
          memberIds: memberIds,
          teamIds: [], // Sẽ được cập nhật sau
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      print(
          '✅ Loaded ${departments.length} departments with ${allUsersSnapshot.docs.length} total users');
      return departments;
    } catch (e) {
      print('❌ Error loading departments: $e');

      // 🔧 Fallback: Trả về departments cơ bản nếu không có quyền truy cập
      if (e.toString().contains('permission-denied')) {
        print(
            '⚠️ Permission denied - returning basic departments without member count');
        return predefinedDepartments.map((deptName) {
          return DepartmentModel(
            id: deptName,
            name: deptName,
            description: 'Phòng ban $deptName',
            managerId: null,
            managerName: null,
            memberIds: [], // Empty vì không có quyền truy cập
            teamIds: [],
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      }

      return [];
    }
  }

  /// Dùng cache sẵn có từ màn hình – không bật loading spinner
  void setAvailableTeamsFromCache(List<TeamModel> cachedTeams, String departmentId) {
    _availableTeams = cachedTeams;
    _lastTeamsDepartmentId = departmentId;
    _isLoadingTeams = false;
    notifyListeners();
  }

  /// Load teams theo department từ Firestore teams collection
  Future<void> loadTeamsByDepartment(String departmentId) async {
    // Skip if already loaded for this department (but NOT if only fallback general team)
    if (_lastTeamsDepartmentId == departmentId && _availableTeams.length > 1) {
      return;
    }

    try {
      _isLoadingTeams = true;
      _error = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('teams')
          .where('departmentId', isEqualTo: departmentId)
          .where('isActive', isEqualTo: true)
          // TODO: add .orderBy('order') once Firestore composite index is ready
          .get();

      _teams = snapshot.docs.map((doc) {
        return TeamModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort: order first, then alphabetically
      _teams.sort((a, b) {
        if (a.order != b.order) return a.order.compareTo(b.order);
        return a.name.compareTo(b.name);
      });

      _availableTeams = _teams;
      _lastTeamsDepartmentId = departmentId;

      print('✅ Loaded ${_teams.length} teams for department: $departmentId');
    } catch (e) {
      _error = 'Lỗi tải danh sách team: $e';
      print('❌ Error loading teams: $e');

      // Fallback: tạo default team nếu không load được
      _teams = [
        TeamModel(
          id: '${departmentId}__general',
          name: 'Chung (Chưa phân team)',
          description: 'Team mặc định',
          departmentId: departmentId,
          departmentName: departmentId,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      _availableTeams = _teams;
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  /// Load users theo department
  Future<void> loadDepartmentUsers(String departmentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('departmentId', isEqualTo: departmentId)
          .where('isActive', isEqualTo: true)
          .get();

      _departmentUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort theo role hierarchy để hiển thị đẹp hơn
      _departmentUsers.sort((a, b) {
        const roleOrder = {
          UserRole.admin: 1,
          UserRole.director: 2,
          UserRole.manager: 3,
          UserRole.employee: 4,
          UserRole.guest: 5,
        };
        int roleComparison =
            (roleOrder[a.role] ?? 6).compareTo(roleOrder[b.role] ?? 6);
        if (roleComparison != 0) return roleComparison;
        return a.displayName.compareTo(b.displayName);
      });

      print(
          '✅ Loaded ${_departmentUsers.length} users for department: $departmentId');
    } catch (e) {
      _error = 'Lỗi tải danh sách nhân viên: $e';
      print('❌ Error loading department users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load users theo team
  Future<void> loadTeamUsers(String teamId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Query users by teamId field
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('teamId', isEqualTo: teamId)
          .where('isActive', isEqualTo: true)
          .get();

      _teamUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      print('✅ Loaded ${_teamUsers.length} users for team: $teamId');
    } catch (e) {
      _error = 'Lỗi tải danh sách thành viên team: $e';
      print('❌ Error loading team users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get suggested participants based on meeting type
  Future<List<UserModel>> getSuggestedParticipants(MeetingType meetingType,
      {String? departmentId, String? teamId, String? currentUserId}) async {
    try {
      List<UserModel> suggestedUsers = [];

      switch (meetingType) {
        case MeetingType.department:
          if (departmentId != null) {
            await loadDepartmentUsers(departmentId);
            suggestedUsers = _departmentUsers;
          }
          break;

        case MeetingType.team:
          if (teamId != null) {
            await loadTeamUsers(teamId);
            suggestedUsers = _teamUsers;
          }
          break;

        case MeetingType.company:
          // Load tất cả users trong company
          QuerySnapshot snapshot = await _firestore
              .collection('users')
              .where('isActive', isEqualTo: true)
              .get();

          suggestedUsers = snapshot.docs.map((doc) {
            return UserModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
          break;

        case MeetingType.personal:
          // Không auto-suggest, để user tự chọn
          suggestedUsers = [];
          break;
      }

      // Loại bỏ current user khỏi danh sách suggestions
      if (currentUserId != null) {
        suggestedUsers.removeWhere((user) => user.id == currentUserId);
      }

      print(
          '✅ Generated ${suggestedUsers.length} suggested participants for ${meetingType.toString()}');
      return suggestedUsers;
    } catch (e) {
      print('❌ Error getting suggested participants: $e');
      return [];
    }
  }

  /// Clear data
  void clearData() {
    _departments.clear();
    _availableDepartments.clear();
    _teams.clear();
    _availableTeams.clear();
    _departmentUsers.clear();
    _teamUsers.clear();
    _lastTeamsDepartmentId = null;
    _error = null;
    notifyListeners();
  }

  /// Get department by ID
  DepartmentModel? getDepartmentById(String departmentId) {
    try {
      return _departments.firstWhere((dept) => dept.id == departmentId);
    } catch (e) {
      return null;
    }
  }

  /// Get team by ID
  TeamModel? getTeamById(String teamId) {
    try {
      return _teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  /// Get display name for a teamId (for UI fallback)
  String getTeamDisplayName(String? teamId) {
    if (teamId == null || teamId.isEmpty) return 'Chưa phân team';
    final team = getTeamById(teamId);
    if (team != null) return team.name;
    // Fallback: if teamId ends with __general, show default name
    if (teamId.endsWith('__general')) return 'Chung (Chưa phân team)';
    return teamId;
  }
}
