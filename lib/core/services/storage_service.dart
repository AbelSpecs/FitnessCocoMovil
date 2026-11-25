import 'dart:typed_data';
import 'package:dio/dio.dart';

class _CachedDownloadUrl {
  final String url;
  final DateTime expiresAt;
  const _CachedDownloadUrl(this.url, this.expiresAt);
}

class StorageService {
  static const String storageApiBase = "https://api.pyrosfit.com/api/Storage";
  static final Map<String, _CachedDownloadUrl> _downloadUrlCache = {};

  /// Invalida la URL presignada de descarga en caché para una key de R2
  static void invalidateDownloadUrlCache(String? key) {
    if (key == null || key.trim().isEmpty) return;
    _downloadUrlCache.remove(key.trim());
  }

  /// Retorna la URL directa para consultar el avatar de un usuario por su userId
  static String getUserProfileUrl(dynamic userId) {
    if (userId == null || userId.toString().trim().isEmpty || userId.toString() == "0") {
      return "";
    }
    return "$storageApiBase/users/$userId/profile";
  }

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
    int? trainerId,
    required int exerciseId,
    required String fileName,
    required String contentType,
    int? userId,
    int expiresInSeconds = 600,
  }) async {
    final dio = Dio();
    final query = <String, String>{
      'exerciseId': exerciseId.toString(),
      'fileName': fileName,
      'contentType': contentType,
      'expiresInSeconds': expiresInSeconds.toString(),
    };
    if (trainerId != null && trainerId > 0) {
      query['trainerId'] = trainerId.toString();
    }
    if (userId != null && userId > 0) {
      query['userId'] = userId.toString();
    }
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

    if (!forceRefresh) {
      final cached = _downloadUrlCache[trimmed];
      if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
        return cached.url;
      }
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
      String resolved = '';
      if (data is String) {
        resolved = data;
      } else if (data is Map) {
        resolved = (data['downloadUrl'] ?? data['url'] ?? data['data']?['downloadUrl'] ?? data['data'] ?? '') as String;
      }
      if (resolved.isNotEmpty) {
        final ttlSeconds = (expiresInSeconds - 60).clamp(30, expiresInSeconds);
        _downloadUrlCache[trimmed] = _CachedDownloadUrl(
          resolved,
          DateTime.now().add(Duration(seconds: ttlSeconds)),
        );
        return resolved;
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
