class Country {
  final int id;
  final String name;
  final String phoneCode;

  Country({required this.id, required this.name, required this.phoneCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      phoneCode: json['phoneCode'] as String? ?? '+1',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
