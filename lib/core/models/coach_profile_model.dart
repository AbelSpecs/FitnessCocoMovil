class CoachProfile {
  final int id;
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? bio;
  final String? certifications;
  final bool isVerified;
  final int yearsOfExperience;
  final String? profilePicture;
  final String? bannerPicture;
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int totalRoutinesCreated;
  final double averageRating;
  final int totalRatingsCount;

  CoachProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.bio,
    this.certifications,
    this.isVerified = false,
    this.yearsOfExperience = 0,
    this.profilePicture,
    this.bannerPicture,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.inactiveStudents = 0,
    this.totalRoutinesCreated = 0,
    this.averageRating = 0.0,
    this.totalRatingsCount = 0,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      bio: json['bio'] as String?,
      certifications: json['certifications'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ??
          (json['experienceYears'] as num?)?.toInt() ??
          0,
      profilePicture: json['profilePicture'] as String?,
      bannerPicture: json['bannerPicture'] as String?,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      activeStudents: (json['activeStudents'] as num?)?.toInt() ?? 0,
      inactiveStudents: (json['inactiveStudents'] as num?)?.toInt() ?? 0,
      totalRoutinesCreated: (json['totalRoutinesCreated'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      totalRatingsCount: (json['totalRatingsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'certifications': certifications,
      'isVerified': isVerified,
      'yearsOfExperience': yearsOfExperience,
      'profilePicture': profilePicture,
      'bannerPicture': bannerPicture,
      'totalStudents': totalStudents,
      'activeStudents': activeStudents,
      'inactiveStudents': inactiveStudents,
      'totalRoutinesCreated': totalRoutinesCreated,
      'averageRating': averageRating,
      'totalRatingsCount': totalRatingsCount,
    };
  }

  CoachProfile copyWith({
    int? id,
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? bio,
    String? certifications,
    bool? isVerified,
    int? yearsOfExperience,
    String? profilePicture,
    String? bannerPicture,
    int? totalStudents,
    int? activeStudents,
    int? inactiveStudents,
    int? totalRoutinesCreated,
    double? averageRating,
    int? totalRatingsCount,
  }) {
    return CoachProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      isVerified: isVerified ?? this.isVerified,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      profilePicture: profilePicture ?? this.profilePicture,
      bannerPicture: bannerPicture ?? this.bannerPicture,
      totalStudents: totalStudents ?? this.totalStudents,
      activeStudents: activeStudents ?? this.activeStudents,
      inactiveStudents: inactiveStudents ?? this.inactiveStudents,
      totalRoutinesCreated: totalRoutinesCreated ?? this.totalRoutinesCreated,
      averageRating: averageRating ?? this.averageRating,
      totalRatingsCount: totalRatingsCount ?? this.totalRatingsCount,
    );
  }
}
