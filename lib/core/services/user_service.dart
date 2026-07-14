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
}
