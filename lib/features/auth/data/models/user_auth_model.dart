/// =========================================================================
/// 1. Tipo de Rol (Equivalente a export type Role = "student" | "coach")
/// En Dart es mucho más seguro usar un Enum que strings planos.
/// =========================================================================
enum Role {
  student,
  coach;

  // Convierte un String del backend en un valor del Enum de forma segura
  static Role fromString(String role) {
    return Role.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => Role.student,
    );
  }
}

/// =========================================================================
/// 2. UserAuth Interface
/// =========================================================================
class UserAuth {
  final int id;
  final int? studentId;
  final int?
      coachId; // El signo '?' hace que la propiedad sea opcional (nullable)
  final String? email;
  final String? firstName;
  final Role? role;

  UserAuth({
    required this.id,
    this.studentId,
    this.coachId,
    this.email,
    this.firstName,
    this.role,
  });

  factory UserAuth.fromJson(Map<String, dynamic> json) {
    return UserAuth(
      id: json['id'] as int,
      studentId: json['studentId'] as int?,
      coachId: json['coachId'] as int?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      role:
          json['role'] != null ? Role.fromString(json['role'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'coachId': coachId,
      'email': email,
      'firstName': firstName,
      'role':
          role?.name, // Guarda el enum como string puro ("student" o "coach")
    };
  }
}

/// =========================================================================
/// 3. LoginCredentials Interface
/// =========================================================================
class LoginCredentials {
  final String userName;
  final String password;

  LoginCredentials({
    required this.userName,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
    };
  }
}

/// =========================================================================
/// 4. RegisterCredentials Interface
/// =========================================================================
class RegisterCredentials {
  final String firstName;
  final String lastName;
  final String email;
  final String userName;
  final String password;
  final String confirmPassword;
  final String phoneNumber;
  final int countryId;
  final int cityId;
  final String address;
  final String birthdate;
  final double? weight; // En Dart, los decimales usan double en vez de number
  final String? fitnessGoal; // Reemplaza por tu clase Goal si la tienes creada

  RegisterCredentials({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userName,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
    required this.countryId,
    required this.cityId,
    required this.address,
    required this.birthdate,
    this.weight,
    this.fitnessGoal,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'userName': userName,
      'password': password,
      'confirmPassword': confirmPassword,
      'phoneNumber': phoneNumber,
      'countryId': countryId,
      'cityId': cityId,
      'address': address,
      'birthdate': birthdate,
      if (weight != null) 'weight': weight,
      if (fitnessGoal != null) 'fitnessGoal': fitnessGoal,
    };
  }
}

/// =========================================================================
/// 5. CoachStudent Interface
/// =========================================================================
class CoachStudent {
  final int coachId;
  final int studentId;
  final bool status;

  CoachStudent({
    required this.coachId,
    required this.studentId,
    required this.status,
  });

  factory CoachStudent.fromJson(Map<String, dynamic> json) {
    return CoachStudent(
      coachId: json['coachId'] as int,
      studentId: json['studentId'] as int,
      status: json['status'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachId': coachId,
      'studentId': studentId,
      'status': status,
    };
  }
}
