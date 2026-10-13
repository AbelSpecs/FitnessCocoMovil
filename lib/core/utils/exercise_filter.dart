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
/// Limpia el tag de studentId de la descripcion para mostrar un texto limpio en la interfaz,
/// asegurando separacion correcta entre palabras y signos de puntuacion para evitar palabras pegadas.
String cleanExerciseDescription(String? description) {
  if (description == null || description.isEmpty) return '';
  // 1. Quitar tags de studentId reemplazandolos con un espacio para evitar fusionar palabras adyacentes
  var text = description.replaceAll(RegExp(r'\[student(?:Id)?:\s*\d+\]', caseSensitive: false), ' ');
  // 2. Limpiar etiquetas HTML residuales
  text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  // 3. Separar signos de puntuacion si estan pegados a letras (ej: "espalda.Pies" -> "espalda. Pies")
  text = text.replaceAllMapped(RegExp(r'([.,:;!?])([A-Za-z\u00C0-\u00FF])'), (m) => '${m[1]} ${m[2]}');
  // 4. Separar dos puntos o signos pegados a digitos (ej: "Series:3" -> "Series: 3")
  text = text.replaceAllMapped(RegExp(r'([:;!?])(\d)'), (m) => '${m[1]} ${m[2]}');
  // 5. Separar punto o coma pegado a digito si NO es decimal (evitar tocar 12.5 o 12,5)
  text = text.replaceAllMapped(RegExp(r'(?<!\d)([.,])(\d)'), (m) => '${m[1]} ${m[2]}');
  // 6. Normalizar espacios repetidos sin eliminar saltos de linea intencionales
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  return text;
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


const List<String> supersetTagLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
];

/// Devuelve la siguiente letra disponible para una nueva serie combinada (ej. 'A', 'B'...).
String getNextAvailableSuperSetTag(List<String> usedTags) {
  final upperUsed = usedTags
      .map((t) => t.trim().toUpperCase())
      .where((t) => t.isNotEmpty)
      .toSet();
  for (final letter in supersetTagLetters) {
    if (!upperUsed.contains(letter)) {
      return letter;
    }
  }
  return 'C${upperUsed.length + 1}';
}

/// Genera el título combinado de grupos musculares para una lista de ejercicios (ej. "Pecho + Espalda").
String getMuscleGroupsTitle(List<dynamic> exercises) {
  final uniqueGroups = <String>{};
  for (final ex in exercises) {
    String? groupName;
    if (ex is Map) {
      groupName = ex['muscleGroupName']?.toString();
    } else {
      try {
        groupName = (ex as dynamic).muscleGroupName?.toString();
      } catch (_) {}
    }
    if (groupName != null && groupName.trim().isNotEmpty) {
      uniqueGroups.add(groupName.trim());
    }
  }
  return uniqueGroups.isNotEmpty ? uniqueGroups.join(' + ') : 'Entrenamiento';
}
