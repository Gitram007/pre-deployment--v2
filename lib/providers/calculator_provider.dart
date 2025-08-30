import 'package:flutter/material.dart';
import '../data/remote/api_service.dart';
import '../models/calculator_result.dart';

class CalculatorProvider with ChangeNotifier {
  final ApiService apiService;

  CalculatorProvider({required this.apiService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CalculatorResult>? _results;
  List<CalculatorResult>? get results => _results;

  Future<String?> calculate(int productId, int quantity) async {
    _isLoading = true;
    _results = null; // Clear previous results
    notifyListeners();

    try {
      final calculatedResults = await apiService.calculateMaterials(productId, quantity);
      _results = calculatedResults;
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _results = null;
    notifyListeners();
  }
}
