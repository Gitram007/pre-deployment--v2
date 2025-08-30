import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/remote/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService apiService;
  List<Product> _products = [];
  List<Product> _allProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  ProductProvider({required this.apiService});

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  void search(String query) {
    _searchQuery = query;
    if (_searchQuery.isEmpty) {
      _products = _allProducts;
    } else {
      _products = _allProducts
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allProducts = await apiService.getProducts();
      _products = _allProducts;
    } catch (e) {
      // In a real app, you'd handle this error more gracefully
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(String name) async {
    try {
      final newProduct = await apiService.addProduct(Product(id: 0, name: name));
      _allProducts.add(newProduct);
      search(_searchQuery);
      notifyListeners();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> updateProduct(int id, String name) async {
    try {
      final updatedProduct = await apiService.updateProduct(id, Product(id: id, name: name));
      final productIndex = _allProducts.indexWhere((p) => p.id == id);
      if (productIndex != -1) {
        _allProducts[productIndex] = updatedProduct;
        search(_searchQuery);
        notifyListeners();
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await apiService.deleteProduct(id);
      _allProducts.removeWhere((p) => p.id == id);
      search(_searchQuery);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
