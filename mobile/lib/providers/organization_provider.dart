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
  String? _error;

  // Cache
  bool _departmentsLoaded = false;
  DateTime? _lastLoadTime;

  // Getters
  List<DepartmentModel> get departments => _departments;
  List<DepartmentModel> get availableDepartments => _availableDepartments;
  List<TeamModel> get teams => _teams;
  List<TeamModel> get availableTeams => _availableTeams;
  List<UserModel> get departmentUsers => _departmentUsers;
  List<UserModel> get teamUsers => _teamUsers;
  bool get isLoading => _isLoading;
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

  /// Load teams theo department
  Future<void> loadTeamsByDepartment(String departmentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load teams từ user data (vì hiện tại teams được lưu trong user.teamIds)
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('departmentId', isEqualTo: departmentId)
          .get();

      Set<String> teamNamesSet = {};
      Map<String, List<String>> teamMembers = {};

      for (var doc in userSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final teamNames = List<String>.from(userData['teamNames'] ?? []);
        final userId = doc.id;
        final userName = userData['displayName'] ?? 'Unknown';

        for (String teamName in teamNames) {
          teamNamesSet.add(teamName);
          if (!teamMembers.containsKey(teamName)) {
            teamMembers[teamName] = [];
          }
          teamMembers[teamName]!.add(userId);
        }
      }

      // Tạo TeamModel từ data
      _teams = teamNamesSet.map((teamName) {
        List<String> memberIds = teamMembers[teamName] ?? [];

        // Tìm team leader
        String? leaderId;
        String? leaderName;
        for (String memberId in memberIds) {
          var userDoc =
              userSnapshot.docs.firstWhere((doc) => doc.id == memberId);
          final userData = userDoc.data() as Map<String, dynamic>;
          if (userData['role'] == 'manager') {
            leaderId = memberId;
            leaderName = userData['displayName'];
            break;
          }
        }

        return TeamModel(
          id: '${departmentId}_$teamName',
          name: teamName,
          description: 'Team $teamName thuộc $departmentId',
          departmentId: departmentId,
          departmentName: departmentId,
          leaderId: leaderId,
          leaderName: leaderName,
          memberIds: memberIds,
          memberNames: [], // Sẽ được load sau nếu cần
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      _availableTeams = _teams.where((team) => team.isActive).toList();

      print('✅ Loaded ${_teams.length} teams for department: $departmentId');
    } catch (e) {
      _error = 'Lỗi tải danh sách team: $e';
      print('❌ Error loading teams: $e');
    } finally {
      _isLoading = false;
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

      // Parse teamId để lấy department và team name
      final parts = teamId.split('_');
      if (parts.length < 2) {
        throw Exception('Invalid team ID format');
      }

      final departmentId = parts[0];
      final teamName = parts.sublist(1).join('_');

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('departmentId', isEqualTo: departmentId)
          .where('teamNames', arrayContains: teamName)
          .where('isActive', isEqualTo: true)
          .get();

      _teamUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      print('✅ Loaded ${_teamUsers.length} users for team: $teamName');
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
}
