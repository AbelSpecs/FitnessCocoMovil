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

      if (response.data != null) {
        if (response.data['success'] == false) {
           throw Exception(response.data['message'] ?? 'Credenciales incorrectas');
        }
        logger.i('Sesión iniciada con: ${response.data['data']}');
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception('Ha ocurrido un error intenta nuevamente');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
         final data = e.response!.data;
         if (data is Map && data['success'] == false) {
            throw Exception(data['message'] ?? 'Error de servidor');
         }
      }
      throw Exception('Ha ocurrido un error intenta nuevamente');
    } catch (e) {
      logger.e('Error en login: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Ha ocurrido un error intenta nuevamente');
    }
  }

  static Future<void> register(RegisterCredentials data) async {
    try {
      final response = await _api.post('/Users/RegisterUser', data: data.toJson());
      if (response.data != null && response.data['success'] == false) {
         throw Exception(response.data['message'] ?? 'Error de servidor');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
         final respData = e.response!.data;
         if (respData is Map && respData['success'] == false) {
            throw Exception(respData['message'] ?? 'Error de servidor');
         }
      }
      throw Exception('Ha ocurrido un error intenta nuevamente');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Ha ocurrido un error intenta nuevamente');
    }
  }

  static Future<void> associateCoach(CoachStudent data) async {
    await _api.post('/CoachStudents', data: data.toJson());
  }
}
