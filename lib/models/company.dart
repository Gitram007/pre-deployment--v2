class Company {
  final int id;
  final String name;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
