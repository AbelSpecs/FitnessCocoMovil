import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';

class RoutineService {
  static final _api = ApiClient.instance;

  // Muscle Groups
  static Future<List<dynamic>?> getMuscleGroups() async {
    try {
      final response = await _api.get('/MuscleGroups');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Exercises
  static Future<List<dynamic>?> getExerciseByMuscleGroupId(int id) async {
    try {
      final response = await _api.get('/Exercises/muscle-group/$id');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> postExercise(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/Exercises', data: data);
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExercise(int id) async {
    try {
      final response = await _api.get('/Exercises/$id');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // DailyStudentExercises
  static Future<List<dynamic>?> getDailyStudentExercisesByStudentIdAndDate(
      int studentId, String date) async {
    try {
      final response = await _api
          .get('/DailyStudentExercises/student/$studentId/date/$date');
      logDebug(
          'Fetching daily student exercises for student $studentId on $date - Response: ${response.data['data']}');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return null;
    } catch (e) {
      logError('Error fetching daily student exercises: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> postDailyStudentExercises(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/DailyStudentExercises', data: data);
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateDailyStudentsExercises(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/DailyStudentExercises/$id', data: data);
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteDailyStudentExercises(int id) async {
    try {
      final response = await _api.delete('/DailyStudentExercises/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // DailyExerciseSets
  static Future<Map<String, dynamic>?> postDailyExercisesSets(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post('/DailyExerciseSets', data: {'set': data});
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateCompleteDailyStudentExercises(
      int id, Map<String, dynamic> data) async {
    logDebug(data);
    try {
      final response =
          await _api.put('/DailyStudentExercises/complete/$id', data: data);
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateDailyExercisesSets(
      int id, Map<String, dynamic> data) async {
    logDebug(id);
    logDebug(data);

    try {
      final response = await _api.put('/DailyExerciseSets/$id', data: data);
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
