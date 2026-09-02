import 'package:pyrosfitmovil/core/services/storage_service.dart';

class StudentInfo {
  final int studentId;
  final String name;
  final String fitnessGoal;
  final String plan;
  final int streak;
  final String? profilePictureKey;
  final String? profilePictureUrl;

  StudentInfo({
    required this.studentId,
    required this.name,
    required this.fitnessGoal,
    required this.plan,
    required this.streak,
    this.profilePictureKey,
    this.profilePictureUrl,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    final key = (json['profilePictureKey'] ??
        json['profilePicture'] ??
        json['profilePictureUrl'] ??
        json['avatar']) as String?;
    final url = key != null && key.isNotEmpty
        ? StorageService.getServeUrl(key)
        : null;

    return StudentInfo(
      studentId: json['studentId'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      fitnessGoal: json['fitnessGoal'] as String? ?? '',
      plan: json['plan'] as String? ?? 'basic',
      streak: json['streak'] as int? ?? 0,
      profilePictureKey: key,
      profilePictureUrl: url,
    );
  }
}
