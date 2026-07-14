class MuscleGroup {
  final int id;
  final String name;

  MuscleGroup({
    required this.id,
    required this.name,
  });

  factory MuscleGroup.fromJson(Map<String, dynamic> json) {
    return MuscleGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return name;
  }
}
