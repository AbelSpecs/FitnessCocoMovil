import 'package:pyrosfitmovil/core/services/student_service.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/features/auth/presentation/widgets/registration_form_widget.dart';
import 'package:pyrosfitmovil/core/models/country_model.dart';
import 'package:pyrosfitmovil/core/models/phone_code_model.dart';
import 'package:pyrosfitmovil/core/services/general_service.dart';
import 'package:pyrosfitmovil/features/auth/data/services/auth_service.dart';

class RegisterInfoScreen extends StatefulWidget {
  final int? coachId;
  const RegisterInfoScreen({super.key, this.coachId});

  @override
  State<RegisterInfoScreen> createState() => _RegisterInfoScreenState();
}

class _RegisterInfoScreenState extends State<RegisterInfoScreen> {
  List<Country> countries = [];
  List<PhoneCode> phoneCodes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final futures = await Future.wait([
      GeneralService.getCountries(),
      GeneralService.getPhoneCodes(),
    ]);
    setState(() {
      countries = futures[0] as List<Country>;
      phoneCodes = futures[1] as List<PhoneCode>;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
      );
    }

    return RegistrationFormWidget(
      type: "student",
      countries: countries,
      phoneCodes: phoneCodes,
      title: "Información Personal",
      subtitle: "Cuéntanos sobre ti para personalizar tu entrenamiento",
      successTitle: "¡Registro exitoso!",
      successMessage: (form) =>
          "Gracias ${form.firstName}, tus datos se han registrado correctamente. Ya puedes iniciar sesión.",
      onSubmit: (form) async {
        final data = await AuthService.register(form);
        final rawId = data?['id'] ?? data?['userId'];
        final int? userId =
            rawId != null ? int.tryParse(rawId.toString()) : null;

        if (userId == null || userId <= 0) {
          throw Exception(
              "No se pudo obtener el identificador del usuario registrado.");
        }

        final clientData = await StudentService.createStudent({
          'userId': userId,
          'weight': form.weight ?? 70.0,
          'height': 0,
          'bodyFatPercentage': 0,
          'fitnessGoal': (form.fitnessGoal != null && form.fitnessGoal!.isNotEmpty)
              ? form.fitnessGoal
              : 'muscle',
          'activityLevel': '',
          'medicalConditions': '',
          'allergies': '',
          'fitnessExperience': '',
          'generalNotes': '',
          'gymId': 1,
        });

        final studentRawId = clientData?['id'] ?? clientData?['studentId'] ?? clientData?['data'];
        final int? studentId = studentRawId != null
            ? int.tryParse(studentRawId.toString())
            : null;

        // Los usuarios independientes se linkean bajo coachId = 9. Si vienen con otro coachId de invitación, se linkean a ese entrenador.
        final effectiveCoachId = (widget.coachId != null && widget.coachId! > 0)
            ? widget.coachId!
            : 9;

        if (studentId != null) {
          await AuthService.associateCoach(CoachStudent(
            coachId: effectiveCoachId,
            studentId: studentId,
            status: true,
          ));
        }
      },
    );
  }
}
