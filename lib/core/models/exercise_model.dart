class ExerciseModel {
  final int id;
  final int? coachId;
  final String name;
  final String? description;
  final int muscleGroupId;
  final String muscleGroup;
  final String? videoKey;
  final String? videoUrl;
  final bool isCustom;

  ExerciseModel({
    required this.id,
    this.coachId,
    required this.name,
    this.description,
    required this.muscleGroupId,
    this.muscleGroup = '',
    this.videoKey,
    this.videoUrl,
    this.isCustom = true,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as int? ?? 0,
      coachId: json['coachId'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      muscleGroupId: json['muscleGroupId'] as int? ?? 1,
      muscleGroup: json['muscleGroup'] as String? ?? json['muscleGroupName'] as String? ?? '',
      videoKey: json['videoKey'] as String?,
      videoUrl: json['videoUrl'] as String?,
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachId': coachId,
      'name': name,
      'description': description,
      'muscleGroupId': muscleGroupId,
      'videoKey': videoKey,
      'videoUrl': videoUrl,
      'isCustom': isCustom,
    };
  }

  ExerciseModel copyWith({
    int? id,
    int? coachId,
    String? name,
    String? description,
    int? muscleGroupId,
    String? muscleGroup,
    String? videoKey,
    String? videoUrl,
    bool? isCustom,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      name: name ?? this.name,
      description: description ?? this.description,
      muscleGroupId: muscleGroupId ?? this.muscleGroupId,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      videoKey: videoKey ?? this.videoKey,
      videoUrl: videoUrl ?? this.videoUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  bool get hasVideo => (videoKey != null && videoKey!.trim().isNotEmpty) ||
                       (videoUrl != null && videoUrl!.trim().isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
