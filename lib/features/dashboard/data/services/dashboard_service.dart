import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';

class DashboardService {
  static final _api = ApiClient.instance;

  static Future<List<CoachStudentsDto>> getCoachStudents(int coachId) async {
    try {
      final response = await _api.get('/Coaches/studentsList/$coachId');
      final data = response.data['data'];
      final students = data['students'] as List;
      return students.map((e) => CoachStudentsDto.fromJson(e)).toList();
    } catch (e) {
      print('Error en getCoachStudents: $e');
      return [];
    }
  }

  static Future<List<GetDailyStudentExerciseDto>> getDailyStudentExercisesByStudentIdAndDate(
      int studentId, String date) async {
    try {
      final response = await _api.get('/DailyStudentExercises/student/$studentId/date/$date');
      final data = response.data['data'] as List;
      return data.map((e) => GetDailyStudentExerciseDto.fromJson(e)).toList();
    } catch (e) {
      print('Error en getDailyStudentExercisesByStudentIdAndDate: $e');
      return [];
    }
  }

  static Future<List<GetDailyStudentExerciseDto>> getDailyStudentExercisesByStudentIdAndDates(
      int studentId, String dateS, String dateE) async {
    try {
      final response = await _api.get(
          '/DailyStudentExercises/student/$studentId/date/start/$dateS/end/$dateE');
      final data = response.data['data'] as List;
      return data.map((e) => GetDailyStudentExerciseDto.fromJson(e)).toList();
    } catch (e) {
      print('Error en getDailyStudentExercisesByStudentIdAndDates: $e');
      return [];
    }
  }
}
