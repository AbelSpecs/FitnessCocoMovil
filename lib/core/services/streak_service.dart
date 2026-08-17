import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';

class StreakService {
  static final _api = ApiClient.instance;

  /// Obtiene el estado actual de la racha (streak) y escudos congeladores de un estudiante.
  /// Endpoint: GET /Streaks/student/{studentId}
  static Future<StudentStreakDto?> getStudentStreak(int studentId) async {
    try {
      final response = await _api.get('/Streaks/student/$studentId');
      final dynamic responseData = response.data;

      if (responseData != null) {
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        if (data != null && data is Map<String, dynamic>) {
          return StudentStreakDto.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      logError('Error al obtener la racha del estudiante $studentId: $e');
      return null;
    }
  }

  /// Registra un entrenamiento completado para calcular y actualizar la racha del estudiante.
  /// Endpoint: POST /Streaks/workout-completed
  static Future<Map<String, dynamic>?> postWorkoutCompleted(int studentId, String activityDate) async {
    try {
      final payload = WorkoutCompletedDto(
        studentId: studentId,
        activityDate: activityDate,
      ).toJson();

      final response = await _api.post('/Streaks/workout-completed', data: payload);
      final dynamic responseData = response.data;

      if (responseData != null) {
        if (responseData is Map<String, dynamic>) {
          return responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData;
        }
      }
      return null;
    } catch (e) {
      logError('Error al registrar entrenamiento completado: $e');
      return null;
    }
  }

  /// Obtiene el historial de logs y eventos de racha de un estudiante.
  /// Endpoint: GET /Streaks/student/{studentId}/history
  static Future<List<StreakHistoryLogDto>> getStudentStreakHistory(int studentId, {int limit = 30}) async {
    try {
      final response = await _api.get(
        '/Streaks/student/$studentId/history',
        queryParameters: {'limit': limit},
      );
      final dynamic responseData = response.data;

      if (responseData != null) {
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        if (data is List) {
          return data.map((item) => StreakHistoryLogDto.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      logError('Error al obtener el historial de racha del estudiante $studentId: $e');
      return [];
    }
  }

  /// Obtiene el radar de riesgo de pérdida de racha para los clientes de un entrenador.
  /// Endpoint: GET /Streaks/coach/{coachId}/risk-radar
  static Future<RiskRadarStudentDto?> getCoachRiskRadar(int coachId) async {
    try {
      final response = await _api.get('/Streaks/coach/$coachId/risk-radar');
      final dynamic responseData = response.data;

      if (responseData != null) {
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        if (data != null && data is Map<String, dynamic>) {
          return RiskRadarStudentDto.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      logError('Error al obtener el radar de riesgo del coach $coachId: $e');
      return null;
    }
  }

  /// Utiliza un escudo de congelación para proteger la racha del estudiante ante inactividad.
  /// Endpoint: POST /Streaks/student/{studentId}/use-freeze-shield
  static Future<Map<String, dynamic>?> useFreezeShield(int studentId, {String? shieldDate}) async {
    try {
      final payload = shieldDate != null ? {'shieldDate': shieldDate} : <String, dynamic>{};
      final response = await _api.post('/Streaks/student/$studentId/use-freeze-shield', data: payload);
      final dynamic responseData = response.data;

      if (responseData != null) {
        if (responseData is Map<String, dynamic>) {
          return responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData;
        }
      }
      return null;
    } catch (e) {
      logError('Error al usar escudo de congelación para el estudiante $studentId: $e');
      rethrow;
    }
  }
}
