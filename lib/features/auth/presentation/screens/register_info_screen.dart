import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/features/auth/presentation/widgets/registration_form_widget.dart';
import 'package:pyrosfitmovil/core/models/country_model.dart';
import 'package:pyrosfitmovil/core/models/phone_code_model.dart';
import 'package:pyrosfitmovil/core/services/general_service.dart';
import 'package:pyrosfitmovil/features/auth/data/services/auth_service.dart';

class RegisterInfoScreen extends StatefulWidget {
  const RegisterInfoScreen({super.key});

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
        await AuthService.register(form);
      },
    );
  }
}
