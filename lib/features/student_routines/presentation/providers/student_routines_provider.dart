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

      // Enriquecer proactivamente con video de RoutineService si el backend no lo devolvió en el DTO (como hace la web)
      final enriched = await Future.wait(data.map((e) async {
        if (!e.hasVideo && e.exerciseId > 0) {
          try {
            final exData = await RoutineService.getExercise(e.exerciseId);
            if (exData != null) {
              final vKey = exData['videoKey']?.toString();
              final vUrl = exData['videoUrl']?.toString();
              if ((vKey != null && vKey.isNotEmpty) || (vUrl != null && vUrl.isNotEmpty)) {
                return e.copyWith(videoKey: vKey, videoUrl: vUrl);
              }
            }
          } catch (_) {}
        }
        return e;
      }));

      _dailyExercises = enriched;
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
        final index = _dailyExercises.indexWhere((e) => e.id == exerciseId);
        if (index != -1) {
          _dailyExercises[index] = _dailyExercises[index].copyWith(
            isCompleted: true,
            studentNotes: studentNotes,
          );
          notifyListeners();
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
