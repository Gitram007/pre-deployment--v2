import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../data/remote/api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService apiService;
  DashboardData? _dashboardData;
  bool _isLoading = false;

  DashboardProvider({required this.apiService});

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _dashboardData = await apiService.getDashboardData();
    } catch (e) {
      print(e);
      _dashboardData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
