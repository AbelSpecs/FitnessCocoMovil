import 'package:dio/dio.dart';
import 'package:pyrosfitmovil/core/models/student_clinical_data_model.dart';
import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class StudentService {
  static final _api = ApiClient.instance;

  /// Obtiene el expediente clínico y antropométrico completo de un estudiante
  static Future<StudentClinicalData?> getStudentClinicalData(dynamic studentId) async {
    try {
      final response = await _api.get('/Students/$studentId');
      if (response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return StudentClinicalData.fromJson(response.data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      logger.w('Error al obtener ficha clínica del estudiante $studentId: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStudentById(String id) async {
    try {
      final response = await _api.get('/Students/$id');
      logger.i('Estudiante obtenido: $response');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>?> getAllStudents() async {
    try {
      final response = await _api.get('/Students');
      if (response.data != null) {
        if (response.data is List) {
          return response.data as List<dynamic>;
        }
        if (response.data is Map && response.data['data'] is List) {
          return response.data['data'] as List<dynamic>;
        }
      }
      return null;
    } catch (e) {
      logger.w('Error al obtener lista de todos los estudiantes: $e');
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

  static Future<Map<String, dynamic>?> createStudent(
      Map<String, dynamic> studentData) async {
    try {
      // El backend ASP.NET Core requiere que el objeto vaya encapsulado en la propiedad 'student'
      final payload = studentData.containsKey('student')
          ? studentData
          : {'student': studentData};

      final response = await _api.post('/Students', data: payload);
      if (response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data['data'];
          if (data is Map<String, dynamic>) {
            return data;
          } else if (data is int || data is num) {
            return {'id': data, ...response.data as Map<String, dynamic>};
          }
          return response.data as Map<String, dynamic>;
        }
      }
      return null;
    } on DioException catch (e) {
      String? errorMsg;
      if (e.response != null && e.response?.data != null) {
        final respData = e.response!.data;
        if (respData is Map) {
          errorMsg = respData['message'] ?? respData['title'] ?? respData['error'];
          if (errorMsg == null && respData['errors'] != null && respData['errors'] is Map) {
            final errMap = respData['errors'] as Map;
            final firstList = errMap.values.firstOrNull;
            if (firstList is List && firstList.isNotEmpty) {
              errorMsg = firstList.first.toString();
            } else {
              errorMsg = firstList?.toString();
            }
          }
        } else if (respData is String && respData.isNotEmpty) {
          errorMsg = respData;
        }
      }
      throw Exception(errorMsg ?? 'Error al registrar perfil de estudiante');
    } catch (e) {
      rethrow;
    }
  }
}
