import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/models/muscle_group_model.dart';
import 'package:pyrosfitmovil/core/services/routine_service.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';

class RoutinesProvider extends ChangeNotifier {
  final AuthProvider authProvider;

  List<DailyStudentExercise> _routines = [];
  List<MuscleGroup> _muscleGroups = [];
  List<ExerciseModel> _exercises = [];

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  int? _currentStudentId;

  RoutinesProvider(this.authProvider) {
    _loadMuscleGroups();
  }

  List<DailyStudentExercise> get routines => _routines;
  List<MuscleGroup> get muscleGroups => _muscleGroups;
  List<ExerciseModel> get exercises => _exercises;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadRoutinesForStudent(int studentId, DateTime date) async {
    _currentStudentId = studentId;
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = date.toIso8601String();
      final rawData =
          await RoutineService.getDailyStudentExercisesByStudentIdAndDate(
              studentId, dateStr);
      logDebug('Loaded routines for student $studentId on $dateStr: $rawData');
      if (rawData != null) {
        logDebug('Raw data for routines: $rawData');
        _routines =
            rawData.map((e) => DailyStudentExercise.fromJson(e)).toList();
        logDebug('Parsed routines: $_routines');
      } else {
        _routines = [];
        logDebug('Parsed empty routines: $_routines');
      }
    } catch (e) {
      debugPrint("Error loading routines: $e");
      _routines = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMuscleGroups() async {
    try {
      final rawData = await RoutineService.getMuscleGroups();
      if (rawData != null) {
        _muscleGroups = rawData.map((e) => MuscleGroup.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading muscle groups: $e");
    }
  }

  Future<void> loadExercisesForMuscleGroup(int muscleGroupId) async {
    try {
      final rawData =
          await RoutineService.getExerciseByMuscleGroupId(muscleGroupId);
      if (rawData != null) {
        _exercises = rawData.map((e) => ExerciseModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading exercises: $e");
    }
  }

  void clearExercises() {
    _exercises = [];
    notifyListeners();
  }

  Future<bool> deleteRoutine(int dailyExerciseId) async {
    bool success =
        await RoutineService.deleteDailyStudentExercises(dailyExerciseId);
    if (success && _currentStudentId != null) {
      _routines.removeWhere((r) => r.dailyExerciseId == dailyExerciseId);
      notifyListeners();
    }
    return success;
  }

  Future<bool> saveNewRoutine(Map<String, dynamic> data) async {
    try {
      final response = await RoutineService.postDailyStudentExercises(data);
      if (response != null && _currentStudentId != null) {
        await loadRoutinesForStudent(_currentStudentId!, _selectedDate);
        return true;
      }
    } catch (e) {
      debugPrint("Error saving new routine: $e");
    }
    return false;
  }

  Future<bool> updateRoutine(int dailyExerciseId, Map<String, dynamic> data,
      List<Map<String, dynamic>> newSets) async {
    logDebug(dailyExerciseId);
    logDebug(data);
    logDebug(newSets);
    try {
      final response = await RoutineService.updateDailyStudentsExercises(
          dailyExerciseId, data);

      logDebug(response);

      for (var set in newSets) {
        await RoutineService.postDailyExercisesSets(set);
      }

      if (response != null && _currentStudentId != null) {
        await loadRoutinesForStudent(_currentStudentId!, _selectedDate);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating routine: $e");
    }
    return false;
  }

  Future<bool> createCustomExercise(String name, int muscleGroupId) async {
    try {
      final coachId = authProvider.user?.coachId;
      if (coachId == null) return false;

      final data = {
        "exercise": {
          "coachId": coachId,
          "name": name,
          "description": "",
          "muscleGroupId": muscleGroupId,
          "videoUrl": "",
          "isCustom": true
        }
      };

      final response = await RoutineService.postExercise(data);
      if (response != null) {
        await loadExercisesForMuscleGroup(muscleGroupId);
        return true;
      }
    } catch (e) {
      debugPrint("Error creating custom exercise: $e");
    }
    return false;
  }
}
