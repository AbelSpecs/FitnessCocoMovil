import 'daily_exercise_set_model.dart';

class DailyStudentExercise {
  final int exerciseId;
  final int coachId;
  final int dailyExerciseId;
  final int studentId;
  final String exerciseName;
  final int? muscleGroupId;
  final String muscleGroupName;
  final String description;
  final String coachNotes;
  final String studentNotes;
  final bool isCompleted;
  final String scheduledDate;
  final String day;
  final String short;
  final List<DailyExerciseSet> dailyExerciseSets;

  DailyStudentExercise({
    required this.exerciseId,
    required this.coachId,
    required this.dailyExerciseId,
    required this.studentId,
    required this.exerciseName,
    this.muscleGroupId,
    required this.muscleGroupName,
    required this.description,
    required this.coachNotes,
    required this.studentNotes,
    required this.isCompleted,
    required this.scheduledDate,
    required this.day,
    required this.short,
    required this.dailyExerciseSets,
  });

  factory DailyStudentExercise.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    var setsList = json['dailyExerciseSets'] as List? ?? [];
    List<DailyExerciseSet> sets = setsList.map((i) => DailyExerciseSet.fromJson(i)).toList();

    return DailyStudentExercise(
      exerciseId: parseInt(json['exerciseId']) ?? 0,
      coachId: parseInt(json['coachId']) ?? 0,
      dailyExerciseId: parseInt(json['dailyExerciseId']) ?? parseInt(json['id']) ?? 0,
      studentId: parseInt(json['studentId']) ?? 0,
      exerciseName: json['exerciseName']?.toString() ?? '',
      muscleGroupId: parseInt(json['muscleGroupId']),
      muscleGroupName: json['muscleGroupName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coachNotes: json['coachNotes']?.toString() ?? '',
      studentNotes: json['studentNotes']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true || json['isCompleted'] == 1 || json['isCompleted'] == 'true',
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      short: json['short']?.toString() ?? '',
      dailyExerciseSets: sets,
    );
  }
}
