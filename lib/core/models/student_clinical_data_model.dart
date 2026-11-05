import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/anthropometric_helper.dart';

class StudentClinicalData {
  final int id;
  final int? userId;
  final double? weight;
  final double? height;
  final double? bodyFatPercentage;
  final DateTime? birthdate;
  final String? fitnessGoal;
  final String? activityLevel;
  final String? medicalConditions;
  final String? allergies;
  final String? fitnessExperience;
  final String? generalNotes;
  final int? gymId;

  const StudentClinicalData({
    required this.id,
    this.userId,
    this.weight,
    this.height,
    this.bodyFatPercentage,
    this.birthdate,
    this.fitnessGoal,
    this.activityLevel,
    this.medicalConditions,
    this.allergies,
    this.fitnessExperience,
    this.generalNotes,
    this.gymId,
  });

  factory StudentClinicalData.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      if (val is double) return val.toInt();
      return null;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.trim().isNotEmpty) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    return StudentClinicalData(
      id: parseInt(data['id'] ?? data['studentId']) ?? 0,
      userId: parseInt(data['userId'] ?? (data['user'] is Map ? data['user']['id'] : null)),
      weight: parseDouble(data['weight']),
      height: parseDouble(data['height']),
      bodyFatPercentage: parseDouble(data['bodyFatPercentage']),
      birthdate: parseDate(data['birthdate'] ?? (data['user'] is Map ? data['user']['birthdate'] : null)),
      fitnessGoal: data['fitnessGoal'] as String?,
      activityLevel: data['activityLevel'] as String?,
      medicalConditions: data['medicalConditions'] as String?,
      allergies: data['allergies'] as String?,
      fitnessExperience: data['fitnessExperience'] as String?,
      generalNotes: data['generalNotes'] as String?,
      gymId: parseInt(data['gymId']),
    );
  }

  // --- Métricas Calculadas mediante AnthropometricHelper ---

  /// Índice de Masa Corporal (IMC)
  double? get bmi => AnthropometricHelper.calculateBMI(weightKg: weight, heightCm: height);

  /// Categoría OMS del IMC
  String get bmiCategory => AnthropometricHelper.getBMICategory(bmi);

  /// Color semántico del IMC
  Color get bmiColor => AnthropometricHelper.getBMIColor(bmi);

  /// Masa Grasa en Kilogramos
  double? get fatMassKg => AnthropometricHelper.calculateFatMassKg(
        weightKg: weight,
        bodyFatPercentage: bodyFatPercentage,
      );

  /// Masa Magra en Kilogramos
  double? get leanMassKg => AnthropometricHelper.calculateLeanMassKg(
        weightKg: weight,
        bodyFatPercentage: bodyFatPercentage,
      );

  /// % de Masa Magra
  double? get leanMassPercentage => AnthropometricHelper.calculateLeanMassPercentage(bodyFatPercentage);

  /// Edad cronológica
  int? get age => AnthropometricHelper.calculateAge(birthdate);

  /// Tasa Metabólica Basal (TMB / BMR) en kcal/día
  int? get bmr => AnthropometricHelper.calculateBMR(
        weightKg: weight,
        heightCm: height,
        bodyFatPercentage: bodyFatPercentage,
        age: age,
      );

  /// Gasto Energético Total Diario (TDEE) / Mantenimiento en kcal/día
  int? get tdee => AnthropometricHelper.calculateTDEE(
        bmr: bmr,
        activityLevel: activityLevel,
      );

  /// Rango de peso saludable (min, max en kg)
  (double min, double max)? get healthyWeightRange => AnthropometricHelper.calculateHealthyWeightRange(height);

  // Formatos amigables para la UI
  String get formattedFatMass => fatMassKg != null ? '${fatMassKg!.toStringAsFixed(1)} kg' : '--';
  String get formattedLeanMass => leanMassKg != null ? '${leanMassKg!.toStringAsFixed(1)} kg' : '--';
  String get formattedLeanPercentage => leanMassPercentage != null ? '${leanMassPercentage!.toStringAsFixed(1)}%' : '--';
  String get formattedBMR => bmr != null ? '$bmr kcal' : '--';
  String get formattedTDEE => tdee != null ? '$tdee kcal' : '--';
  String get formattedAge => age != null ? '$age años' : 'No registrada';

  /// Evalúa si el texto clínico contiene información real (filtrando "ninguna", "n/a", etc.)
  static bool hasMeaningfulText(String? text) {
    if (text == null) return false;
    final clean = text.trim().toLowerCase();
    if (clean.isEmpty) return false;
    if (clean == '-' ||
        clean == '—' ||
        clean == 'ninguna' ||
        clean == 'ninguno' ||
        clean == 'sin registros' ||
        clean == 'no registrado' ||
        clean == 'no registra' ||
        clean == 'n/a' ||
        clean == 'none') {
      return false;
    }
    return true;
  }

  bool get hasMedicalConditions => hasMeaningfulText(medicalConditions);
  bool get hasAllergies => hasMeaningfulText(allergies);
  bool get hasGeneralNotes => hasMeaningfulText(generalNotes);
  bool get hasHealthAlert => hasMedicalConditions || hasAllergies;

  String get formattedWeight => weight != null && weight! > 0 ? '${weight!.toStringAsFixed(1)} kg' : 'No registrado';
  String get formattedHeight => height != null && height! > 0 ? '${height!.toStringAsFixed(0)} cm' : 'No registrado';
  String get formattedBodyFat => bodyFatPercentage != null && bodyFatPercentage! > 0 ? '${bodyFatPercentage!.toStringAsFixed(1)}%' : 'No registrado';

  String get formattedGoal {
    final g = fitnessGoal?.trim().toLowerCase() ?? '';
    switch (g) {
      case 'muscle':
        return 'Ganancia Muscular';
      case 'fat-loss':
      case 'fat_loss':
        return 'Pérdida de Grasa';
      case 'strength':
        return 'Ganancia de Fuerza';
      case 'endurance':
        return 'Resistencia';
      default:
        return fitnessGoal != null && fitnessGoal!.trim().isNotEmpty ? fitnessGoal!.trim() : 'General';
    }
  }

  String get formattedActivityLevel {
    final l = activityLevel?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    switch (l) {
      case 'sedentary':
      case 'sedentario':
        return 'Sedentario (Poco o ningún ejercicio)';
      case 'light':
      case 'ligero':
      case 'ligera':
        return 'Ligero (1-3 días/semana)';
      case 'moderate':
      case 'moderado':
      case 'moderada':
        return 'Moderado (3-5 días/semana)';
      case 'very_active':
      case 'muy_activo':
      case 'muy_activa':
        return 'Muy Activo (6-7 días/semana)';
      case 'extra_active':
      case 'atleta':
      case 'intenso':
        return 'Atleta / Intenso (Doble sesión)';
      default:
        return activityLevel != null && activityLevel!.trim().isNotEmpty ? activityLevel!.trim() : 'No especificado';
    }
  }

  String get formattedExperience {
    final e = fitnessExperience?.trim().toLowerCase() ?? '';
    if (e == 'si' || e == 'yes' || e == 'true') return 'Con experiencia previa';
    if (e == 'no' || e == 'false') return 'Principiante';
    switch (e) {
      case 'beginner':
      case 'principiante':
        return 'Principiante (< 6 meses)';
      case 'novice':
      case 'novato':
        return 'Novato (6m - 1 año)';
      case 'intermediate':
      case 'intermedio':
        return 'Intermedio (1 - 3 años)';
      case 'advanced':
      case 'avanzado':
        return 'Avanzado (> 3 años)';
      default:
        return fitnessExperience != null && fitnessExperience!.trim().isNotEmpty ? fitnessExperience!.trim() : 'No especificada';
    }
  }
}
