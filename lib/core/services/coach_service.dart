import 'package:pyrosfitmovil/core/network/api_client.dart';

class CoachService {
  static final _api = ApiClient.instance;

  static Future<Map<String, dynamic>?> getCoachById(String id) async {
    try {
      final response = await _api.get('/Coaches/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCoachByUserId(String id) async {
    try {
      final response = await _api.get('/Coaches/user/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>?> getCoachStudents(int coachId) async {
    try {
      final response = await _api.get('/Coaches/studentsList/$coachId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data']['students'] as List<dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
