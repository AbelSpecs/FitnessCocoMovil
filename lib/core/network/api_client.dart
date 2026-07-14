import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5242/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Como indicó el usuario, por el momento no creamos los interceptores,
  // por lo que simplemente exponemos la instancia de Dio configurada.
  
  static Dio get instance => _dio;
}
