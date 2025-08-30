import 'package:flutter/material.dart';
import '../data/remote/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';

enum AuthStatus { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  final _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.Uninitialized;
  String? _token;
  UserProfile? _user;

  AuthProvider({required this.apiService}) {
    _initAuth();
  }

  AuthStatus get status => _status;
  String? get token => _token;
  UserProfile? get user => _user;
  bool get isAdmin => _user?.profile.role == 'admin';

  Future<void> _initAuth() async {
    _token = await _storage.read(key: 'access_token');
    if (_token != null) {
      await fetchUserProfile();
      if (_user != null) {
        _status = AuthStatus.Authenticated;
      } else {
        // Token is present but user fetch failed, likely invalid token
        _status = AuthStatus.Unauthenticated;
        await logout(); // Clear invalid token
      }
    } else {
      _status = AuthStatus.Unauthenticated;
    }
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    try {
      _user = await apiService.getCurrentUser();
    } catch (e) {
      print('Failed to fetch user profile: $e');
      _user = null;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _status = AuthStatus.Authenticating;
    notifyListeners();
    try {
      await apiService.login(username, password);
      await _initAuth();
    } catch (e) {
      // Let the UI handle the state change after showing the error
      rethrow;
    }
  }

  Future<bool> register(String company, String username, String email, String password) async {
    try {
      await apiService.register(company, username, email, password);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.Unauthenticated;
    _token = null;
    _user = null;
    await apiService.logout();
    notifyListeners();
  }

  void setAuthStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
