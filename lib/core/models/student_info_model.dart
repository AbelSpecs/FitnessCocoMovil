import 'package:pyrosfitmovil/core/services/storage_service.dart';

class StudentInfo {
  final int studentId;
  final int? userId;
  final String name;
  final String fitnessGoal;
  final String plan;
  final int streak;
  final String? profilePictureKey;
  final String? profilePictureUrl;

  StudentInfo({
    required this.studentId,
    this.userId,
    required this.name,
    required this.fitnessGoal,
    required this.plan,
    required this.streak,
    this.profilePictureKey,
    this.profilePictureUrl,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is double) return v.toInt();
      return null;
    }

    final rawUserId = parseInt(json['userId'] ?? (json['user'] is Map ? json['user']['id'] : null));
    final key = (json['profilePictureKey'] ??
        json['profilePicture'] ??
        json['profilePictureUrl'] ??
        json['avatar']) as String?;

    String? resolvedUrl;
    if (key != null && key.trim().isNotEmpty) {
      resolvedUrl = StorageService.getServeUrl(key);
    } else if (rawUserId != null && rawUserId > 0) {
      resolvedUrl = StorageService.getUserProfileUrl(rawUserId);
    }

    return StudentInfo(
      studentId: parseInt(json['studentId']) ?? parseInt(json['id']) ?? 0,
      userId: rawUserId,
      name: json['name'] as String? ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      fitnessGoal: json['fitnessGoal'] as String? ?? '',
      plan: json['plan'] as String? ?? 'basic',
      streak: parseInt(json['streak']) ?? 0,
      profilePictureKey: key,
      profilePictureUrl: resolvedUrl,
    );
  }

  StudentInfo copyWith({
    int? studentId,
    int? userId,
    String? name,
    String? fitnessGoal,
    String? plan,
    int? streak,
    String? profilePictureKey,
    String? profilePictureUrl,
  }) {
    return StudentInfo(
      studentId: studentId ?? this.studentId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      plan: plan ?? this.plan,
      streak: streak ?? this.streak,
      profilePictureKey: profilePictureKey ?? this.profilePictureKey,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
