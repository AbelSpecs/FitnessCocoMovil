import 'dart:typed_data';
import 'package:dio/dio.dart';

class StorageService {
  static const String storageApiBase = "https://api.pyrosfit.com/api/Storage";

  /// Retorna la URL directa del endpoint /Storage/serve para una key o URL de Cloudflare R2 / S3
  static String getServeUrl(String? keyOrUrl) {
    if (keyOrUrl == null || keyOrUrl.trim().isEmpty) return "";
    final trimmed = keyOrUrl.trim();
    if (trimmed.startsWith("http://") ||
        trimmed.startsWith("https://") ||
        trimmed.startsWith("data:") ||
        trimmed.startsWith("blob:")) {
      return trimmed;
    }
    return "$storageApiBase/serve?key=${Uri.encodeComponent(trimmed)}";
  }

  /// Solicita una URL presignada para subir una foto de perfil de usuario a Cloudflare R2
  static Future<Map<String, dynamic>> getPresignedProfileUrl({
    required int userId,
    required String fileName,
    required String contentType,
    int expiresInSeconds = 300,
  }) async {
    final dio = Dio();
    final query = {
      'userId': userId.toString(),
      'fileName': fileName,
      'contentType': contentType,
      'expiresInSeconds': expiresInSeconds.toString(),
    };
    final response = await dio.post(
      '$storageApiBase/presign/profile',
      queryParameters: query,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Solicita una URL presignada para subir un banner de entrenador a Cloudflare R2
  static Future<Map<String, dynamic>> getPresignedBannerUrl({
    required int trainerId,
    required String fileName,
    required String contentType,
    int expiresInSeconds = 300,
  }) async {
    final dio = Dio();
    final query = {
      'trainerId': trainerId.toString(),
      'fileName': fileName,
      'contentType': contentType,
      'expiresInSeconds': expiresInSeconds.toString(),
    };
    final response = await dio.post(
      '$storageApiBase/presign/banner',
      queryParameters: query,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Sube los bytes directamente a la URL presignada de Cloudflare R2 / S3
  static Future<void> uploadBytesToPresignedUrl({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }

  /// Solicita una URL presignada para subir un video de ejercicio a Cloudflare R2
  static Future<Map<String, dynamic>> getPresignedVideoUrl({
    required int trainerId,
    required int exerciseId,
    required String fileName,
    required String contentType,
    int expiresInSeconds = 600,
  }) async {
    final dio = Dio();
    final query = {
      'trainerId': trainerId.toString(),
      'exerciseId': exerciseId.toString(),
      'fileName': fileName,
      'contentType': contentType,
      'expiresInSeconds': expiresInSeconds.toString(),
    };
    final response = await dio.post(
      '$storageApiBase/presign/video',
      queryParameters: query,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Obtiene la URL presignada de descarga para una key de Storage
  static Future<String> getServeDownloadUrl(
    String key, {
    bool forceRefresh = false,
    int expiresInSeconds = 3600,
  }) async {
    if (key.trim().isEmpty) return "";
    final trimmed = key.trim();
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      return trimmed;
    }
    try {
      final dio = Dio();
      final response = await dio.get(
        '$storageApiBase/download',
        queryParameters: {
          'key': trimmed,
          'expiresInSeconds': expiresInSeconds.toString(),
        },
      );
      final data = response.data;
      if (data is String) return data;
      if (data is Map) {
        return (data['downloadUrl'] ?? data['url'] ?? data['data']?['downloadUrl'] ?? data['data'] ?? '') as String;
      }
      return getServeUrl(trimmed);
    } catch (e) {
      return getServeUrl(trimmed);
    }
  }

  /// Sube bytes de video con callback de progreso
  static Future<void> uploadVideoBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      onSendProgress: onProgress,
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }

}
