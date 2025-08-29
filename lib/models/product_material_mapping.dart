class ProductMaterialMapping {
  final int id;
  final int productId;
  final int materialId;
  final double fixedQuantity;

  ProductMaterialMapping({
    required this.id,
    required this.productId,
    required this.materialId,
    required this.fixedQuantity,
  });

  factory ProductMaterialMapping.fromJson(Map<String, dynamic> json) {
    return ProductMaterialMapping(
      id: json['id'],
      productId: json['product'],
      materialId: json['material'],
      fixedQuantity: double.parse(json['fixed_quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'material': materialId,
      'fixed_quantity': fixedQuantity,
    };
  }
}
