import 'package:pyrosfitmovil/core/models/coach_profile_model.dart';
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

  static Future<Map<String, dynamic>?> updateCoach(
      int coachId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/Coaches/$coachId', data: data);
      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<CoachProfile?> getCoachProfile(int coachId) async {
    try {
      final response = await _api.get('/Coaches/profile/$coachId');
      if (response.data != null && response.data['data'] != null) {
        return CoachProfile.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createCoach(
      Map<String, dynamic> coachData) async {
    try {
      final response = await _api.post('/Coaches', data: coachData);
      if (response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data['data'] ?? response.data;
          if (data is Map<String, dynamic>) {
            return data;
          }
          return response.data as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
