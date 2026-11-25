import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';

/// Determina si el usuario autenticado tiene permisos de administrador.
bool isAdminUser(UserAuth? user) {
  if (user == null) return false;
  return user.isAdmin;
}

/// Determina si un ejercicio pertenece al catálogo general (sin coach o no personalizado).
bool isGeneralExercise(ExerciseModel item) {
  return item.coachId == null || item.coachId == 0 || !item.isCustom;
}

/// Determina si el usuario actual puede editar/eliminar el ejercicio.
/// - Ejercicios generales: únicamente administradores.
/// - Ejercicios personalizados: administradores o el coach propietario.
bool canManageExercise(ExerciseModel item, UserAuth? user) {
  if (isGeneralExercise(item)) {
    return isAdminUser(user);
  }
  if (isAdminUser(user)) {
    return true;
  }
  final currentCoachId = user?.coachId ?? user?.id;
  return currentCoachId != null && item.coachId == currentCoachId;
}

