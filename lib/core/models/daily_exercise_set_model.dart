class DailyExerciseSet {
  final int id;
  final int dailyStudentExerciseId;
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final String restTime;
  final int? actualReps;
  final double? actualWeight;
  final bool isAchieved;

  DailyExerciseSet({
    required this.id,
    required this.dailyStudentExerciseId,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.restTime,
    this.actualReps,
    this.actualWeight,
    required this.isAchieved,
  });

  factory DailyExerciseSet.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return DailyExerciseSet(
      id: parseInt(json['id']) ?? 0,
      dailyStudentExerciseId: parseInt(json['dailyStudentExerciseId']) ?? 0,
      setNumber: parseInt(json['setNumber']) ?? 0,
      targetReps: parseInt(json['targetReps']) ?? 0,
      targetWeight: parseDouble(json['targetWeight']) ?? 0.0,
      restTime: json['restTime']?.toString() ?? '',
      actualReps: parseInt(json['actualReps']),
      actualWeight: parseDouble(json['actualWeight']),
      isAchieved: json['isAchieved'] == true || json['isAchieved'] == 1 || json['isAchieved'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dailyStudentExerciseId': dailyStudentExerciseId,
      'setNumber': setNumber,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'restTime': restTime,
      'actualReps': actualReps,
      'actualWeight': actualWeight,
      'isAchieved': isAchieved,
    };
  }
}
