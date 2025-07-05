import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

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

      // Bước 1: Chỉ tạo tài khoản trên Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật display name nếu có
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      // Bước 2: Bỏ qua việc tạo hồ sơ ở đây.
      // Việc này sẽ được thực hiện khi người dùng đăng nhập lần đầu.

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

      // [LOGIC MỚI] Kiểm tra và tạo hồ sơ nếu cần
      if (userCredential.user != null) {
        final userDocRef =
            _firestore.collection('users').doc(userCredential.user!.uid);
        final docSnapshot = await userDocRef.get();

        if (!docSnapshot.exists) {
          // Lần đăng nhập đầu tiên -> Tạo hồ sơ với role mặc định là guest, chưa được duyệt
          await userDocRef.set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName ?? '',
            'role': UserRole.guest.toString().split('.').last,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'isRoleApproved': false, // Chưa được duyệt vai trò
            'pendingRole': null,
            'pendingDepartment': null,
          });
        } else {
          // Các lần đăng nhập sau -> Cập nhật không cần chờ
          userDocRef.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          }).catchError((e) {
            print("Lỗi cập nhật lastLoginAt: $e");
          });
        }
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

      // [KHÔI PHỤC] Lưu thông tin người dùng vào Firestore nếu là người dùng mới
      if (userCredential.user != null) {
        final userDoc =
            _firestore.collection('users').doc(userCredential.user!.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'role': UserRole.guest.toString().split('.').last,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'isRoleApproved': false, // Chưa được duyệt vai trò
            'pendingRole': null,
            'pendingDepartment': null,
          });
        } else {
          await userDoc.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
            'photoURL':
                userCredential.user!.photoURL, // Cập nhật ảnh đại diện mới nhất
          });
        }
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

  // Đăng xuất
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      _user = null;
    } catch (e) {
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

  // Lấy tất cả người dùng (chỉ Admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      if (_userModel == null || !_userModel!.isAdmin) {
        throw Exception('Bạn không có quyền truy cập danh sách người dùng');
      }

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      if (snapshot.docs.isEmpty) {
        return <UserModel>[]; // Trả về mảng rỗng thay vì null
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

  // Thay đổi vai trò người dùng (chỉ Admin)
  Future<void> changeUserRole(String userId, UserRole newRole) async {
    try {
      if (_userModel == null || !_userModel!.isAdmin) {
        throw Exception('Bạn không có quyền thay đổi vai trò');
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

  // Tạo Admin đầu tiên (chỉ dùng một lần)
  Future<void> createFirstAdmin() async {
    try {
      if (_user == null) {
        throw Exception('Vui lòng đăng nhập trước');
      }

      // Kiểm tra xem đã có Admin chưa
      QuerySnapshot adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.admin.toString().split('.').last)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        throw Exception('Đã có Admin trong hệ thống');
      }

      // Tạo Admin
      await _firestore.collection('users').doc(_user!.uid).update({
        'role': UserRole.admin.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload user model
      await _loadUserModel();
      notifyListeners();
    } catch (e) {
      throw Exception('Lỗi tạo Admin: $e');
    }
  }

  // Backward compatibility
  Future<void> createFirstSuperAdmin() async => createFirstAdmin();

  // Chọn vai trò và phòng ban sau khi đăng ký hoặc đăng nhập lần đầu
  Future<void> submitRoleAndDepartment({
    required UserRole selectedRole,
    required String? selectedDepartment,
  }) async {
    if (_user == null) throw Exception('Chưa đăng nhập');
    final userDoc = _firestore.collection('users').doc(_user!.uid);
    if (selectedRole == UserRole.guest) {
      // Nếu chọn guest thì duyệt luôn
      await userDoc.update({
        'role': 'guest',
        'departmentId': selectedDepartment,
        'pendingRole': null,
        'pendingDepartment': null,
        'isRoleApproved': true,
      });
    } else {
      // Nếu chọn vai trò khác thì chờ duyệt
      await userDoc.update({
        'pendingRole': selectedRole.toString().split('.').last,
        'pendingDepartment': selectedDepartment,
        'role': 'guest',
        'isRoleApproved': false,
      });
    }
    await _loadUserModel();
    notifyListeners();
  }

  // Lấy danh sách user chờ duyệt vai trò
  Future<List<UserModel>> getPendingUsers() async {
    if (_userModel == null || !_userModel!.isAdmin) {
      throw Exception('Bạn không có quyền truy cập');
    }
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('isRoleApproved', isEqualTo: false)
        .where('pendingRole', isNotEqualTo: null)
        .get();
    return snapshot.docs
        .map((doc) =>
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Admin duyệt vai trò
  Future<void> approveUserRole(String userId) async {
    if (_userModel == null || !_userModel!.isAdmin) {
      throw Exception('Bạn không có quyền phê duyệt');
    }
    final userDoc = _firestore.collection('users').doc(userId);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) throw Exception('User không tồn tại');
    final data = docSnapshot.data() as Map<String, dynamic>;
    final pendingRole = data['pendingRole'];
    final pendingDepartment = data['pendingDepartment'];
    if (pendingRole == null) throw Exception('Không có vai trò chờ duyệt');
    await userDoc.update({
      'role': pendingRole,
      'departmentId': pendingDepartment,
      'pendingRole': null,
      'pendingDepartment': null,
      'isRoleApproved': true,
    });
  }

  // Admin từ chối vai trò
  Future<void> rejectUserRole(String userId) async {
    if (_userModel == null || !_userModel!.isAdmin) {
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
}
