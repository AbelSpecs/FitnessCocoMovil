import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/globals.dart';
import 'package:pyrosfitmovil/core/services/user_service.dart';
import 'package:pyrosfitmovil/core/services/student_service.dart';
import 'package:pyrosfitmovil/core/services/general_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _coachData;

  String? _qrBase64;
  String? _urlToShare;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isEditing => _isEditing;

  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get studentData => _studentData;
  Map<String, dynamic>? get coachData => _coachData;

  String? get qrBase64 => _qrBase64;
  String? get urlToShare => _urlToShare;

  // Variables editables (Estudiante)
  double? editingWeight;
  double? editingHeight;
  double? editingBodyFatPercentage;
  String? editingActivityLevel;
  String? editingMedicalConditions;
  String? editingAllergies;
  String? editingFitnessGoal;

  Future<void> fetchProfile(int userId, bool isCoach) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await UserService.getUserDetails(userId.toString());
      logger.i(data);
      if (data['data'] != null) {
        _userData = data['data'];
        _studentData = _userData?['student'];
        _coachData = _userData?['coach'];
      }
      logger.i(_coachData);

      if (isCoach && _coachData != null) {
        final coachId = _coachData!['id'];
        final qrData = await GeneralService.getQr(coachId);
        logger.i('qrData: $qrData');
        if (qrData != null && qrData['data'] != null) {
          _qrBase64 = qrData['data']['base64'];
          logger.i('_qrBase64: $_qrBase64');
        }
        // Base URL podría venir del env, usamos un dummy similar al web
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

  void setEditing(bool val) {
    _isEditing = val;
    if (!val) {
      // Revertir a valores originales si cancela
      _initEditingValues();
    }
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

  Future<bool> saveProfile() async {
    if (_studentData == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final studentId = _studentData!['id'];
      final updateData = {
        ..._studentData!, // enviamos el resto de datos
        'weight': editingWeight,
        'height': editingHeight,
        'bodyFatPercentage': editingBodyFatPercentage,
        'activityLevel': editingActivityLevel,
        'medicalConditions': editingMedicalConditions,
        'allergies': editingAllergies,
        'fitnessGoal': editingFitnessGoal,
      };

      // OJO: La web app envía userData completo (incluyendo `user` y `student`),
      // pero el endpoint es `api.put("/Students/${studentId}", studentData)`
      // y en la web userData envuelve todo. Vamos a empaquetarlo como la web si es necesario.
      // Aquí estamos pasando 'studentData' al _api.put('/Students/$id', data: data)
      // Así que debería bastar.

      // Simularemos que enviamos todo el objeto userData completo actualizado
      final fullData = {..._userData!, 'student': updateData};

      await StudentService.updateStudent(studentId, fullData);

      // Actualizamos estado local
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
      logger.e("Error saving profile: $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
