import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;

  Future<void> login(String email, String password) async {
    // TODO: Implement login logic with backend
    _isAuthenticated = true;
    _token = 'dummy_token';
    _userId = 'dummy_user_id';
    notifyListeners();
  }

  Future<void> signup(String email, String password) async {
    // TODO: Implement signup logic with backend
    _isAuthenticated = true;
    _token = 'dummy_token';
    _userId = 'dummy_user_id';
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    notifyListeners();
  }
}
