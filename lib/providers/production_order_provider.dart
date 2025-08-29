import 'package:flutter/material.dart';
import '../models/production_order.dart';
import '../data/remote/api_service.dart';

class ProductionOrderProvider with ChangeNotifier {
  final ApiService apiService;
  List<ProductionOrder> _orders = [];
  bool _isLoading = false;

  ProductionOrderProvider({required this.apiService});

  List<ProductionOrder> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchProductionOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await apiService.getProductionOrders();
      // Sort by most recent first
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProductionOrder(int productId, int quantity) async {
    try {
      final newOrder = await apiService.addProductionOrder(
        ProductionOrder(id: 0, productId: productId, quantity: quantity, createdAt: DateTime.now()),
      );
      _orders.insert(0, newOrder); // Insert at the beginning of the list
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
