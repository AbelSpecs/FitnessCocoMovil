/// Utilidades de tiempo para PyrosFit Móvil

/// Convierte una cadena de tiempo de descanso (ej. "60", "90s", "01:30", "2 min", "90 seg")
/// en la cantidad total de segundos correspondiente.
int parseRestTimeToSeconds(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 0;
  }

  final cleaned = raw.trim().toLowerCase();

  // Si contiene "min": ej. "2 min", "1.5 min", "2min"
  if (cleaned.contains('min')) {
    final numMatch = RegExp(r'^[0-9]+(\.[0-9]+)?').firstMatch(cleaned);
    if (numMatch != null) {
      final val = double.tryParse(numMatch.group(0)!) ?? 0;
      return (val * 60).round();
    }
  }

  // Formatos con dos puntos: "MM:SS" o "HH:MM:SS"
  if (cleaned.contains(':')) {
    final parts = cleaned.split(':').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    if (parts.length == 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      return parts[0] * 60 + parts[1];
    }
  }

  // Formatos numéricos directos: "90", "90s", "90 seg", "90seg"
  final match = RegExp(r'^[0-9]+').firstMatch(cleaned);
  if (match != null) {
    return int.tryParse(match.group(0)!) ?? 0;
  }

  return 0;
}

/// Formatea segundos a "MM:SS"
String formatSecondsToMS(int totalSeconds) {
  final safeSec = totalSeconds < 0 ? 0 : totalSeconds;
  final m = safeSec ~/ 60;
  final s = safeSec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Formatea el tiempo de descanso para visualización amigable en la interfaz.
/// Ejemplos:
/// - 120 -> "2 min"
/// - 90 -> "1m 30s"
/// - 60 -> "1 min"
/// - 45 -> "45s"
/// - "1:30" -> "1m 30s"
String formatRestTimeDisplay(dynamic raw) {
  final totalSeconds = parseRestTimeToSeconds(raw?.toString());
  if (totalSeconds <= 0) return '0s';

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes == 0) {
    return '${seconds}s';
  }
  if (seconds == 0) {
    return '$minutes min';
  }
  return '${minutes}m ${seconds}s';
}
