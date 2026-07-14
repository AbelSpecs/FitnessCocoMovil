import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';
import 'package:pyrosfitmovil/core/models/country_model.dart';
import 'package:pyrosfitmovil/core/models/city_model.dart';
import 'package:pyrosfitmovil/core/models/phone_code_model.dart';
import 'package:pyrosfitmovil/core/services/general_service.dart';
import 'package:pyrosfitmovil/core/utils/notify.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/core/widgets/spinner.dart';
import 'package:logger/logger.dart';
import 'dart:developer';

final logger = Logger();

class RegistrationFormWidget extends StatefulWidget {
  final String type; // "coach" or "student"
  final List<Country> countries;
  final List<PhoneCode> phoneCodes;
  final String title;
  final String subtitle;
  final String successTitle;
  final String Function(RegisterCredentials form) successMessage;
  final Future<void> Function(RegisterCredentials form) onSubmit;

  const RegistrationFormWidget({
    super.key,
    required this.type,
    required this.countries,
    required this.phoneCodes,
    required this.title,
    required this.subtitle,
    required this.successTitle,
    required this.successMessage,
    required this.onSubmit,
  });

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  int _step = 1;
  bool _loading = false;
  bool _success = false;

  final _formKey = GlobalKey<FormState>();

  // Controladores Paso 1
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Variables Paso 2
  DateTime? _birthdate;
  Country? _selectedCountry;
  List<City> _cities = [];
  City? _selectedCity;
  PhoneCode? _selectedPhoneCode;
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Variables Paso 3 (Student)
  final _weightCtrl = TextEditingController();
  String? _selectedGoal;

  final Map<String, String> _goalLabels = {
    "muscle": "Ganar Músculo",
    "strength": "Aumentar Fuerza",
    "weight_loss": "Perder Peso",
    "endurance": "Mejorar Resistencia",
    "health": "Salud General",
    "flexibility": "Mejorar Flexibilidad",
    "sports": "Rendimiento Deportivo"
  };

  int get _totalSteps => widget.type == "student" ? 3 : 2;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _userNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthdate) {
    DateTime today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleCountryChange(Country? country) async {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _cities = [];
    });
    try {
      if (country != null) {
        final cities = await GeneralService.getCities(country.id);
        setState(() {
          _cities = cities;
        });
      }
    } catch (e) {
      logger.e('Error al obtener ciudades: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF97316),
              onPrimary: Colors.white,
              surface: Color(0xFF18181B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  void _nextStep() {
    setState(() => _step++);
  }

  void _prevStep() {
    setState(() => _step--);
  }

  Future<void> _submit() async {
    // Validaciones Paso 1
    if (_firstNameCtrl.text.trim().isEmpty) {
      Notify.error(context, "Error", "El nombre es obligatorio");
      return;
    }
    if (_lastNameCtrl.text.trim().isEmpty) {
      Notify.error(context, "Error", "El apellido es obligatorio");
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      Notify.error(context, "Error", "El email es obligatorio");
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      Notify.error(context, "Error", "Introduce un correo electrónico válido");
      return;
    }
    if (_userNameCtrl.text.trim().isEmpty) {
      Notify.error(context, "Error", "El usuario es obligatorio");
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      Notify.error(context, "Error", "Las contraseñas no coinciden");
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      Notify.error(
          context, "Error", "La contraseña debe tener al menos 8 caracteres");
      return;
    }

    // Validaciones Paso 2
    if (_birthdate == null) {
      Notify.error(context, "Error", "Selecciona una fecha de nacimiento");
      return;
    }
    final age = _calculateAge(_birthdate!);
    if (age < 10 || age > 120) {
      Notify.error(context, "Error", "Ingresa una fecha de nacimiento válida");
      return;
    }
    if (_selectedCountry == null) {
      Notify.error(context, "Error", "Selecciona un país");
      return;
    }
    if (_selectedCity == null) {
      Notify.error(context, "Error", "Selecciona una ciudad");
      return;
    }
    if (_selectedPhoneCode == null) {
      Notify.error(context, "Error", "El código de teléfono es obligatorio");
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      Notify.error(context, "Error", "El teléfono es obligatorio");
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      Notify.error(context, "Error", "La dirección es obligatoria");
      return;
    }

    // Validaciones Paso 3
    if (widget.type == "student") {
      final weightVal = double.tryParse(_weightCtrl.text);
      if (weightVal == null || weightVal < 30 || weightVal > 300) {
        Notify.error(context, "Error", "El peso debe estar entre 30 y 300 kg");
        return;
      }
      if (_selectedGoal == null) {
        Notify.error(context, "Error", "Debes seleccionar un objetivo");
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final form = RegisterCredentials(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        userName: _userNameCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
        phoneNumber: "${_selectedPhoneCode!.code}${_phoneCtrl.text.trim()}",
        countryId: _selectedCountry!.id,
        cityId: _selectedCity!.id,
        address: _addressCtrl.text.trim(),
        birthdate: DateFormat('yyyy-MM-dd').format(_birthdate!),
        weight:
            widget.type == "student" ? double.tryParse(_weightCtrl.text) : null,
        fitnessGoal: widget.type == "student" ? _selectedGoal : null,
      );

      await widget.onSubmit(form);
      setState(() => _success = true);
    } catch (e) {
      Notify.error(context, "Error", "Hubo un error al procesar el formulario");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return _buildSuccessScreen();
    }

    const backgroundColor = Color(0xFF09090B);
    const borderColor = Color(0xFF27272A);
    const textMuted = Color(0xFFA1A1AA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: context.pyrosStyles.buildMeshBackground(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 32,
                children: [
                  // LOGO
                  Column(
                    spacing: 12,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [
                            Color.fromRGBO(253, 91, 11, 1),
                            Color.fromRGBO(255, 170, 48, 1)
                          ]),
                          boxShadow: const [
                            BoxShadow(
                                color: Color.fromRGBO(253, 91, 11, 0.4),
                                blurRadius: 16)
                          ],
                        ),
                        child: const Icon(Icons.fitness_center,
                            size: 32, color: Colors.white),
                      ),
                      Text('PYROSFIT',
                          style: Theme.of(context).textTheme.displayLarge),
                      const Text('TRAINING CO.',
                          style: TextStyle(
                              color: textMuted,
                              fontSize: 10,
                              letterSpacing: 2)),
                    ],
                  ),

                  // TARJETA FORMULARio
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xCC18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 24,
                        children: [
                          Column(
                            spacing: 4,
                            children: [
                              Text(widget.title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  textAlign: TextAlign.center),
                              Text(widget.subtitle,
                                  style: const TextStyle(
                                      fontSize: 14, color: textMuted),
                                  textAlign: TextAlign.center),
                            ],
                          ),

                          // Form Steps
                          if (_step == 1) _buildStep1(borderColor),
                          if (_step == 2) _buildStep2(borderColor),
                          if (_step == 3) _buildStep3(borderColor),

                          // Acciones
                          Row(
                            spacing: 12,
                            children: [
                              if (_step > 1)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _loading ? null : _prevStep,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side:
                                          const BorderSide(color: borderColor),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Anterior',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: _loading
                                        ? null
                                        : const LinearGradient(colors: [
                                            Color.fromRGBO(253, 91, 11, 1),
                                            Color.fromRGBO(255, 170, 48, 1)
                                          ]),
                                    color: _loading ? Colors.grey[800] : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : (_step == _totalSteps
                                            ? _submit
                                            : _nextStep),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Spinner(size: 20))
                                        : Text(
                                            _step == _totalSteps
                                                ? 'Registrar'
                                                : 'Siguiente',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Link Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('¿Ya tienes cuenta? ',
                                  style: TextStyle(
                                      color: textMuted, fontSize: 14)),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text('Inicia sesión',
                                    style: TextStyle(
                                        color: Color(0xFFF97316),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(Color borderColor) {
    return Column(
      spacing: 16,
      children: [
        Text('Paso 1 de $_totalSteps: Información básica',
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
        _buildInput('Nombre', _firstNameCtrl, borderColor, hintText: 'Nombre'),
        _buildInput('Apellido', _lastNameCtrl, borderColor,
            hintText: 'Apellido'),
        _buildInput('Email', _emailCtrl, borderColor,
            isEmail: true, hintText: 'tu@email.com'),
        _buildInput('Usuario', _userNameCtrl, borderColor,
            hintText: 'Nombre de usuario'),
        _buildInput('Contraseña', _passwordCtrl, borderColor,
            isPassword: true, hintText: '••••••••'),
        _buildInput('Confirmar Contraseña', _confirmPasswordCtrl, borderColor,
            isPassword: true, hintText: '••••••••'),
      ],
    );
  }

  Widget _buildStep2(Color borderColor) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Paso 2 de $_totalSteps: Información adicional',
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            textAlign: TextAlign.center),

        // Fecha Nacimiento
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            const Text('Fecha de Nacimiento',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFF27272A).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor)),
                child: Text(
                  _birthdate == null
                      ? 'Selecciona tu fecha'
                      : DateFormat('dd/MM/yyyy').format(_birthdate!),
                  style: TextStyle(
                      color: _birthdate == null
                          ? const Color(0xFF52525B)
                          : Colors.white),
                ),
              ),
            ),
          ],
        ),

        // País
        _buildDropdownSearch<Country>(
          label: 'País',
          hintText: 'Selecciona tu país',
          items: widget.countries,
          selectedItem: _selectedCountry,
          itemAsString: (c) => c.name,
          onChanged: _handleCountryChange,
          borderColor: borderColor,
        ),

        // Ciudad
        _buildDropdownSearch<City>(
          label: 'Ciudad',
          hintText: 'Selecciona la ciudad',
          items: _cities,
          selectedItem: _selectedCity,
          itemAsString: (c) => c.name,
          onChanged: (v) => setState(() => _selectedCity = v),
          borderColor: borderColor,
        ),

        // Teléfono
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text('Teléfono',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDropdownSearch<PhoneCode>(
                    label: '',
                    hintText: 'Código',
                    items: widget.phoneCodes,
                    selectedItem: _selectedPhoneCode,
                    itemAsString: (p) => p.code,
                    onChanged: (v) => setState(() => _selectedPhoneCode = v),
                    borderColor: borderColor,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '424-258-6514',
                      hintStyle: const TextStyle(
                          color: Color(0xFF52525B), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF27272A).withOpacity(0.6),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFFF97316), width: 1.5)),
                    ),
                  ),
                )
              ],
            )
          ],
        ),

        // Dirección
        _buildInput('Dirección', _addressCtrl, borderColor,
            hintText: 'Dirección'),
      ],
    );
  }

  Widget _buildStep3(Color borderColor) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Paso 3 de 3: Entrenamiento',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            textAlign: TextAlign.center),
        _buildInput('Peso (kg)', _weightCtrl, borderColor,
            isNumber: true, hintText: 'Peso (kg)'),
        const Text('Objetivos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goalLabels.entries.map((entry) {
            final isSelected = _selectedGoal == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedGoal = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF97316)
                      : const Color(0xFF27272A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          isSelected ? const Color(0xFFF97316) : borderColor),
                ),
                child: Text(entry.value,
                    style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildInput(
      String label, TextEditingController ctrl, Color borderColor,
      {bool isPassword = false,
      bool isEmail = false,
      bool isNumber = false,
      String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        TextFormField(
          controller: ctrl,
          obscureText: isPassword,
          keyboardType: isNumber
              ? TextInputType.number
              : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF27272A).withOpacity(0.6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFF97316), width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.redAccent)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSearch<T>({
    required String label,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) itemAsString,
    required void Function(T?) onChanged,
    required Color borderColor,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (label.isNotEmpty)
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500)),
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: selectedItem,
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(itemAsString(e),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14))))
              .toList(),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF18181B),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF27272A).withOpacity(0.6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFF97316), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xCC18181B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [
                    Color.fromRGBO(253, 91, 11, 1),
                    Color.fromRGBO(255, 170, 48, 1)
                  ]),
                ),
                child: const Icon(Icons.check, size: 32, color: Colors.white),
              ),
              Text(widget.successTitle,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(
                  widget.successMessage(RegisterCredentials(
                    firstName: _firstNameCtrl.text,
                    lastName: _lastNameCtrl.text,
                    email: _emailCtrl.text,
                    userName: _userNameCtrl.text,
                    password: '',
                    confirmPassword: '',
                    phoneNumber: '',
                    countryId: 0,
                    cityId: 0,
                    address: '',
                    birthdate: '',
                  )),
                  style: const TextStyle(color: Color(0xFFA1A1AA)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text('Volver a iniciar sesión',
                    style: TextStyle(
                        color: Color(0xFFF97316), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
