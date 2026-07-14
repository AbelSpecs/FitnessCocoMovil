import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';
import 'package:dio/dio.dart';

import 'package:logger/logger.dart';

final logger = Logger();

class AuthService {
  static final Dio _api = ApiClient.instance;

  static Future<Map<String, dynamic>> login(
      LoginCredentials credentials) async {
    logger.i('Intentando iniciar sesión con: ${credentials.toJson()}');
    try {
      final response =
          await _api.post('/Users/Login', data: credentials.toJson());

      logger.i('Sesión iniciada con: ${response.data['data']}');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error en login: $e');
      return {};
    }
  }

  static Future<void> register(RegisterCredentials data) async {
    await _api.post('/auth/register', data: data.toJson());
  }

  static Future<void> associateCoach(CoachStudent data) async {
    await _api.post('/auth/register-coach', data: data.toJson());
  }
}
