class InwardEntry {
  final int id;
  final int materialId;
  final double quantity;
  final DateTime createdAt;

  InwardEntry({
    required this.id,
    required this.materialId,
    required this.quantity,
    required this.createdAt,
  });

  factory InwardEntry.fromJson(Map<String, dynamic> json) {
    return InwardEntry(
      id: json['id'],
      materialId: json['material'],
      quantity: double.parse(json['quantity']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material': materialId,
      'quantity': quantity,
    };
  }
}
