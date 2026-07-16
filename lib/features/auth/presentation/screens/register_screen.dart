import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/features/auth/presentation/widgets/registration_form_widget.dart';
import 'package:pyrosfitmovil/core/models/country_model.dart';
import 'package:pyrosfitmovil/core/models/phone_code_model.dart';
import 'package:pyrosfitmovil/core/services/general_service.dart';
import 'package:pyrosfitmovil/features/auth/data/services/auth_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/core/widgets/spinner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: context.pyrosStyles.buildMeshBackground(
          child: const Center(child: Spinner(size: 60, label: 'Cargando')),
        ),
      );
    }

    return RegistrationFormWidget(
      type: "coach",
      countries: countries,
      phoneCodes: phoneCodes,
      title: "Crear Cuenta",
      subtitle: "",
      successTitle: "¡Registro exitoso!",
      successMessage: (form) =>
          "Gracias ${form.firstName}, tu cuenta de entrenador ha sido creada correctamente. Ya puedes iniciar sesión.",
      onSubmit: (form) async {
        await AuthService.register(form);
      },
    );
  }
}
