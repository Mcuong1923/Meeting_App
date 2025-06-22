import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;

  AuthProvider() {
    // Lắng nghe thay đổi trạng thái đăng nhập
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
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
          // Lần đăng nhập đầu tiên -> Tạo hồ sơ (đây là lúc sẽ chờ)
          await userDocRef.set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
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
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
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
}
