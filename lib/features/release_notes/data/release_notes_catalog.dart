import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/features/release_notes/data/models/release_note_model.dart';

/// Catálogo centralizado de versiones y notas de lanzamiento de PyrosFit.
/// 
/// Este catálogo es la única fuente de la verdad para:
/// 1. Mostrar el modal automático cuando el usuario actualiza la app.
/// 2. Alimentar el feed / pantalla de historial de versiones.
/// 3. Servir de base o fallback si en el futuro se consulta una API remota.
class ReleaseNotesCatalog {
  ReleaseNotesCatalog._();

  /// Listado histórico de todas las versiones ordenadas de la más reciente a la más antigua.
  static final List<ReleaseNote> _releases = [
    ReleaseNote(
      version: '1.0.0',
      buildNumber: 7,
      releaseDate: DateTime(2025, 2, 20),
      title: '¡Bienvenido al nuevo PyrosFit!',
      subtitle: 'La plataforma definitiva para llevar tu entrenamiento al siguiente nivel.',
      isMajor: true,
      items: [
        const ReleaseItem(
          title: 'Rutinas semanales y diarias interactivas',
          description:
              'Visualiza tus ejercicios asignados día por día con series, repeticiones, descansos y notas del entrenador.',
          type: ReleaseItemType.feature,
          icon: Icons.fitness_center,
        ),
        const ReleaseItem(
          title: 'Reproductor de video de técnica',
          description:
              'Aprende la técnica correcta de cada ejercicio directamente desde la app con videos en alta definición.',
          type: ReleaseItemType.feature,
          icon: Icons.play_circle_fill_outlined,
        ),
        const ReleaseItem(
          title: 'Sistema de Racha y Disciplina',
          description:
              'Registra tus entrenamientos consecutivos y mantén encendida la llama de tu racha diaria.',
          type: ReleaseItemType.feature,
          icon: Icons.local_fire_department,
        ),
        const ReleaseItem(
          title: 'Podio y Ranking en vivo',
          description:
              'Compite amistosamente con tus compañeros de gimnasio según tu constancia y puntos acumulados.',
          type: ReleaseItemType.feature,
          icon: Icons.emoji_events_outlined,
        ),
        const ReleaseItem(
          title: 'Vinculación rápida con Código QR',
          description:
              'Conéctate instantáneamente con tu coach escaneando su código QR exclusivo desde la app.',
          type: ReleaseItemType.improvement,
          icon: Icons.qr_code_scanner,
        ),
        const ReleaseItem(
          title: 'Interfaz oscura de alto rendimiento',
          description:
              'Diseño completamente optimizado para entrenamientos en sala con estética fluida y modo oscuro.',
          type: ReleaseItemType.ui,
          icon: Icons.dark_mode_outlined,
        ),
      ],
    ),
  ];

  /// Obtiene la lista completa de todas las versiones registradas.
  static List<ReleaseNote> get allReleases => List.unmodifiable(_releases);

  /// Obtiene la nota de lanzamiento más reciente.
  static ReleaseNote get latestRelease => _releases.first;

  /// Busca las notas de una versión específica (ej. "1.0.0").
  static ReleaseNote? getByVersion(String version) {
    try {
      final cleanVersion = _cleanVersion(version);
      return _releases.firstWhere((r) => _cleanVersion(r.version) == cleanVersion);
    } catch (_) {
      return null;
    }
  }

  /// Retorna las versiones que son posteriores a la última versión que vio el usuario.
  /// Si [lastSeenVersion] es null, significa que es la primera vez que abre la app,
  /// por lo que devuelve la versión más reciente.
  static List<ReleaseNote> getUnseenReleases(String? lastSeenVersion) {
    if (lastSeenVersion == null || lastSeenVersion.isEmpty) {
      return [_releases.first];
    }

    final cleanLast = _cleanVersion(lastSeenVersion);
    final unseen = <ReleaseNote>[];

    for (final release in _releases) {
      final cleanCur = _cleanVersion(release.version);
      if (cleanCur == cleanLast) {
        break; // Ya encontramos la última que vio, no agregamos más antiguas
      }
      if (compareVersions(cleanCur, cleanLast) > 0) {
        unseen.add(release);
      }
    }

    return unseen;
  }

  /// Registra una nueva versión dinámicamente (por ejemplo, si se obtienen de una API remota en el futuro).
  static void registerRemoteRelease(ReleaseNote note) {
    final index = _releases.indexWhere((r) => _cleanVersion(r.version) == _cleanVersion(note.version));
    if (index >= 0) {
      _releases[index] = note;
    } else {
      _releases.insert(0, note);
      _releases.sort((a, b) => compareVersions(b.version, a.version));
    }
  }

  /// Compara dos versiones semánticas (ej. "1.0.1" vs "1.0.0").
  /// Retorna > 0 si [v1] es mayor que [v2].
  /// Retorna < 0 si [v1] es menor que [v2].
  /// Retorna 0 si son iguales.
  static int compareVersions(String v1, String v2) {
    final v1Parts = _cleanVersion(v1).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = _cleanVersion(v2).split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < maxLen; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    return 0;
  }

  static String _cleanVersion(String v) {
    // Elimina el build number si viene como "1.0.0+7" -> "1.0.0"
    return v.split('+').first.replaceAll('v', '').trim();
  }
}
