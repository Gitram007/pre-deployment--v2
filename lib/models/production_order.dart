class ProductionOrder {
  final int id;
  final int productId;
  final int quantity;
  final DateTime createdAt;

  ProductionOrder({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.createdAt,
  });

  factory ProductionOrder.fromJson(Map<String, dynamic> json) {
    return ProductionOrder(
      id: json['id'],
      productId: json['product'],
      quantity: int.parse(json['quantity'].toString()),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'quantity': quantity,
    };
  }
}
