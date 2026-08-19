import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';

const List<StreakTier> streakTiers = [
  StreakTier(
    min: 0,
    label: 'Chispa de Esparta',
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF221F1B), Color(0xFF33261D)],
    ),
    orbGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE28B36), Color(0xFFC76F26)],
    ),
    glow: [
      BoxShadow(
        color: Color(0x80E28B36),
        blurRadius: 30,
        offset: Offset(0, 8),
        spreadRadius: -10,
      )
    ],
    textColor: Color(0xFFF6AA50),
    ringColor: Color(0x73E28B36),
  ),
  StreakTier(
    min: 3,
    label: 'Llama Olímpica',
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF221E1A), Color(0xFF452417)],
    ),
    orbGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF2782A), Color(0xFFCC5218)],
    ),
    glow: [
      BoxShadow(
        color: Color(0x8CF2782A),
        blurRadius: 34,
        offset: Offset(0, 10),
        spreadRadius: -10,
      )
    ],
    textColor: Color(0xFFFFA05C),
    ringColor: Color(0x80F2782A),
  ),
  StreakTier(
    min: 7,
    label: 'Forja de Hefesto',
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF241814), Color(0xFF4E2014)],
    ),
    orbGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF95A0B), Color(0xFFD63B08)],
    ),
    glow: [
      BoxShadow(
        color: Color(0x99F95A0B),
        blurRadius: 38,
        offset: Offset(0, 12),
        spreadRadius: -10,
      )
    ],
    textColor: Color(0xFFFF7E3E),
    ringColor: Color(0x8CF95A0B),
  ),
  StreakTier(
    min: 14,
    label: 'Furia del Fénix',
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF261414), Color(0xFF5A1C16)],
    ),
    orbGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF3B14), Color(0xFFDC2008)],
    ),
    glow: [
      BoxShadow(
        color: Color(0xB3FF3B14),
        blurRadius: 44,
        offset: Offset(0, 14),
        spreadRadius: -10,
      )
    ],
    textColor: Color(0xFFFF6242),
    ringColor: Color(0x99FF3B14),
  ),
  StreakTier(
    min: 30,
    label: 'Fuego de los Titanes',
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B0E14), Color(0xFF6B181E)],
    ),
    orbGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF1A2C), Color(0xFFD9001D)],
    ),
    glow: [
      BoxShadow(
        color: Color(0xD9FF1A2C),
        blurRadius: 55,
        offset: Offset(0, 18),
        spreadRadius: -10,
      )
    ],
    textColor: Color(0xFFFF5264),
    ringColor: Color(0xB3FF1A2C),
  ),
];

StreakTier tierFor(int streak) {
  for (final tier in streakTiers.reversed) {
    if (streak >= tier.min) {
      return tier;
    }
  }
  return streakTiers.first;
}

StreakTier? nextTierFor(int streak) {
  for (final tier in streakTiers) {
    if (tier.min > streak) {
      return tier;
    }
  }
  return null;
}

double calculateStreakExperience(int currentStreak, [List<StreakTier>? tiers]) {
  final activeTiers = tiers ?? streakTiers;
  if (currentStreak <= 0) return 0.0;
  if (activeTiers.length <= 1) return 0.0;

  final maxMin = activeTiers.last.min;
  if (currentStreak >= maxMin) return 100.0;

  final totalSegments = activeTiers.length - 1;
  final segmentWidth = 100.0 / totalSegments;

  for (int i = 0; i < totalSegments; i++) {
    final currentMin = activeTiers[i].min;
    final nextMin = activeTiers[i + 1].min;

    if (currentStreak >= currentMin && currentStreak <= nextMin) {
      final segmentProgress = (currentStreak - currentMin) / (nextMin - currentMin);
      final startPercent = i * segmentWidth;
      final endPercent = (i + 1) * segmentWidth;
      final totalPercent = startPercent + segmentProgress * (endPercent - startPercent);
      return totalPercent.clamp(0.0, 100.0);
    }
  }

  return 100.0;
}

/// Calcula el peso máximo levantado a partir de los sets reales de los ejercicios
double calculateMaxWeightLifted(List<GetDailyStudentExerciseDto> exercises) {
  double maxWeight = 0;
  for (final ex in exercises) {
    if (ex.dailyExerciseSets.isNotEmpty) {
      for (final set in ex.dailyExerciseSets) {
        final actualWeight = set.actualWeight != null
            ? (double.tryParse(set.actualWeight.toString()) ?? 0.0)
            : 0.0;
        if (actualWeight > maxWeight) {
          maxWeight = actualWeight;
        }
      }
    }
  }
  return maxWeight;
}

/// Calcula la duración total de la rutina en segundos
int calculateRoutineDurationInSeconds(List<GetDailyStudentExerciseDto> exercises) {
  int totalSeconds = 0;
  for (final ex in exercises) {
    if (ex.dailyExerciseSets.isNotEmpty) {
      for (final set in ex.dailyExerciseSets) {
        // Asume 45 segundos de ejecución por set
        totalSeconds += 45;
        if (set.restTime.isNotEmpty) {
          final restStr = set.restTime.trim();
          if (restStr.contains(':')) {
            final parts = restStr.split(':').map((p) => int.tryParse(p) ?? 0).toList();
            if (parts.length == 3) {
              totalSeconds += parts[0] * 3600 + parts[1] * 60 + parts[2];
            } else if (parts.length == 2) {
              totalSeconds += parts[0] * 60 + parts[1];
            }
          } else {
            final num = int.tryParse(restStr);
            if (num != null && num > 0) {
              totalSeconds += num;
            }
          }
        }
      }
    }
  }
  return totalSeconds > 0 ? totalSeconds : 1;
}

/// Calcula la duración de la rutina en minutos (mínimo 1)
int calculateRoutineDurationInMin(List<GetDailyStudentExerciseDto> exercises) {
  final seconds = calculateRoutineDurationInSeconds(exercises);
  final mins = (seconds / 60).round();
  return mins > 0 ? mins : 1;
}

/// Formatea una duración en segundos para diferenciar segundos (s), minutos (min) y horas (h).
/// Ejemplos:
/// - 1 -> "1 s"
/// - 45 -> "45 s"
/// - 120 -> "2 min"
/// - 150 -> "2 min 30 s"
/// - 3600 -> "1 h"
/// - 3660 -> "1 h 1 min"
String formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '1 s';

  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return minutes > 0 ? '$hours h $minutes min' : '$hours h';
  }

  if (minutes > 0) {
    return seconds > 0 ? '$minutes min $seconds s' : '$minutes min';
  }

  return '$seconds s';
}

List<HistoryItem> historyExercisesMapper(List<GetDailyStudentExerciseDto> historyExercises) {
  if (historyExercises.isEmpty) return [];

  final Map<String, List<GetDailyStudentExerciseDto>> grouped = {};

  for (final ex in historyExercises) {
    final dateKey = ex.scheduledDate.contains('T')
        ? ex.scheduledDate.split('T')[0]
        : ex.scheduledDate;
    if (dateKey.isEmpty) continue;
    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(ex);
  }

  return grouped.entries.map((entry) {
    final dateStr = entry.key;
    final exercises = entry.value;

    final muscleGroups = exercises
        .map((e) => e.muscleGroupName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final name = muscleGroups.isNotEmpty ? muscleGroups.join(' & ') : 'Rutina';
    final seconds = calculateRoutineDurationInSeconds(exercises);

    return HistoryItem(
      name: name,
      date: dateStr,
      seconds: seconds,
      min: (seconds / 60).round(),
    );
  }).toList();
}

List<HistoryItem> streakHistoryMapper(List<StreakHistoryLogDto> streakHistoryLogs) {
  if (streakHistoryLogs.isEmpty) return [];

  return streakHistoryLogs.map((log) {
    final rawDate = log.activityDate ?? log.createdAt ?? '';
    final formattedDate = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;

    return HistoryItem(
      name: (log.activityTypeName != null && log.activityTypeName!.isNotEmpty)
          ? log.activityTypeName!
          : 'Entrenamiento',
      date: formattedDate,
      seconds: 1, // En caso de no tener tiempo se coloca 1s
      min: 0,
    );
  }).toList();
}

List<HistoryItem> combinedHistoryMapper(
  List<StreakHistoryLogDto>? streakHistoryLogs,
  List<GetDailyStudentExerciseDto>? lastCompletedExercises,
) {
  final mappedStreakLogs = streakHistoryLogs != null ? streakHistoryMapper(streakHistoryLogs) : <HistoryItem>[];
  final mappedExercises = lastCompletedExercises != null ? historyExercisesMapper(lastCompletedExercises) : <HistoryItem>[];

  final combined = [...mappedStreakLogs, ...mappedExercises];

  // Ordenar de más reciente a más antiguo y devolver solo los 4 más recientes
  combined.sort((a, b) {
    final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
    final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
    return dateB.compareTo(dateA);
  });

  return combined.take(4).toList();
}

const List<RiskStudentInfo> defaultStudentsMock = [
  RiskStudentInfo(
    studentId: '1',
    name: 'Carlos Mendoza',
    initials: 'CM',
    streak: 0,
    lastWorkout: 'Hace 5 días',
    inactivity: 5,
    risk: 'high',
  ),
  RiskStudentInfo(
    studentId: '2',
    name: 'Sofía Rodríguez',
    initials: 'SR',
    streak: 2,
    lastWorkout: 'Hace 3 días',
    inactivity: 3,
    risk: 'medium',
  ),
  RiskStudentInfo(
    studentId: '3',
    name: 'María Gómez',
    initials: 'MG',
    streak: 14,
    lastWorkout: 'Ayer',
    inactivity: 1,
    risk: 'low',
  ),
  RiskStudentInfo(
    studentId: '4',
    name: 'Julián Ferrer',
    initials: 'JF',
    streak: 0,
    lastWorkout: 'Hace 8 días',
    inactivity: 8,
    risk: 'high',
  ),
  RiskStudentInfo(
    studentId: '5',
    name: 'Lucía Ibarra',
    initials: 'LI',
    streak: 6,
    lastWorkout: 'Hoy',
    inactivity: 0,
    risk: 'low',
  ),
  RiskStudentInfo(
    studentId: '6',
    name: 'Diego Salas',
    initials: 'DS',
    streak: 1,
    lastWorkout: 'Hace 3 días',
    inactivity: 3,
    risk: 'medium',
  ),
];

List<RiskStudentInfo> riskRadarStudentsMapper(List<RiskRadarStudentDto>? riskRadarList) {
  if (riskRadarList == null || riskRadarList.isEmpty) {
    return defaultStudentsMock;
  }

  return riskRadarList.map((item) {
    final studentName = (item.studentName != null && item.studentName!.trim().isNotEmpty)
        ? item.studentName!
        : 'Alumno #${item.studentId}';
    final nameParts = studentName.trim().split(RegExp(r'\s+'));
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : studentName.length >= 2
            ? studentName.substring(0, 2).toUpperCase()
            : studentName.toUpperCase();

    final daysInactive = item.daysInactive ?? 0;
    String lastWorkout = '';
    if (daysInactive == 0) {
      lastWorkout = 'Hoy';
    } else if (daysInactive == 1) {
      lastWorkout = 'Ayer';
    } else if (daysInactive >= 999) {
      lastWorkout = 'Sin actividad';
    } else {
      lastWorkout = 'Hace $daysInactive días';
    }

    String risk = 'low';
    if (item.riskLevel == 2) {
      risk = 'high';
    } else if (item.riskLevel == 1) {
      risk = 'medium';
    } else {
      risk = 'low';
    }

    return RiskStudentInfo(
      studentId: item.studentId.toString(),
      name: studentName,
      initials: initials,
      streak: item.currentStreak ?? 0,
      lastWorkout: lastWorkout,
      inactivity: daysInactive >= 999 ? 30 : daysInactive,
      risk: risk,
    );
  }).toList();
}

const List<Map<String, dynamic>> fireTierTitles = [
  {'min': 30, 'title': 'Fuego de los Titanes'},
  {'min': 14, 'title': 'Furia del Fénix'},
  {'min': 7, 'title': 'Forja de Hefesto'},
  {'min': 3, 'title': 'Llama Olímpica'},
  {'min': 0, 'title': 'Chispa de Esparta'},
];

String getTitleForStreak(int streak) {
  for (final t in fireTierTitles) {
    if (streak >= (t['min'] as int)) {
      return t['title'] as String;
    }
  }
  return 'Chispa de Esparta';
}

List<AthleteRankingInfo> mapLeaderboardToAthletes(
  List<StreakLeaderboardItemDto>? items, {
  int currentStudentId = 0,
  String coachLabel = 'PyrosFit',
}) {
  if (items == null || items.isEmpty) {
    return [];
  }

  return items.map((item) {
    final studentName = (item.studentName.trim().isNotEmpty)
        ? item.studentName
        : 'Alumno #${item.studentId}';
    final nameParts = studentName.trim().split(RegExp(r'\s+'));
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : studentName.length >= 2
            ? studentName.substring(0, 2).toUpperCase()
            : studentName.toUpperCase();

    final streak = item.currentStreak;
    final longestStreak = item.longestStreak;
    final points = streak * 100 + longestStreak * 25 + item.freezeShieldsAvailable * 10;
    final title = getTitleForStreak(streak);

    return AthleteRankingInfo(
      id: item.studentId.toString(),
      name: studentName,
      initials: initials,
      coach: coachLabel,
      points: points,
      streak: streak,
      longestStreak: longestStreak,
      volume: streak * 1250,
      sessions: streak,
      delta: 0,
      title: title,
      me: item.studentId == currentStudentId,
    );
  }).toList();
}
