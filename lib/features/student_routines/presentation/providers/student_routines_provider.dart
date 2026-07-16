import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/globals.dart';
import 'package:pyrosfitmovil/core/services/routine_service.dart';
import 'package:pyrosfitmovil/features/dashboard/data/services/dashboard_service.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';

class StudentRoutinesProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GetDailyStudentExerciseDto> _weeklyExercises = [];
  List<GetDailyStudentExerciseDto> get weeklyExercises => _weeklyExercises;

  List<GetDailyStudentExerciseDto> _dailyExercises = [];
  List<GetDailyStudentExerciseDto> get dailyExercises => _dailyExercises;

  Future<void> fetchWeeklyExercises(int studentId, String dateStart, String dateEnd) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DashboardService.getDailyStudentExercisesByStudentIdAndDates(
          studentId, dateStart, dateEnd);
      _weeklyExercises = data;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error, por favor intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      logError('Error fetching weekly exercises: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyExercises(int studentId, String date) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DashboardService.getDailyStudentExercisesByStudentIdAndDate(
          studentId, date);
      _dailyExercises = data;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error, por favor intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      logError('Error fetching daily exercises: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeExerciseSet(
      GetDailyExerciseSetsDto set, bool isAchieved, int? actualReps, int? actualWeight) async {
    try {
      final data = {
        'id': set.id,
        'dailyStudentExerciseId': set.dailyStudentExerciseId,
        'setNumber': int.tryParse(set.setNumber) ?? 0,
        'targetReps': int.tryParse(set.targetReps) ?? 0,
        'targetWeight': int.tryParse(set.targetWeight) ?? 0,
        'restTime': set.restTime,
        'isAchieved': isAchieved,
        'actualReps': actualReps,
        'actualWeight': actualWeight,
      };
      final response = await RoutineService.updateDailyExercisesSets(set.id, data);
      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error, por favor intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      logError('Error completing set: $e');
      return false;
    }
  }

  Future<bool> completeExercise(int exerciseId, String studentNotes) async {
    try {
      final data = {
        'isCompleted': true,
        'studentNotes': studentNotes,
      };
      final response = await RoutineService.updateCompleteDailyStudentExercises(exerciseId, data);
      if (response != null) {
        // We could optimistically update it, but GetDailyStudentExerciseDto might not have copyWith.
        // Let's just update the list if possible, or fetch again.
        final index = _dailyExercises.indexWhere((e) => e.id == exerciseId);
        if (index != -1) {
          // It doesn't have copyWith, so we'll just reload or mutate if not final
          // Let's fetch again for simplicity or let the UI handle it
        }
        return true;
      }
      return false;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error, por favor intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      logError('Error completing exercise: $e');
      return false;
    }
  }
}
