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
}
