class AppMaterial {
  final int id;
  final String name;
  final String unit;
  final double quantity;
  final String style;
  final double lowStockThreshold;

  AppMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.style = 'N/A',
    this.lowStockThreshold = 10.0,
  });

  factory AppMaterial.fromJson(Map<String, dynamic> json) {
    return AppMaterial(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      quantity: double.parse(json['quantity'].toString()),
      style: json['style'] ?? 'N/A',
      lowStockThreshold: double.parse(json['low_stock_threshold']?.toString() ?? '10.0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'style': style,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMaterial &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
