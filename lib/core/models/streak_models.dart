import 'package:flutter/material.dart';

class StudentStreakDto {
  final int studentId;
  final String? studentName;
  final int currentStreak;
  final int? longestStreak;
  final String? lastCompletedDate;
  final int freezeShieldsAvailable;
  final String? updatedAt;
  final bool isCompletedToday;
  final int? daysInactive;
  final String? status;

  StudentStreakDto({
    required this.studentId,
    this.studentName,
    required this.currentStreak,
    this.longestStreak,
    this.lastCompletedDate,
    required this.freezeShieldsAvailable,
    this.updatedAt,
    required this.isCompletedToday,
    this.daysInactive,
    this.status,
  });

  factory StudentStreakDto.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return StudentStreakDto(
      studentId: parseInt(json['studentId']) ?? 0,
      studentName: json['studentName'] as String?,
      currentStreak: parseInt(json['currentStreak']) ?? 0,
      longestStreak: parseInt(json['longestStreak'] ?? json['maxStreak']),
      lastCompletedDate: (json['lastCompletedDate'] ?? json['lastActivityDate']) as String?,
      freezeShieldsAvailable: parseInt(json['freezeShieldsAvailable'] ?? json['shieldsAvailable']) ?? 0,
      updatedAt: json['updatedAt'] as String?,
      isCompletedToday: parseBool(json['isCompletedToday']),
      daysInactive: parseInt(json['daysInactive'] ?? json['skippedDaysCount']),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate,
      'freezeShieldsAvailable': freezeShieldsAvailable,
      'updatedAt': updatedAt,
      'isCompletedToday': isCompletedToday,
      'daysInactive': daysInactive,
      'status': status,
    };
  }
}

class WorkoutCompletedDto {
  final int studentId;
  final String activityDate;

  WorkoutCompletedDto({
    required this.studentId,
    required this.activityDate,
  });

  factory WorkoutCompletedDto.fromJson(Map<String, dynamic> json) {
    return WorkoutCompletedDto(
      studentId: json['studentId'] is int ? json['studentId'] : int.tryParse(json['studentId'].toString()) ?? 0,
      activityDate: json['activityDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'activityDate': activityDate,
    };
  }
}

class RiskRadarStudentDto {
  final int studentId;
  final String? studentName;
  final int? currentStreak;
  final int? daysInactive;
  final int? riskLevel;

  RiskRadarStudentDto({
    required this.studentId,
    this.studentName,
    this.currentStreak,
    this.daysInactive,
    this.riskLevel,
  });

  factory RiskRadarStudentDto.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return RiskRadarStudentDto(
      studentId: parseInt(json['studentId']) ?? 0,
      studentName: json['studentName'] as String?,
      currentStreak: parseInt(json['currentStreak']),
      daysInactive: parseInt(json['daysInactive']),
      riskLevel: parseInt(json['riskLevel']),
    );
  }
}

class StreakHistoryLogDto {
  final int id;
  final int studentId;
  final int? activityTypeId;
  final String? activityTypeCode;
  final String? activityTypeName;
  final String? activityDate;
  final String? createdAt;

  StreakHistoryLogDto({
    required this.id,
    required this.studentId,
    this.activityTypeId,
    this.activityTypeCode,
    this.activityTypeName,
    this.activityDate,
    this.createdAt,
  });

  factory StreakHistoryLogDto.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return StreakHistoryLogDto(
      id: parseInt(json['id']) ?? 0,
      studentId: parseInt(json['studentId']) ?? 0,
      activityTypeId: parseInt(json['activityTypeId']),
      activityTypeCode: json['activityTypeCode'] as String?,
      activityTypeName: json['activityTypeName'] as String?,
      activityDate: json['activityDate'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class HistoryItem {
  final String name;
  final String date;
  final int min;

  HistoryItem({
    required this.name,
    required this.date,
    required this.min,
  });
}

class UseFreezeShieldDto {
  final String? shieldDate;

  UseFreezeShieldDto({this.shieldDate});

  Map<String, dynamic> toJson() {
    return {
      if (shieldDate != null) 'shieldDate': shieldDate,
    };
  }
}

class StreakTier {
  final int min;
  final String label;
  final Gradient cardGradient;
  final Gradient orbGradient;
  final List<BoxShadow> glow;
  final Color textColor;
  final Color ringColor;

  const StreakTier({
    required this.min,
    required this.label,
    required this.cardGradient,
    required this.orbGradient,
    required this.glow,
    required this.textColor,
    required this.ringColor,
  });
}
