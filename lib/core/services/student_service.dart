import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class StudentService {
  static final _api = ApiClient.instance;

  static Future<Map<String, dynamic>?> getStudentById(String id) async {
    try {
      final response = await _api.get('/Students/$id');
      logger.i('Estudiante obtenido: $response');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStudentByUserId(String id) async {
    try {
      final response = await _api.get('/Students/user/$id');
      logger.i('Estudiante obtenido: $response');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateStudent(
      int id, Map<String, dynamic> studentData) async {
    try {
      final response = await _api.put('/Students/$id', data: studentData);
      logger.i('Estudiante actualizado exitosamente');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error al actualizar estudiante: $e');
      return null;
    }
  }
}
