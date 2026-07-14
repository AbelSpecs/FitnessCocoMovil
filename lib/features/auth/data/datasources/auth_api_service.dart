import 'package:dio/dio.dart';

// REQUERIMIENTO DE MODELOS/ENTIDADES (Se crearán en tu capa de data/models):
// import 'package:pyrosfitmovil/features/auth/data/models/login_credentials.dart';
// import 'package:pyrosfitmovil/features/auth/data/models/register_credentials.dart';
// import 'package:pyrosfitmovil/features/auth/data/models/coach_student_model.dart';

class AuthApiService {
  // 1. Configuración de la Base URL (Equivalente a import.meta.env.VITE_API_URL)
  // Tip: En desarrollo local con emulador Android, usa 'http://10.0.2.2:PORT' en lugar de localhost
  static const String _apiBaseUrl = "https://tu-api-pyrosfit.com/api";

  // 2. Creación de la instancia de Dio (Equivalente a axios.create)
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10), // Buenas prácticas en móvil
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  /// 3. Registro de Usuario (Equivalente a export const register)
  Future<Map<String, dynamic>> register(
      Map<String, dynamic> credentials) async {
    try {
      final response =
          await _dio.post("/Users/RegisterUser", data: credentials);

      // En Dio, response.data ya viene parseado automáticamente como un Map (JSON)
      // Accedemos al nodo interno 'data' tal como hacías en React: response.data.data
      final data = response.data['data'];
      return data;
    } on DioException catch (e) {
      // Manejo de excepciones específicas de red/HTTP
      throw Exception(e.response?.data['message'] ?? "Error en el registro");
    }
  }

  /// 4. Asociar Entrenador y Alumno (Equivalente a export const associateCoach)
  Future<Map<String, dynamic>> associateCoach(Map<String, dynamic> info) async {
    try {
      final response = await _dio.post("/CoachStudents", data: info);
      final data = response.data['data'];
      return data;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? "Error al asociar entrenador");
    }
  }

  /// 5. Iniciar Sesión (Equivalente a export const login)
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _dio.post("/Users/Login", data: credentials);
      final data = response.data['data'];
      return data;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? "Credenciales incorrectas");
    }
  }
}
