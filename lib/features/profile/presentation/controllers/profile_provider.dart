import 'package:pyrosfitmovil/core/models/coach_profile_model.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/globals.dart';
import 'package:pyrosfitmovil/core/services/user_service.dart';
import 'package:pyrosfitmovil/core/services/student_service.dart';
import 'package:pyrosfitmovil/core/services/coach_service.dart';
import 'package:pyrosfitmovil/core/services/general_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isCoach = false;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _coachData;
  CoachProfile? _coachProfile;

  String? _qrBase64;
  String? _urlToShare;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isEditing => _isEditing;
  bool get isCoach => _isCoach;

  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get studentData => _studentData;
  Map<String, dynamic>? get coachData => _coachData;
  CoachProfile? get coachProfile => _coachProfile;

  int get coachActiveStudents =>
      _coachProfile?.activeStudents ??
      (_coachData?['activeStudents'] as num?)?.toInt() ??
      (_coachData?['totalStudents'] as num?)?.toInt() ??
      (_coachData?['studentsCount'] as num?)?.toInt() ??
      0;

  int get coachTotalRoutines =>
      _coachProfile?.totalRoutinesCreated ??
      (_coachData?['totalRoutinesCreated'] as num?)?.toInt() ??
      (_coachData?['routinesCount'] as num?)?.toInt() ??
      0;

  double get coachAverageRating =>
      _coachProfile?.averageRating ??
      (_coachData?['averageRating'] as num?)?.toDouble() ??
      (_coachData?['rating'] as num?)?.toDouble() ??
      0.0;

  int get coachExperienceYears =>
      _coachProfile?.yearsOfExperience ??
      (_coachData?['yearsOfExperience'] as num?)?.toInt() ??
      (_coachData?['experienceYears'] as num?)?.toInt() ??
      0;


  String? get qrBase64 => _qrBase64;
  String? get urlToShare => _urlToShare;

  String? get profilePictureKey =>
      _userData?['profilePictureKey'] ??
      _userData?['profilePicture'] ??
      _coachData?['profilePictureKey'] ??
      _coachData?['profilePicture'] ??
      _studentData?['profilePictureKey'] ??
      _studentData?['profilePicture'];

  String? get profilePictureUrl =>
      _userData?['profilePictureUrl'] ??
      (profilePictureKey != null
          ? StorageService.getServeUrl(profilePictureKey)
          : null);

  String? get bannerPictureKey {
    final key = _coachData?['bannerPictureKey'] ??
        _coachData?['bannerPicture'] ??
        _coachData?['bannerUrl'] ??
        _userData?['bannerPictureKey'] ??
        _userData?['bannerPicture'] ??
        _userData?['bannerUrl'];
    if (key != null && key.toString().trim().isNotEmpty) {
      return key.toString().trim();
    }
    return null;
  }

  String? get bannerPictureUrl {
    final direct = _coachData?['bannerPictureUrl'] ??
        _userData?['bannerPictureUrl'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }
    final key = bannerPictureKey;
    if (key != null && key.isNotEmpty) {
      return StorageService.getServeUrl(key);
    }
    return null;
  }

  // Variables editables (Estudiante)
  double? editingWeight;
  double? editingHeight;
  double? editingBodyFatPercentage;
  String? editingActivityLevel;
  String? editingMedicalConditions;
  String? editingAllergies;
  String? editingFitnessGoal;

  // Variables editables (Entrenador)
  String? editingBio;
  String? editingCertifications;
  String? editingBannerUrl;
  int? editingYearsOfExperience;

  Future<void> fetchProfile(int userId, bool isCoach, {AuthProvider? authProvider}) async {
    _isLoading = true;
    _isCoach = isCoach;
    notifyListeners();

    try {
      final data = await UserService.getUserDetails(userId.toString());
      logger.i(data);
      if (data['data'] != null) {
        _userData = data['data'];
        _studentData = _userData?['student'];
        _coachData = _userData?['coach'];

        // Sincronizar con AuthProvider global si se proporcionó
        if (authProvider != null) {
          final pKey = profilePictureKey;
          if (pKey != null && pKey.isNotEmpty) {
            authProvider.updateProfilePicture(pKey, profilePictureUrl);
          }
          final bKey = bannerPictureKey;
          if (bKey != null && bKey.isNotEmpty) {
            authProvider.updateBannerPicture(bKey, bannerPictureUrl);
          }
        }
      }
      logger.i(_coachData);

      if (isCoach && _coachData != null) {
        final coachId = _coachData!['id'];
        if (coachId != null && coachId is int) {
          try {
            final profile = await CoachService.getCoachProfile(coachId);
            if (profile != null) {
              _coachProfile = profile;
              _coachData = {
                ..._coachData!,
                ...profile.toJson(),
                'experienceYears': profile.yearsOfExperience,
                'yearsOfExperience': profile.yearsOfExperience,
              };
            }
          } catch (err) {
            logger.w("Error al cargar métricas dinámicas del coach: $err");
          }
        }
        _initCoachEditingValues();
        final qrData = await GeneralService.getQr(coachId);
        logger.i('qrData: $qrData');
        if (qrData != null && qrData['data'] != null) {
          _qrBase64 = qrData['data']['base64'];
          logger.i('_qrBase64: $_qrBase64');
        }
        _urlToShare = 'https://pyrosfit.com/register-info?coachId=$coachId';
      } else if (!isCoach && _studentData != null) {
        _initEditingValues();
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error, por favor intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      logger.e("Error fetching profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initEditingValues() {
    editingWeight = _studentData?['weight']?.toDouble();
    editingHeight = _studentData?['height']?.toDouble();
    editingBodyFatPercentage = _studentData?['bodyFatPercentage']?.toDouble();
    editingActivityLevel = _studentData?['activityLevel'];
    editingMedicalConditions = _studentData?['medicalConditions'];
    editingAllergies = _studentData?['allergies'];
    editingFitnessGoal = _studentData?['fitnessGoal'];
  }

  void _initCoachEditingValues() {
    editingBio = _coachData?['bio'] ?? '';
    editingCertifications = _coachData?['certifications'] ?? '';
    editingBannerUrl = bannerPictureUrl ?? bannerPictureKey ?? _coachData?['bannerUrl'] ?? '';
    editingYearsOfExperience = coachExperienceYears;
  }

  void setEditing(bool val) {
    _isEditing = val;
    if (!val) {
      // Revertir a valores originales si cancela
      if (_isCoach) {
        _initCoachEditingValues();
      } else {
        _initEditingValues();
      }
    }
    notifyListeners();
  }

  void setBanner(String base64Image) {
    editingBannerUrl = base64Image;
    if (_coachData != null) {
      _coachData = {
        ..._coachData!,
        'bannerUrl': base64Image,
      };
    }
    _isEditing = true;
    notifyListeners();
  }

  void updateBannerPicture(String? key, String? url) {
    editingBannerUrl = url ?? key ?? '';
    if (_coachData != null) {
      _coachData = {
        ..._coachData!,
        'bannerPictureKey': key,
        'bannerPicture': key,
        'bannerPictureUrl': url,
        'bannerUrl': url ?? key,
      };
    }
    if (_userData != null) {
      _userData = {
        ..._userData!,
        'bannerPictureKey': key,
        'bannerPicture': key,
        'bannerPictureUrl': url,
        'bannerUrl': url ?? key,
      };
    }
    notifyListeners();
  }

  void updateProfilePicture(String? key, String? url) {
    if (_userData != null) {
      _userData = {
        ..._userData!,
        'profilePictureKey': key,
        'profilePictureUrl': url,
        'profilePicture': key,
      };
    }
    if (_coachData != null) {
      _coachData = {
        ..._coachData!,
        'profilePictureKey': key,
        'profilePictureUrl': url,
        'profilePicture': key,
      };
    }
    if (_studentData != null) {
      _studentData = {
        ..._studentData!,
        'profilePictureKey': key,
        'profilePictureUrl': url,
        'profilePicture': key,
      };
    }
    notifyListeners();
  }

  void removeBanner() {
    editingBannerUrl = '';
    if (_coachData != null) {
      _coachData = {
        ..._coachData!,
        'bannerUrl': '',
        'bannerPictureKey': '',
        'bannerPicture': '',
        'bannerPictureUrl': '',
      };
    }
    if (_userData != null) {
      _userData = {
        ..._userData!,
        'bannerPictureKey': '',
        'bannerPicture': '',
        'bannerPictureUrl': '',
        'bannerUrl': '',
      };
    }
    _isEditing = true;
    notifyListeners();
  }

  void updateField(String field, dynamic value) {
    switch (field) {
      case 'weight':
        editingWeight = double.tryParse(value.toString());
        break;
      case 'height':
        editingHeight = double.tryParse(value.toString());
        break;
      case 'bodyFatPercentage':
        editingBodyFatPercentage = double.tryParse(value.toString());
        break;
      case 'activityLevel':
        editingActivityLevel = value;
        break;
      case 'medicalConditions':
        editingMedicalConditions = value;
        break;
      case 'allergies':
        editingAllergies = value;
        break;
      case 'fitnessGoal':
        editingFitnessGoal = value;
        break;
    }
    notifyListeners();
  }

  void updateCoachField(String field, dynamic value) {
    switch (field) {
      case 'bio':
        editingBio = value?.toString();
        break;
      case 'certifications':
        editingCertifications = value?.toString();
        break;
      case 'bannerUrl':
        editingBannerUrl = value?.toString();
        break;
      case 'yearsOfExperience':
      case 'experienceYears':
        editingYearsOfExperience = int.tryParse(value?.toString() ?? '') ?? 0;
        break;
    }
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    if (_isCoach) {
      return await saveCoachProfile();
    } else {
      return await saveStudentProfile();
    }
  }

  Future<bool> saveStudentProfile() async {
    if (_studentData == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final studentId = _studentData!['id'];
      final updateData = {
        ..._studentData!,
        'weight': editingWeight,
        'height': editingHeight,
        'bodyFatPercentage': editingBodyFatPercentage,
        'activityLevel': editingActivityLevel,
        'medicalConditions': editingMedicalConditions,
        'allergies': editingAllergies,
        'fitnessGoal': editingFitnessGoal,
      };

      final fullData = {..._userData!, 'student': updateData};
      await StudentService.updateStudent(studentId, fullData);

      _studentData = updateData;
      _isEditing = false;
      return true;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error, por favor intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      logger.e("Error saving student profile: $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveCoachProfile() async {
    if (_coachData == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final coachId = _coachData!['id'];
      final updateData = {
        ..._coachData!,
        'bio': editingBio,
        'certifications': editingCertifications,
        'bannerUrl': editingBannerUrl,
        'yearsOfExperience': editingYearsOfExperience ?? coachExperienceYears,
        'experienceYears': editingYearsOfExperience ?? coachExperienceYears,
      };

      if (coachId != null && coachId is int) {
        await CoachService.updateCoach(coachId, updateData);
      }

      _coachData = updateData;
      if (_coachProfile != null) {
        _coachProfile = _coachProfile!.copyWith(
          bio: editingBio,
          certifications: editingCertifications,
          bannerPicture: editingBannerUrl,
          yearsOfExperience: editingYearsOfExperience ?? coachExperienceYears,
        );
      }
      _isEditing = false;
      return true;
    } catch (e) {
      logger.e("Error saving coach profile: $e");
      // En caso de que el endpoint específico de coach aún no persista en backend,
      // actualizamos el estado local como en la web
      _coachData = {
        ..._coachData!,
        'bio': editingBio,
        'certifications': editingCertifications,
        'bannerUrl': editingBannerUrl,
      };
      _isEditing = false;
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
