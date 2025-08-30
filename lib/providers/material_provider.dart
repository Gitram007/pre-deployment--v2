import 'package:flutter/material.dart';
import '../models/material.dart';
import '../data/remote/api_service.dart';

class MaterialProvider with ChangeNotifier {
  final ApiService apiService;
  List<AppMaterial> _materials = [];
  List<AppMaterial> _allMaterials = [];
  List<AppMaterial> _lowStockMaterials = [];
  bool _isLoading = false;
  String _searchQuery = '';

  MaterialProvider({required this.apiService}) {
    fetchLowStockMaterials();
  }

  List<AppMaterial> get materials => _materials;
  List<AppMaterial> get lowStockMaterials => _lowStockMaterials;
  bool get isLoading => _isLoading;

  Future<void> fetchLowStockMaterials() async {
    try {
      _lowStockMaterials = await apiService.getLowStockMaterials();
      notifyListeners();
    } catch (e) {
      print('Failed to fetch low stock materials: $e');
    }
  }

  void search(String query) {
    _searchQuery = query;
    if (_searchQuery.isEmpty) {
      _materials = _allMaterials;
    } else {
      _materials = _allMaterials
          .where((material) =>
              material.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> fetchMaterials() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allMaterials = await apiService.getMaterials();
      _materials = _allMaterials;
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMaterial(AppMaterial material) async {
    try {
      final newMaterial = await apiService.addMaterial(material);
      _allMaterials.add(newMaterial);
      search(_searchQuery);
      notifyListeners();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> updateMaterial(int id, AppMaterial material) async {
    try {
      final updatedMaterial = await apiService.updateMaterial(id, material);
      final materialIndex = _allMaterials.indexWhere((m) => m.id == id);
      if (materialIndex != -1) {
        _allMaterials[materialIndex] = updatedMaterial;
        search(_searchQuery);
        notifyListeners();
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await apiService.deleteMaterial(id);
      _allMaterials.removeWhere((m) => m.id == id);
      search(_searchQuery);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
