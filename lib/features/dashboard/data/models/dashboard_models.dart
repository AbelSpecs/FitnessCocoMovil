class CoachStudentsDto {
  final int studentId;
  final String name;
  final String fitnessGoal;

  CoachStudentsDto({
    required this.studentId,
    required this.name,
    required this.fitnessGoal,
  });

  factory CoachStudentsDto.fromJson(Map<String, dynamic> json) {
    return CoachStudentsDto(
      studentId: json['studentId'] as int,
      name: json['name'] as String,
      fitnessGoal: json['fitnessGoal'] as String? ?? '',
    );
  }
}

class GetDailyExerciseSetsDto {
  final int id;
  final int dailyStudentExerciseId;
  final String setNumber;
  final String targetReps;
  final String targetWeight;
  final String restTime;
  final int? actualReps;
  final int? actualWeight;
  final bool isAchieved;

  GetDailyExerciseSetsDto({
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

  factory GetDailyExerciseSetsDto.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return GetDailyExerciseSetsDto(
      id: parseInt(json['id']) ?? 0,
      dailyStudentExerciseId: parseInt(json['dailyStudentExerciseId']) ?? 0,
      setNumber: json['setNumber']?.toString() ?? '',
      targetReps: json['targetReps']?.toString() ?? '',
      targetWeight: json['targetWeight']?.toString() ?? '',
      restTime: json['restTime']?.toString() ?? '',
      actualReps: parseInt(json['actualReps']),
      actualWeight: parseInt(json['actualWeight']),
      isAchieved: json['isAchieved'] == true || json['isAchieved'] == 1 || json['isAchieved'] == 'true',
    );
  }
}

class GetDailyStudentExerciseDto {
  final int id;
  final int coachId;
  final int studentId;
  final int exerciseId;
  final String scheduledDate;
  final List<GetDailyExerciseSetsDto> dailyExerciseSets;
  final String exerciseName;
  final String muscleGroupName;
  final String coachNotes;
  final String studentNotes;
  final bool isCompleted;

  GetDailyStudentExerciseDto({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.exerciseId,
    required this.scheduledDate,
    required this.dailyExerciseSets,
    required this.exerciseName,
    required this.muscleGroupName,
    required this.coachNotes,
    required this.studentNotes,
    required this.isCompleted,
  });

  factory GetDailyStudentExerciseDto.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    var list = json['dailyExerciseSets'] as List? ?? [];
    List<GetDailyExerciseSetsDto> setsList = list.map((i) => GetDailyExerciseSetsDto.fromJson(i)).toList();

    return GetDailyStudentExerciseDto(
      id: parseInt(json['id']) ?? 0,
      coachId: parseInt(json['coachId']) ?? 0,
      studentId: parseInt(json['studentId']) ?? 0,
      exerciseId: parseInt(json['exerciseId']) ?? 0,
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      dailyExerciseSets: setsList,
      exerciseName: json['exerciseName']?.toString() ?? '',
      muscleGroupName: json['muscleGroupName']?.toString() ?? '',
      coachNotes: json['coachNotes']?.toString() ?? '',
      studentNotes: json['studentNotes']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true || json['isCompleted'] == 1 || json['isCompleted'] == 'true',
    );
  }
}
