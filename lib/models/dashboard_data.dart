import 'material.dart';
import 'production_order.dart';
import 'inward_entry.dart';

class DashboardData {
  final int productCount;
  final int materialCount;
  final List<AppMaterial> lowStockMaterials;
  final List<ProductionOrder> recentProductionOrders;
  final List<InwardEntry> recentInwardEntries;

  DashboardData({
    required this.productCount,
    required this.materialCount,
    required this.lowStockMaterials,
    required this.recentProductionOrders,
    required this.recentInwardEntries,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse lists from JSON
    List<T> _parseList<T>(
        String key, T Function(Map<String, dynamic>) fromJson) {
      if (json[key] != null) {
        final list = json[key] as List;
        return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return DashboardData(
      productCount: json['product_count'] ?? 0,
      materialCount: json['material_count'] ?? 0,
      lowStockMaterials:
          _parseList('low_stock_materials', (i) => AppMaterial.fromJson(i)),
      recentProductionOrders: _parseList(
          'recent_production_orders', (i) => ProductionOrder.fromJson(i)),
      recentInwardEntries:
          _parseList('recent_inward_entries', (i) => InwardEntry.fromJson(i)),
    );
  }
}
