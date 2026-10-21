import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';

/// Clasificación de cada añadido o cambio en la versión
enum ReleaseItemType {
  feature,     // Nueva funcionalidad
  improvement, // Mejora de algo existente
  fix,         // Corrección de bugs
  ui,          // Rediseño o cambio visual
  performance, // Rendimiento
}

/// Audiencia objetivo de una novedad
enum TargetAudience {
  all,     // Visible para todos los usuarios
  student, // Específico para clientes / alumnos
  coach,   // Específico para entrenadores
}

extension TargetAudienceExtension on TargetAudience {
  String get label {
    switch (this) {
      case TargetAudience.all:
        return 'TODOS';
      case TargetAudience.student:
        return 'CLIENTE';
      case TargetAudience.coach:
        return 'COACH';
    }
  }

  /// Indica si el ítem es relevante y visible para el rol del usuario actual
  bool isVisibleFor(Role? role) {
    if (this == TargetAudience.all) return true;
    if (role == Role.coach) {
      return this == TargetAudience.coach;
    } else {
      return this == TargetAudience.student;
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case TargetAudience.all:
        return Colors.white.withValues(alpha: 0.08);
      case TargetAudience.student:
        return const Color(0xFF0284C7).withValues(alpha: 0.15); // Azul / Celeste
      case TargetAudience.coach:
        return const Color(0xFFF95A0B).withValues(alpha: 0.15); // Naranja Pyros
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case TargetAudience.all:
        return const Color(0xFFACACAF);
      case TargetAudience.student:
        return const Color(0xFF38BDF8);
      case TargetAudience.coach:
        return const Color(0xFFFF8243);
    }
  }
}

extension ReleaseItemTypeExtension on ReleaseItemType {
  String get label {
    switch (this) {
      case ReleaseItemType.feature:
        return 'NUEVO';
      case ReleaseItemType.improvement:
        return 'MEJORA';
      case ReleaseItemType.fix:
        return 'CORRECCIÓN';
      case ReleaseItemType.ui:
        return 'DISEÑO';
      case ReleaseItemType.performance:
        return 'RENDIMIENTO';
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case ReleaseItemType.feature:
        return const Color(0xFFF95A0B).withValues(alpha: 0.18); // Naranja Pyros
      case ReleaseItemType.improvement:
        return const Color(0xFF0284C7).withValues(alpha: 0.18); // Azul celeste
      case ReleaseItemType.fix:
        return const Color(0xFFEAB308).withValues(alpha: 0.18); // Amarillo ámbar
      case ReleaseItemType.ui:
        return const Color(0xFFA855F7).withValues(alpha: 0.18); // Púrpura
      case ReleaseItemType.performance:
        return const Color(0xFF10B981).withValues(alpha: 0.18); // Esmeralda / Verde
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case ReleaseItemType.feature:
        return const Color(0xFFFF8243);
      case ReleaseItemType.improvement:
        return const Color(0xFF38BDF8);
      case ReleaseItemType.fix:
        return const Color(0xFFFACC15);
      case ReleaseItemType.ui:
        return const Color(0xFFC084FC);
      case ReleaseItemType.performance:
        return const Color(0xFF34D399);
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case ReleaseItemType.feature:
        return Icons.auto_awesome;
      case ReleaseItemType.improvement:
        return Icons.trending_up;
      case ReleaseItemType.fix:
        return Icons.build_circle_outlined;
      case ReleaseItemType.ui:
        return Icons.palette_outlined;
      case ReleaseItemType.performance:
        return Icons.bolt;
    }
  }
}

/// Un añadido, ajuste o corrección específico dentro de la versión
class ReleaseItem {
  final String title;
  final String description;
  final ReleaseItemType type;
  final TargetAudience audience;
  final IconData? icon;

  const ReleaseItem({
    required this.title,
    required this.description,
    this.audience = TargetAudience.all,
    this.type = ReleaseItemType.feature,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'audience': audience.name,
      'type': type.name,
    };
  }

  factory ReleaseItem.fromMap(Map<String, dynamic> map) {
    return ReleaseItem(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      audience: TargetAudience.values.firstWhere(
        (e) => e.name == map['audience'],
        orElse: () => TargetAudience.all,
      ),
      type: ReleaseItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReleaseItemType.feature,
      ),
    );
  }
}

/// Representa una versión completa de la aplicación y sus notas de lanzamiento
class ReleaseNote {
  /// Versión semántica (ej. "1.0.0", "1.1.0")
  final String version;

  /// Número de build opcional (ej. 7, 8)
  final int? buildNumber;

  /// Fecha del lanzamiento
  final DateTime releaseDate;

  /// Título destacado o lema de la versión (ej. "¡Nuevas rutinas y rankings!")
  final String title;

  /// Resumen o mensaje motivacional para el usuario
  final String? subtitle;

  /// ¿Es una actualización mayor o crítica?
  final bool isMajor;

  /// Lista de añadidos y cambios
  final List<ReleaseItem> items;

  const ReleaseNote({
    required this.version,
    this.buildNumber,
    required this.releaseDate,
    required this.title,
    this.subtitle,
    this.isMajor = false,
    required this.items,
  });

  /// Versión completa con build number si existe (ej: "1.0.0+8")
  String get fullVersion =>
      buildNumber != null ? '$version+$buildNumber' : version;

  /// Retorna los ítems filtrados según el rol del usuario (Role.coach o Role.student)
  List<ReleaseItem> filteredItemsFor(Role? role) {
    return items.where((item) => item.audience.isVisibleFor(role)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'releaseDate': releaseDate.toIso8601String(),
      'title': title,
      'subtitle': subtitle,
      'isMajor': isMajor,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory ReleaseNote.fromMap(Map<String, dynamic> map) {
    return ReleaseNote(
      version: map['version'] ?? '',
      buildNumber: map['buildNumber'],
      releaseDate: map['releaseDate'] != null
          ? DateTime.parse(map['releaseDate'])
          : DateTime.now(),
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      isMajor: map['isMajor'] ?? false,
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => ReleaseItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
