import 'package:flutter/material.dart';
import '../data/remote/api_service.dart';

class ReportProvider with ChangeNotifier {
  final ApiService apiService;
  Map<String, dynamic> _materialUsage = {};
  Map<String, dynamic> _overallReport = {};
  bool _isLoading = false;

  ReportProvider({required this.apiService});

  Map<String, dynamic> get materialUsage => _materialUsage;
  Map<String, dynamic> get overallReport => _overallReport;
  bool get isLoading => _isLoading;

  Future<void> fetchMaterialUsageByProduct(int productId, String frequency) async {
    _isLoading = true;
    notifyListeners();
    try {
      _materialUsage = await apiService.getMaterialUsageByProduct(productId, frequency);
    } catch (e) {
      print(e);
      _materialUsage = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverallReport(String frequency) async {
    _isLoading = true;
    notifyListeners();
    try {
      _overallReport = await apiService.getOverallReport(frequency);
    } catch (e) {
      print(e);
      _overallReport = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
