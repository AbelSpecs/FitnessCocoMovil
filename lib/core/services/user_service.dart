import 'package:pyrosfitmovil/core/network/api_client.dart';

class UserService {
  static final _api = ApiClient.instance;

  static Future<Map<String, dynamic>> getUser(String id) async {
    final response = await _api.get('/Users/$id');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getUserDetails(String id) async {
    final response = await _api.get('/Users/$id/details');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfilePictures(
    int userId, {
    String? profilePicture,
    String? bannerPicture,
  }) async {
    final response = await _api.put('/Users/$userId/profilePictures', data: {
      'userId': userId,
      'profilePicture': profilePicture,
      'bannerPicture': bannerPicture,
    });
    return response.data as Map<String, dynamic>;
  }
}