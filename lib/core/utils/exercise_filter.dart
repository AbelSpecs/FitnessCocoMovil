import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';

/// Determina si el usuario actual es un cliente independiente.
/// Un cliente es independiente si su rol es "student" y no tiene un entrenador asignado
/// (myCoachId es 0, null o el ID legado 9).
bool isUserIndependent(UserAuth? user) {
  if (user == null) return false;

  final userId = user.id;
  final studentId = user.studentId ?? 0;
  final coachId = user.coachId ?? 0;
  final myCoachId = user.myCoachId ?? 0;

  // El usuario con ID 53 (o studentId 23) siempre se considera independiente
  if (userId == 53 || studentId == 23) {
    return true;
  }

  // Cualquier usuario que dependa del coachId 9 (sea en myCoachId o coachId legado) es independiente
  if (coachId == 9 || myCoachId == 9) {
    return true;
  }

  // Si es un entrenador real (tiene coachId asignado > 0 y distinto de 9), no es independiente
  if (user.role == Role.coach && coachId > 0 && coachId != 9) {
    return false;
  }

  // Si tiene un entrenador asignado real (distinto de 0 y del ID legado 9), no es independiente
  if (myCoachId != 0 && myCoachId != 9) {
    return false;
  }

  return true;
}

/// Agrega el tag del studentId al final de la descripción del ejercicio.
/// Ejemplo: "Hacer con pausa abajo [studentId:15]"
String formatExerciseDescriptionWithStudentId(String? description, int? studentId) {
  final baseDesc = (description ?? '').trim();
  if (studentId == null || studentId == 0) return baseDesc;

  final tag = '[studentId:$studentId]';
  if (baseDesc.contains(tag)) {
    return baseDesc;
  }
  return baseDesc.isNotEmpty ? '$baseDesc $tag' : tag;
}

/// Limpia el tag de studentId de la descripción para mostrar un texto limpio en la interfaz.
String cleanExerciseDescription(String? description) {
  if (description == null || description.isEmpty) return '';
  return description.replaceAll(RegExp(r'\[student(?:Id)?:\s*\d+\]', caseSensitive: false), '').trim();
}

/// Filtra la lista de ejercicios según el usuario y alcance:
/// - Si es entrenador o cliente con entrenador asignado: no filtra por studentId (ve el catálogo normal).
/// - Si es cliente independiente: ve todos los ejercicios del sistema (isCustom = false)
///   y ÚNICAMENTE sus propios ejercicios personalizados (que contienen su studentId en la descripción).
List<ExerciseModel> filterExercisesForUser(
  List<ExerciseModel> exercisesList,
  UserAuth? user, [
  int? currentStudentId,
]) {
  if (!isUserIndependent(user)) {
    return exercisesList;
  }

  final effectiveId = (currentStudentId != null && currentStudentId != 0)
      ? currentStudentId
      : (user?.studentId ?? 0);

  return exercisesList.where((exercise) {
    // 1. Ejercicios globales / base de PyrosFit: visibles para todos
    if (!exercise.isCustom) {
      return true;
    }

    // 2. Si es personalizado, solo lo ve si la descripción contiene su studentId
    final desc = exercise.description ?? '';
    if (desc.isEmpty || effectiveId == 0) {
      return false;
    }

    final idStr = effectiveId.toString();
    final regex = RegExp(r'\[student(?:Id)?:\s*' + idStr + r'\]', caseSensitive: false);
    return regex.hasMatch(desc) ||
        desc.contains('studentId:$idStr') ||
        desc.contains('student:$idStr');
  }).toList();
}
