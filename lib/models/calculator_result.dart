class CalculatorResult {
  final int materialId;
  final String materialName;
  final String materialUnit;
  final double requiredQuantity;
  final double currentStock;
  final double shortfall;

  CalculatorResult({
    required this.materialId,
    required this.materialName,
    required this.materialUnit,
    required this.requiredQuantity,
    required this.currentStock,
    required this.shortfall,
  });

  factory CalculatorResult.fromJson(Map<String, dynamic> json) {
    return CalculatorResult(
      materialId: json['material_id'],
      materialName: json['material_name'],
      materialUnit: json['material_unit'],
      requiredQuantity: double.parse(json['required_quantity'].toString()),
      currentStock: double.parse(json['current_stock'].toString()),
      shortfall: double.parse(json['shortfall'].toString()),
    );
  }
}
