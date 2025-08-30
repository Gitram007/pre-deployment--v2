import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../data/remote/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService apiService;
  List<UserProfile> _users = [];
  bool _isLoading = false;

  UserProvider({required this.apiService});

  List<UserProfile> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await apiService.getUsers();
    } catch (e) {
      print(e);
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(int userId, String role) async {
    try {
      await apiService.updateUser(userId, role);
      await fetchUsers(); // Refresh the list
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await apiService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> createUser(String username, String email, String password, String role) async {
    try {
      await apiService.createUser(username, email, password, role);
      await fetchUsers(); // Refresh the list
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}
