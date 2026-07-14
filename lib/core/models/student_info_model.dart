class StudentInfo {
  final int studentId;
  final String name;
  final String fitnessGoal;
  final String plan;
  final int streak;

  StudentInfo({
    required this.studentId,
    required this.name,
    required this.fitnessGoal,
    required this.plan,
    required this.streak,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      studentId: json['studentId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      fitnessGoal: json['fitnessGoal'] as String? ?? '',
      plan: json['plan'] as String? ?? 'basic',
      streak: json['streak'] as int? ?? 0,
    );
  }
}
