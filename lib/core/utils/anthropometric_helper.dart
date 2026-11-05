import 'package:flutter/material.dart';

/// Helper centralizado para todos los cálculos antropométricos y metabólicos
/// derivados a partir de los datos físicos del alumno (peso, altura, % grasa, fecha de nacimiento, nivel de actividad).
class AnthropometricHelper {
  AnthropometricHelper._();

  /// 1. Índice de Masa Corporal (IMC en kg/m²)
  /// Fórmula OMS: peso / (altura_en_metros)^2
  static double? calculateBMI({required double? weightKg, required double? heightCm}) {
    if (weightKg == null || heightCm == null || weightKg <= 0 || heightCm <= 0) {
      return null;
    }
    final heightInMeters = heightCm / 100.0;
    final val = weightKg / (heightInMeters * heightInMeters);
    if (!val.isFinite || val <= 0 || val > 100) return null;
    return double.parse(val.toStringAsFixed(1));
  }

  /// Categoría OMS según el IMC
  static String getBMICategory(double? bmi) {
    if (bmi == null) return 'No registrado';
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Color semántico según la categoría de IMC
  static Color getBMIColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return const Color(0xFFFBBF24); // Ámbar
    if (bmi < 25.0) return const Color(0xFF22C55E); // Verde
    if (bmi < 30.0) return const Color(0xFFF97316); // Naranja
    return const Color(0xFFEF4444); // Rojo
  }

  /// 2. Masa Grasa en Kilogramos (Fat Mass)
  /// Fórmula: peso * (% grasa / 100)
  static double? calculateFatMassKg({
    required double? weightKg,
    required double? bodyFatPercentage,
  }) {
    if (weightKg == null || bodyFatPercentage == null || weightKg <= 0 || bodyFatPercentage <= 0) {
      return null;
    }
    final fatKg = weightKg * (bodyFatPercentage / 100.0);
    return double.parse(fatKg.toStringAsFixed(1));
  }

  /// 3. Masa Magra / Libre de Grasa en Kilogramos (Lean Body Mass - LBM)
  /// Fórmula: peso - masa_grasa
  static double? calculateLeanMassKg({
    required double? weightKg,
    required double? bodyFatPercentage,
  }) {
    if (weightKg == null || bodyFatPercentage == null || weightKg <= 0 || bodyFatPercentage <= 0) {
      return null;
    }
    final fatKg = weightKg * (bodyFatPercentage / 100.0);
    final leanKg = weightKg - fatKg;
    if (leanKg <= 0) return null;
    return double.parse(leanKg.toStringAsFixed(1));
  }

  /// % de Masa Magra (% Libre de Grasa)
  /// Fórmula: 100 - % grasa
  static double? calculateLeanMassPercentage(double? bodyFatPercentage) {
    if (bodyFatPercentage == null || bodyFatPercentage <= 0 || bodyFatPercentage >= 100) {
      return null;
    }
    return double.parse((100.0 - bodyFatPercentage).toStringAsFixed(1));
  }

  /// 4. Tasa Metabólica Basal (TMB / BMR) en kcal/día
  /// Utiliza la fórmula Katch-McArdle si se cuenta con % de grasa (la más precisa):
  /// TMB = 370 + (21.6 * Masa Magra en kg)
  /// Fallback a Mifflin-St Jeor si no hay % de grasa:
  /// TMB = 10 * peso + 6.25 * altura - 5 * edad + 5 (referencia estándar)
  static int? calculateBMR({
    required double? weightKg,
    required double? heightCm,
    double? bodyFatPercentage,
    int? age,
  }) {
    if (weightKg == null || weightKg <= 0) return null;

    // Katch-McArdle (si tiene % grasa)
    if (bodyFatPercentage != null && bodyFatPercentage > 0 && bodyFatPercentage < 100) {
      final leanMass = weightKg * (1.0 - (bodyFatPercentage / 100.0));
      final bmr = 370.0 + (21.6 * leanMass);
      return bmr.round();
    }

    // Mifflin-St Jeor general (si no tiene % de grasa pero sí altura y edad)
    if (heightCm != null && heightCm > 0) {
      final effectiveAge = age ?? 25;
      final bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * effectiveAge) + 5.0;
      return bmr.round();
    }

    return null;
  }

  /// 5. Gasto Energético Total Diario (TDEE) / Calorías de Mantenimiento
  /// Multiplica la TMB por el factor de actividad física
  static int? calculateTDEE({
    required int? bmr,
    required String? activityLevel,
  }) {
    if (bmr == null || bmr <= 0) return null;
    final factor = getActivityFactor(activityLevel);
    return (bmr * factor).round();
  }

  /// Factor multiplicador según nivel de actividad física
  static double getActivityFactor(String? activityLevel) {
    final clean = activityLevel?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    switch (clean) {
      case 'sedentary':
      case 'sedentario':
        return 1.2;
      case 'light':
      case 'ligero':
      case 'ligera':
        return 1.375;
      case 'moderate':
      case 'moderado':
      case 'moderada':
        return 1.55;
      case 'very_active':
      case 'muy_activo':
      case 'muy_activa':
        return 1.725;
      case 'extra_active':
      case 'atleta':
      case 'intenso':
        return 1.9;
      default:
        return 1.375; // Valor medio estándar por defecto
    }
  }

  /// 6. Rango de Peso Ideal Estimado (según IMC saludable 18.5 - 24.9)
  static (double min, double max)? calculateHealthyWeightRange(double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    final minWeight = 18.5 * (heightM * heightM);
    final maxWeight = 24.9 * (heightM * heightM);
    return (
      double.parse(minWeight.toStringAsFixed(1)),
      double.parse(maxWeight.toStringAsFixed(1)),
    );
  }

  /// 7. Cálculo de edad a partir de fecha de nacimiento
  static int? calculateAge(DateTime? birthdate) {
    if (birthdate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }
}
