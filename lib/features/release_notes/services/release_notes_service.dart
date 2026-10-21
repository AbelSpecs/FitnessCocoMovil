import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:pyrosfitmovil/features/release_notes/data/models/release_note_model.dart';
import 'package:pyrosfitmovil/features/release_notes/data/release_notes_catalog.dart';

/// Servicio encargado de detectar si hay novedades no vistas por el usuario
/// y persistir la última versión que ha visualizado.
class ReleaseNotesService {
  static final ReleaseNotesService instance = ReleaseNotesService._internal();
  ReleaseNotesService._internal();

  static const String _storageKey = 'pyros_last_seen_release_version';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  String? _cachedCurrentVersion;

  /// Obtiene la versión actual de la aplicación desde el sistema (ej. "1.0.0+8")
  Future<String> getCurrentAppVersion({bool includeBuildNumber = true}) async {
    if (_cachedCurrentVersion != null) return _cachedCurrentVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      final version = (includeBuildNumber && info.buildNumber.isNotEmpty)
          ? '${info.version}+${info.buildNumber}'
          : info.version;
      _cachedCurrentVersion = version;
      return version;
    } catch (e) {
      _logger.e('Error al obtener la versión de la app: $e');
      return '1.0.0';
    }
  }

  /// Obtiene la última versión que el usuario marcó como vista
  Future<String?> getLastSeenVersion() async {
    try {
      return await _storage.read(key: _storageKey);
    } catch (e) {
      _logger.e('Error al leer last_seen_version: $e');
      return null;
    }
  }

  /// Indica si hay notas de versión pendientes de ser mostradas al usuario
  Future<bool> shouldShowWhatsNew() async {
    final current = await getCurrentAppVersion();
    final lastSeen = await getLastSeenVersion();

    if (lastSeen == null) {
      // Primera vez o actualización desde versión anterior sin este sistema
      return true;
    }

    // Comparamos si la versión actual es mayor que la última que vio
    return ReleaseNotesCatalog.compareVersions(current, lastSeen) > 0;
  }

  /// Obtiene las notas de la versión actual instalada (o la más reciente si coincide)
  Future<ReleaseNote> getCurrentOrLatestRelease() async {
    final current = await getCurrentAppVersion();
    final match = ReleaseNotesCatalog.getByVersion(current);
    return match ?? ReleaseNotesCatalog.latestRelease;
  }

  /// Obtiene la lista de todas las versiones que el usuario aún no ha visto
  Future<List<ReleaseNote>> getPendingReleases() async {
    final lastSeen = await getLastSeenVersion();
    return ReleaseNotesCatalog.getUnseenReleases(lastSeen);
  }

  /// Marca una versión específica como vista
  Future<void> markVersionAsSeen(String version) async {
    try {
      await _storage.write(key: _storageKey, value: version);
      _logger.i('Versión $version marcada como vista por el usuario.');
    } catch (e) {
      _logger.e('Error al guardar last_seen_version: $e');
    }
  }

  /// Marca la versión actualmente instalada en el dispositivo como vista
  Future<void> markCurrentVersionAsSeen() async {
    final current = await getCurrentAppVersion();
    await markVersionAsSeen(current);
  }

  /// Útil para testing y QA: borra la marca de versión vista para que el modal
  /// vuelva a dispararse automáticamente.
  Future<void> resetSeenVersionForTesting() async {
    try {
      await _storage.delete(key: _storageKey);
      _cachedCurrentVersion = null;
      _logger.i('Versión vista reiniciada para pruebas.');
    } catch (e) {
      _logger.e('Error al reiniciar last_seen_version: $e');
    }
  }
}
