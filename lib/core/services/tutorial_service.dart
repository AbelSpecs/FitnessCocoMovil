import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Servicio centralizado de persistencia para el sistema de tutoriales y tours guiados.
/// Sigue la arquitectura estándar de PyrosFit utilizando FlutterSecureStorage.
/// Diseñado para escalar a medida que la aplicación agregue nuevas secciones y funcionalidades.
class TutorialService {
  static final TutorialService instance = TutorialService._internal();
  TutorialService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  static const String _keyPrefix = 'pyros_tutorial_completed_';

  // Conjunto en memoria para respuesta instantánea y prevenir repeticiones en la misma sesión / ciclo de vida
  final Set<String> _completedToursInMemory = {};
  final Set<String> _activeRunningTours = {};

  // Constantes de tours interactivos disponibles en la app
  static const String studentProfileTour = 'student_profile_v1';
  static const String coachProfileTour = 'coach_profile_v1';
  static const String homeDashboardTour = 'home_dashboard_v1';
  static const String coachDashboardTour = 'coach_dashboard_v1';
  static const String studentWeeklyRoutineTour = 'student_weekly_routine_v1';
  static const String studentDailyRoutineTour = 'student_daily_routine_v1';
  static const String exercisesLibraryTour = 'exercises_library_v1';
  static const String rankingLeaderboardTour = 'ranking_leaderboard_v1';
  static const String coachClientsTour = 'coach_clients_v1';
  static const String coachClientRoutinesTour = 'coach_client_routines_v1';

  /// Retorna si se debe mostrar el tutorial indicado al usuario.
  /// Si ya se completó o está actualmente en ejecución, retorna false inmediatamente.
  Future<bool> shouldShowTutorial(String tourKey) async {
    if (_completedToursInMemory.contains(tourKey) || _activeRunningTours.contains(tourKey)) {
      return false;
    }
    try {
      final value = await _storage.read(key: '$_keyPrefix$tourKey');
      if (value == 'true') {
        _completedToursInMemory.add(tourKey);
        return false;
      }
      return true;
    } catch (e) {
      _logger.e('Error al consultar estado de tutorial $tourKey: $e');
      return false;
    }
  }

  /// Marca que un tutorial ha iniciado para evitar que se vuelva a disparar al pausar la app.
  void markTutorialStarted(String tourKey) {
    _activeRunningTours.add(tourKey);
  }

  /// Marca un tutorial como completado para no volver a interrumpir al usuario.
  Future<void> markTutorialCompleted(String tourKey) async {
    _completedToursInMemory.add(tourKey);
    _activeRunningTours.remove(tourKey);
    try {
      await _storage.write(key: '$_keyPrefix$tourKey', value: 'true');
    } catch (e) {
      _logger.e('Error al guardar tutorial completado $tourKey: $e');
    }
  }

  /// Restablece un tutorial específico para permitir que el usuario lo vuelva a ver explícitamente.
  Future<void> resetTutorial(String tourKey) async {
    _completedToursInMemory.remove(tourKey);
    _activeRunningTours.remove(tourKey);
    try {
      await _storage.delete(key: '$_keyPrefix$tourKey');
    } catch (e) {
      _logger.e('Error al reiniciar tutorial $tourKey: $e');
    }
  }

  /// Restablece todos los tutoriales interactivos de la aplicación.
  Future<void> resetAllTutorials() async {
    _completedToursInMemory.clear();
    _activeRunningTours.clear();
    try {
      final all = await _storage.readAll();
      for (final k in all.keys) {
        if (k.startsWith(_keyPrefix)) {
          await _storage.delete(key: k);
        }
      }
    } catch (e) {
      _logger.e('Error al reiniciar todos los tutoriales: $e');
    }
  }
}
