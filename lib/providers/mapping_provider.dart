import 'package:flutter/material.dart';
import '../models/product_material_mapping.dart';
import '../data/remote/api_service.dart';

class MappingProvider with ChangeNotifier {
  final ApiService apiService;
  List<ProductMaterialMapping> _allMappings = [];
  bool _isLoading = false;

  MappingProvider({required this.apiService});

  List<ProductMaterialMapping> get allMappings => _allMappings;
  bool get isLoading => _isLoading;

  Future<void> fetchAllMappings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allMappings = await apiService.getMappings();
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProductMaterialMapping> getMappingsForProduct(int productId) {
      return _allMappings.where((m) => m.productId == productId).toList();
  }

  Future<void> addMapping(int productId, int materialId, double fixedQuantity) async {
    try {
      final newMapping = ProductMaterialMapping(id: 0, productId: productId, materialId: materialId, fixedQuantity: fixedQuantity);
      final createdMapping = await apiService.addMapping(newMapping);
      _allMappings.add(createdMapping);
      notifyListeners();
    } catch (e) {
        print(e);
    }
  }

  Future<void> deleteMapping(int mappingId) async {
    try {
      await apiService.deleteMapping(mappingId);
      _allMappings.removeWhere((m) => m.id == mappingId);
      notifyListeners();
    } catch (e) {
        print(e);
    }
  }
}
