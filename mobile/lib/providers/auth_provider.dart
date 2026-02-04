import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../utils/room_setup_helper.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;

  // Kiểm tra xem user có cần chọn vai trò không
  bool get needsRoleSelection =>
      _userModel != null &&
      !_userModel!.isAdmin && // Admin không cần chọn vai trò
      !_userModel!.isRoleApproved &&
      _userModel!.pendingRole == null;

  AuthProvider() {
    // Lắng nghe thay đổi trạng thái đăng nhập
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserModel();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Load thông tin user từ Firestore
  Future<void> _loadUserModel() async {
    try {
      if (_user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userModel =
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
    } catch (e) {
      print('Error loading user model: $e');
    }
  }

  // Đăng ký tài khoản mới - TỐI ƯU SIÊU TỐC
  Future<void> signup(String email, String password,
      {String? displayName}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Bước 1: Tạo tài khoản trên Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật display name nếu có
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      // Bước 2: Tạo user profile trong Firestore (CHỈ NẾU CHƯA CÓ)
      if (userCredential.user != null) {
        await _createUserProfileIfNotExists(
          userCredential.user!,
          displayName: displayName,
        );
      }

      _user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Đã xảy ra lỗi';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email này đã được sử dụng';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        case 'weak-password':
          errorMessage = 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Đăng ký bằng email/password chưa được bật';
          break;
        default:
          errorMessage = e.message ?? 'Lỗi đăng ký';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đăng nhập
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Đăng nhập với Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Tạo hoặc cập nhật user profile
      if (userCredential.user != null) {
        await _createUserProfileIfNotExists(userCredential.user!);

        // Cập nhật lastLoginAt
        final userDocRef =
            _firestore.collection('users').doc(userCredential.user!.uid);
        await userDocRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // Setup rooms nếu user là admin và chưa có phòng
        await _setupRoomsIfNeeded();
      }

      _user = userCredential.user;
      await _loadUserModel();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Đã xảy ra lỗi';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Không tìm thấy tài khoản với email này';
          break;
        case 'wrong-password':
          errorMessage = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          errorMessage = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'too-many-requests':
          errorMessage = 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau';
          break;
        default:
          errorMessage = e.message ?? 'Lỗi đăng nhập';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đăng nhập với Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Bắt đầu quá trình đăng nhập Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Nếu người dùng hủy đăng nhập
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Lấy thông tin xác thực từ Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase với credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Tạo hoặc cập nhật user profile
      if (userCredential.user != null) {
        await _createUserProfileIfNotExists(userCredential.user!);

        // Cập nhật thông tin mới nhất
        final userDoc =
            _firestore.collection('users').doc(userCredential.user!.uid);
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'photoURL': userCredential.user!.photoURL,
        });

        // Setup rooms nếu user là admin và chưa có phòng
        await _setupRoomsIfNeeded();
      }

      _user = userCredential.user;
      await _loadUserModel();
    } catch (e) {
      throw Exception('Lỗi đăng nhập với Google: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// TẠO USER PROFILE THÔNG MINH - KHÔNG OVERRIDE ROLES ĐÃ SETUP
  Future<void> _createUserProfileIfNotExists(User user,
      {String? displayName}) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (docSnapshot.exists) {
        // User đã tồn tại -> KHÔNG thay đổi gì, giữ nguyên setup từ Firebase Console
        print('✅ User profile đã tồn tại - giữ nguyên setup hiện tại');
        return;
      }

      // User chưa tồn tại -> Tạo mới với role default
      print('🆕 Tạo user profile mới với role mặc định');

      await userDocRef.set({
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'Người dùng',
        'photoURL': user.photoURL,
        'role': 'guest', // Role mặc định
        'isRoleApproved': false, // Cần được phê duyệt
        'pendingRole': null,
        'pendingDepartment': null,
        'departmentId': null,
        'departmentName': null,
        'teamIds': [],
        'teamNames': [],
        'managerId': null,
        'managerName': null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'additionalData': {
          'createdBy': 'system_auto',
          'registrationMethod': user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'email',
        },
      });

      print('✅ Đã tạo user profile với role guest');
    } catch (e) {
      print('❌ Lỗi tạo user profile: $e');
      // Không throw error để không làm gián đoạn quá trình đăng nhập
    }
  }

  /// Setup rooms nếu user là admin và chưa có phòng
  Future<void> _setupRoomsIfNeeded() async {
    try {
      // Chờ một chút để userModel được load
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadUserModel();

      if (_userModel != null && _userModel!.isAdmin) {
        // Kiểm tra đã có phòng chưa
        final QuerySnapshot roomSnapshot =
            await _firestore.collection('rooms').limit(1).get();

        if (roomSnapshot.docs.isEmpty) {
          print(
              '🏗️ Admin đăng nhập lần đầu - thiết lập phòng họp mặc định...');

          // Setup rooms cho admin
          await RoomSetupHelper.setupDefaultRooms(_userModel!);

          print('✅ Đã setup phòng họp mặc định cho admin');
        }
      }
    } catch (e) {
      print('⚠️ Lỗi setup rooms: $e');
      // Không throw error để không làm gián đoạn đăng nhập
    }
  }

  /// Tạo user và gán vai trò (chỉ Admin)
  Future<void> createUserWithRole(String email, String displayName,
      UserRole role, String? departmentId) async {
    try {
      if (_userModel == null || !_userModel!.isAdmin) {
        throw Exception('Chỉ Admin mới có quyền tạo user');
      }

      // Tạo user document trong Firestore (không tạo auth account)
      final userDoc = _firestore.collection('users').doc();

      await userDoc.set({
        'email': email,
        'displayName': displayName,
        'photoURL': null,
        'role': role.toString().split('.').last,
        'isRoleApproved': true, // Admin tạo -> tự động approve
        'pendingRole': null,
        'pendingDepartment': null,
        'departmentId': departmentId,
        'departmentName': null, // Sẽ được cập nhật sau
        'teamIds': [],
        'teamNames': [],
        'managerId': null,
        'managerName': null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
        'additionalData': {
          'createdBy': _userModel!.id,
          'createdByAdmin': true,
          'needsPasswordSetup': true,
        },
      });

      print('✅ Đã tạo user $displayName với role ${role.toString()}');
    } catch (e) {
      throw Exception('Lỗi tạo user: $e');
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();

      // Clear tất cả user data
      _user = null;
      _userModel = null;

      print('✅ Đăng xuất thành công');
    } catch (e) {
      print('❌ Lỗi đăng xuất: $e');
      throw Exception('Lỗi đăng xuất: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đặt lại mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Đã xảy ra lỗi';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Không tìm thấy tài khoản với email này';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        default:
          errorMessage = e.message ?? 'Lỗi gửi email đặt lại mật khẩu';
      }

      throw Exception(errorMessage);
    }
  }

  // Cập nhật thông tin người dùng
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(displayName);
        if (photoURL != null) {
          await _user!.updatePhotoURL(photoURL);
        }

        // Cập nhật vào Firestore
        await _firestore.collection('users').doc(_user!.uid).update({
          if (displayName != null) 'displayName': displayName,
          if (photoURL != null) 'photoURL': photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        notifyListeners();
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin: $e');
    }
  }

  // Lấy thông tin người dùng từ Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(_user!.uid).get();
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin người dùng: $e');
    }
  }

  // Lấy người dùng (Admin xem tất cả, Director chỉ xem phòng ban mình)
  Future<List<UserModel>> getAllUsers() async {
    try {
      if (_userModel == null ||
          (!_userModel!.isAdmin && !_userModel!.isDirector)) {
        throw Exception('Bạn không có quyền truy cập danh sách người dùng');
      }

      QuerySnapshot snapshot;

      if (_userModel!.isAdmin) {
        // Admin xem tất cả users
        snapshot = await _firestore.collection('users').get();
        print('🔑 Admin - Lấy tất cả ${snapshot.docs.length} users');
      } else if (_userModel!.isDirector) {
        // Director chỉ xem users trong department mình
        if (_userModel!.departmentId == null) {
          throw Exception('Director chưa được phân phòng ban');
        }
        snapshot = await _firestore
            .collection('users')
            .where('departmentId', isEqualTo: _userModel!.departmentId)
            .get();
        print(
            '📂 Director - Lấy ${snapshot.docs.length} users trong department: ${_userModel!.departmentId}');
      } else {
        // Fallback: không có quyền
        return <UserModel>[];
      }

      if (snapshot.docs.isEmpty) {
        return <UserModel>[]; // Trả về mảng rỗng
      }

      List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final user = UserModel.fromMap(data, doc.id);
            users.add(user);
          }
        } catch (e) {
          print('Lỗi parse user ${doc.id}: $e');
          // Bỏ qua user có lỗi, tiếp tục với user khác
          continue;
        }
      }

      return users;
    } catch (e) {
      print('Lỗi getAllUsers: $e');
      throw Exception('Lỗi lấy danh sách người dùng: ${e.toString()}');
    }
  }

  // Thay đổi vai trò người dùng (Admin và Director)
  Future<void> changeUserRole(String userId, UserRole newRole) async {
    try {
      if (_userModel == null ||
          (!_userModel!.isAdmin && !_userModel!.isDirector)) {
        throw Exception('Bạn không có quyền thay đổi vai trò');
      }

      // Director không được tạo Admin
      if (_userModel!.isDirector &&
          !_userModel!.isAdmin &&
          newRole == UserRole.admin) {
        throw Exception('Director không thể tạo Admin');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Lỗi thay đổi vai trò: $e');
    }
  }

  // Lấy danh sách user chờ duyệt vai trò
  Future<List<UserModel>> getPendingUsers() async {
    if (_userModel == null ||
        (!_userModel!.isAdmin && !_userModel!.isDirector)) {
      throw Exception('Bạn không có quyền truy cập');
    }

    Query query = _firestore
        .collection('users')
        .where('isRoleApproved', isEqualTo: false)
        .where('pendingRole', isNotEqualTo: null);

    // Nếu là Director, chỉ lấy users trong department mình
    if (_userModel!.isDirector && !_userModel!.isAdmin) {
      if (_userModel!.departmentId != null) {
        query = query.where('pendingDepartment',
            isEqualTo: _userModel!.departmentId);
      } else {
        // Nếu Director chưa có department, trả về empty
        return [];
      }
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs
        .map((doc) =>
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Lấy tất cả users trong department (cho Director)
  Future<List<UserModel>> getUsersInDepartment([String? departmentId]) async {
    if (_userModel == null ||
        (!_userModel!.isAdmin && !_userModel!.isDirector)) {
      throw Exception('Bạn không có quyền truy cập');
    }

    // Sử dụng departmentId được truyền vào hoặc department của user hiện tại
    final targetDepartmentId = departmentId ?? _userModel!.departmentId;

    if (targetDepartmentId == null) {
      throw Exception('Không xác định được department');
    }

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('departmentId', isEqualTo: targetDepartmentId)
        .get();

    List<UserModel> users = [];
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final user = UserModel.fromMap(data, doc.id);
          users.add(user);
        }
      } catch (e) {
        print('Lỗi parse user ${doc.id}: $e');
        continue;
      }
    }

    return users;
  }

  // Delete user (Admin can delete any, Director deleted only in their department)
  Future<void> deleteUser(String userId) async {
    if (_userModel == null ||
        (!_userModel!.isAdmin && !_userModel!.isDirector)) {
      throw Exception('Bạn không có quyền xóa user');
    }

    // Kiểm tra user tồn tại và trong department
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User không tồn tại');
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final userDepartmentId = userData['departmentId'];

    // Nếu là Director, chỉ được xóa user trong department mình
    if (_userModel!.isDirector && !_userModel!.isAdmin) {
      if (userDepartmentId != _userModel!.departmentId) {
        throw Exception('Bạn chỉ có thể xóa user trong department của mình');
      }
    }

    // Xóa user
    await _firestore.collection('users').doc(userId).delete();
    print('✅ Đã xóa user: ${userData['email']}');
  }

  // Director thay đổi role của user trong department mình
  Future<void> changeUserRoleInDepartment(
      String userId, UserRole newRole) async {
    if (_userModel == null ||
        (!_userModel!.isAdmin && !_userModel!.isDirector)) {
      throw Exception('Bạn không có quyền thay đổi vai trò');
    }

    // Kiểm tra user tồn tại và trong department
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User không tồn tại');
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final userDepartmentId = userData['departmentId'];

    // Nếu là Director, chỉ được sửa user trong department mình
    if (_userModel!.isDirector && !_userModel!.isAdmin) {
      if (userDepartmentId != _userModel!.departmentId) {
        throw Exception('Bạn chỉ có thể sửa user trong department của mình');
      }
      // Director không được promote thành Admin
      if (newRole == UserRole.admin) {
        throw Exception('Director không thể tạo Admin');
      }
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print(
        '✅ Đã thay đổi role của ${userData['email']} thành ${newRole.toString()}');
    notifyListeners();
  }

  // Admin và Director duyệt vai trò
  Future<void> approveUserRole(String userId) async {
    // DEBUG: Kiểm tra user role hiện tại
    print('🔍 DEBUG - Current user role: ${_userModel?.role}');
    print('🔍 DEBUG - isAdmin: ${_userModel?.isAdmin}');
    print('🔍 DEBUG - isDirector: ${_userModel?.isDirector}');
    print('🔍 DEBUG - User ID: ${_userModel?.id}');
    print('🔍 DEBUG - Approving user: $userId');

    if (_userModel == null ||
        (!_userModel!.isAdmin && !_userModel!.isDirector)) {
      throw Exception('Bạn không có quyền phê duyệt');
    }
    final userDoc = _firestore.collection('users').doc(userId);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) throw Exception('User không tồn tại');
    final data = docSnapshot.data() as Map<String, dynamic>;
    final pendingRole = data['pendingRole'];
    final pendingDepartment = data['pendingDepartment'];
    if (pendingRole == null) throw Exception('Không có vai trò chờ duyệt');

    // Map departmentId thành departmentName
    String? departmentName = _mapDepartmentIdToName(pendingDepartment);

    await userDoc.update({
      'role': pendingRole,
      'departmentId': pendingDepartment,
      'departmentName': departmentName, // ← Thêm departmentName
      'pendingRole': null,
      'pendingDepartment': null,
      'isRoleApproved': true,
    });
  }

  // Admin và Director từ chối vai trò
  Future<void> rejectUserRole(String userId) async {
    if (_userModel == null ||
        (!_userModel!.isAdmin && !_userModel!.isDirector)) {
      throw Exception('Bạn không có quyền phê duyệt');
    }
    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.update({
      'pendingRole': null,
      'pendingDepartment': null,
      'role': 'guest',
      'isRoleApproved': true,
    });
  }

  /// Gửi yêu cầu vai trò và phòng ban (cho role selection screen)
  Future<void> submitRoleAndDepartment(
      UserRole role, String? departmentId, {String? fullName}) async {
    try {
      if (_user == null) throw Exception('Chưa đăng nhập');
      
      // Validate department is required (safety guard against UI bypass)
      if (departmentId == null || departmentId.isEmpty) {
        throw Exception('Vui lòng chọn phòng ban');
      }

      final updateData = {
        'pendingRole': role.toString().split('.').last,
        'pendingDepartment': departmentId,
        'isRoleApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add displayName if provided
      if (fullName != null && fullName.isNotEmpty) {
        updateData['displayName'] = fullName;
      }

      await _firestore.collection('users').doc(_user!.uid).update(updateData);

      // Reload user model
      await _loadUserModel();
      notifyListeners();

      print('✅ Đã gửi yêu cầu vai trò: ${role.toString()}');
    } catch (e) {
      throw Exception('Lỗi gửi yêu cầu vai trò: $e');
    }
  }

  /// Update basic profile info (avatar, full name) - applies immediately for all users
  Future<void> updateBasicInfo(String fullName, {String? photoURL}) async {
    try {
      if (_user == null) throw Exception('Chưa đăng nhập');

      final updateData = {
        'displayName': fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoURL != null) {
        updateData['photoURL'] = photoURL;
      }

      await _firestore.collection('users').doc(_user!.uid).update(updateData);

      // Reload user model
      await _loadUserModel();
      notifyListeners();

      print('✅ Đã cập nhật thông tin cơ bản');
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin: $e');
    }
  }

  /// Create role/department change request (for regular users) - requires approval
  Future<void> createRoleChangeRequest(UserRole newRole, String? newDepartment) async {
    try {
      if (_user == null) throw Exception('Chưa đăng nhập');
      if (_userModel == null) throw Exception('Không tìm thấy thông tin user');

      // Check if user is admin (shouldn't use this method)
      if (_userModel!.isAdmin) {
        throw Exception('Admin nên dùng updateRoleAndDepartment thay vì tạo request');
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        'pendingRole': newRole.toString().split('.').last,
        'pendingDepartment': newDepartment,
        'requestedAt': FieldValue.serverTimestamp(),
        'isRoleApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload user model
      await _loadUserModel();
      notifyListeners();

      print('✅ Đã tạo yêu cầu thay đổi vai trò/phòng ban');
    } catch (e) {
      throw Exception('Lỗi tạo yêu cầu: $e');
    }
  }

  /// Update role/department immediately (for Global Admin only) - no approval needed
  Future<void> updateRoleAndDepartmentImmediate(UserRole newRole, String? newDepartment) async {
    try {
      if (_user == null) throw Exception('Chưa đăng nhập');
      if (_userModel == null) throw Exception('Không tìm thấy thông tin user');

      // Only admin can use this method
      if (!_userModel!.isAdmin) {
        throw Exception('Chỉ Admin mới có thể cập nhật vai trò trực tiếp');
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        'role': newRole.toString().split('.').last,
        'departmentId': newDepartment,
        'isRoleApproved': true,
        // Clear any pending requests
        'pendingRole': null,
        'pendingDepartment': null,
        'requestedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload user model
      await _loadUserModel();
      notifyListeners();

      print('✅ Đã cập nhật vai trò/phòng ban (Admin)');
    } catch (e) {
      throw Exception('Lỗi cập nhật vai trò: $e');
    }
  }

  /// Check if user has pending role/department change request
  bool hasPendingRoleChange() {
    return _userModel?.pendingRole != null || _userModel?.pendingDepartment != null;
  }

  /// Check if current user is Global Admin
  bool isGlobalAdmin() {
    return _userModel?.isAdmin == true;
  }

  /// Hướng dẫn tạo Super Admin thủ công (không tự động tạo)
  Future<void> createFirstSuperAdmin() async {
    try {
      print('📝 HƯỚNG DẪN TẠO SUPER ADMIN THỦ CÔNG:');
      print('');
      print('🔥 BƯỚC 1: TẠO USER TRÊN FIREBASE CONSOLE');
      print('1. Mở Firebase Console: https://console.firebase.google.com');
      print('2. Chọn project của bạn');
      print('3. Vào Authentication > Users');
      print('4. Nhấn "Add user" và nhập:');
      print('   📧 Email: admin@meetingapp.com');
      print('   🔑 Password: admin123456');
      print('');
      print('🎯 BƯỚC 2: TẠO USER PROFILE TRÊN FIRESTORE');
      print('1. Vào Firestore Database > users collection');
      print('2. Tạo document với UID giống User vừa tạo');
      print('3. Nhập data:');
      print('   {');
      print('     "email": "admin@meetingapp.com",');
      print('     "displayName": "Super Admin",');
      print('     "role": "admin",');
      print('     "isRoleApproved": true,');
      print('     "isActive": true,');
      print('     "createdAt": [timestamp],');
      print('     "departmentId": "SYSTEM"');
      print('   }');
      print('');
      print('✨ BƯỚC 3: ĐĂNG NHẬP VÀO APP');
      print('- Email: admin@meetingapp.com');
      print('- Password: admin123456');
      print('');
      print('⚠️ LƯU Ý: App sẽ KHÔNG tự động tạo admin nữa!');
      print('Bạn cần setup thủ công trên Firebase Console.');

      // Không tạo admin tự động nữa
      throw Exception(
          'Vui lòng setup Super Admin thủ công theo hướng dẫn trên console');
    } catch (e) {
      print('❌ $e');
      rethrow;
    }
  }

  /// Map departmentId thành tên phòng ban hiển thị
  String? _mapDepartmentIdToName(String? departmentId) {
    if (departmentId == null) return null;

    // Map các department IDs thành tên hiển thị
    const departmentMap = {
      'Công nghệ thông tin': 'Công nghệ thông tin',
      'Nhân sự': 'Nhân sự',
      'Marketing': 'Marketing',
      'Kế toán': 'Kế toán',
      'Kinh doanh': 'Kinh doanh',
      'Vận hành': 'Vận hành',
      'Khác': 'Khác',
      'SYSTEM': 'Hệ thống', // Cho Admin
      'CNTT': 'Công nghệ thông tin', // Alias
      'HR': 'Nhân sự', // Alias
      'MARKETING': 'Marketing', // Alias
      'ACCOUNTING': 'Kế toán', // Alias
      'BUSINESS': 'Kinh doanh', // Alias
      'OPERATIONS': 'Vận hành', // Alias
    };

    return departmentMap[departmentId] ??
        departmentId; // Fallback to original ID
  }
}
