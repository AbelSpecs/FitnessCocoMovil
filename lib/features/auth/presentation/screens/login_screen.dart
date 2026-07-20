import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/core/widgets/spinner.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pyrosfitmovil/features/auth/data/services/auth_service.dart';
import 'package:pyrosfitmovil/core/services/user_service.dart';
import 'package:pyrosfitmovil/core/services/student_service.dart';
import 'package:pyrosfitmovil/core/services/coach_service.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _error = "";

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = "";
      _isLoading = true;
    });

    try {
      final userName = _userNameController.text.trim();
      final password = _passwordController.text;

      // 1. Llamada al servicio auth.service
      final data = await AuthService.login(LoginCredentials(
        userName: userName,
        password: password,
      ));
      logger.i(data);

      final String id = data['id'].toString();
      final String token = data['token'] as String;
      // @abel seguir revisando ma;ana
      // 2. Llamadas concurrentes a servicios de usuario
      final userData = await UserService.getUser(id);
      final studentData = await StudentService.getStudentByUserId(id);
      final coachData = await CoachService.getCoachByUserId(id);

      // 3. Determinar rol y construir el objeto de sesión (UserAuth)
      Role role = studentData?['data'] == null ? Role.coach : Role.student;

      int studentId =
          studentData?['data'] == null ? 0 : studentData?['data']['id'] as int;

      int coachId =
          coachData?['data'] == null ? 0 : coachData?['data']['id'] as int;

      int myCoachId = 0;
      if (studentData?['data'] != null) {
        final details = await UserService.getUserDetails(id);
        if (details['data'] != null && details['data']['coach'] != null) {
          myCoachId = details['data']['coach']['id'] as int;
        }
      }

      UserAuth userAuth = UserAuth(
        id: userData['data']['id'] as int,
        studentId: studentId != 0 ? studentId : null,
        coachId: coachId != 0 ? coachId : null,
        myCoachId: myCoachId != 0 ? myCoachId : null,
        email: userData['data']['email'] as String?,
        firstName: userData['data']['firstName'] as String?,
        role: role,
      );

      // 4. Guardar en tu manejador de estado (Provider)
      if (token.isNotEmpty && mounted) {
        await Provider.of<AuthProvider>(context, listen: false)
            .setAuth(userAuth, token);
      }

      // 5. Notificación de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Logueado con éxito!"),
            backgroundColor: Color.fromRGBO(253, 91, 11, 1),
          ),
        );

        // 6. Navegación al Dashboard (GoRouter)
        context.go('/');
      }
    } catch (err) {
      final errorMessage = err.toString().replaceAll("Exception: ", "");
      setState(() {
        // Adaptación del mapeo de errores de Axios/Fetch
        _error = errorMessage;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      logger.e('Error en login: $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definición de la paleta de colores oscura/moderna de PyrosFit (Estilo Tailwind/Shadcn)
    const backgroundColor =
        Color(0xFF09090B); // Negro zinc-950 puro (bg-background)
    const borderColor = Color(0xFF27272A); // Gris zinc-800 (border-border)
    const textMuted =
        Color(0xFFA1A1AA); // Gris zinc-400 (text-muted-foreground)

    // Naranja Pyros oficial (bg-gradient-primary)
    const primaryGradient = [
      Color.fromRGBO(253, 91, 11, 1),
      Color.fromRGBO(255, 170, 48, 1)
    ];

    // Ajuste de Transparencia Real: bg-card/80 -> Color Zinc-900 con 80% de opacidad (0xCC en Hexadecimal)
    const cardColorTransparent = Color(0xCC18181B); // text-muted-foreground

    return Scaffold(
        backgroundColor: backgroundColor,
        body: context.pyrosStyles.buildMeshBackground(
          child: Stack(
            children: [
              // 1. Fondo con Gradiente Mesh Fijo
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.8, -0.6),
                    radius: 1.2,
                    colors: [
                      Color.fromARGB(255, 86, 50,
                          32), // Brillo sutil grisáceo en la esquina
                      backgroundColor,
                    ],
                  ),
                ),
              ),

              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(1, 1.2),
                    radius: 1.2,
                    colors: [
                      Color.fromARGB(255, 86, 50,
                          32), // Brillo sutil grisáceo en la esquina
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // 2. Contenido Centrado Scrolleable (Evita errores de overflow con el teclado)
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing:
                          32.0, // Layout espaciado uniforme (Equivalente a space-y-8)
                      children: [
                        // --- SECCIÓN LOGO ---
                        Column(
                          spacing: 12.0, // gap-3
                          children: [
                            // Contenedor del Icono con Sombra de Neón (Shadow Glow)
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: context.pyrosStyles.gradientPrimary,
                                boxShadow: context.pyrosStyles.shadowGlow,
                              ),
                              child: const Icon(
                                Icons
                                    .fitness_center, // Equivalente a Dumbbell de lucide-react
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            Text('PyrosFit',
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                          ],
                        ),

                        // --- TARJETA DE LOGIN (CARD) ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 12.0, sigmaY: 12.0), // backdrop-blur-md
                            child: Container(
                              padding: const EdgeInsets.all(32.0), // p-8
                              decoration: BoxDecoration(
                                color: cardColorTransparent, // bg-card/80
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing:
                                      24.0, // space-y-6 del contenedor del card
                                  children: [
                                    // Cabecera del Card
                                    const Column(
                                      spacing: 4.0,
                                      children: [
                                        Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Ingresa tus credenciales para continuar',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Alerta de Error (Si existe)
                                    if (_error.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(
                                              0.1), // bg-destructive/10
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          _error,
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 14),
                                        ),
                                      ),

                                    // Bloque de Inputs
                                    Column(
                                      spacing: 16.0, // space-y-4 del Formulario
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Campo: Usuario
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 8.0,
                                          children: [
                                            const Text('Usuario',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            TextFormField(
                                              controller: _userNameController,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              decoration: _buildInputDecoration(
                                                  'usuario', borderColor),
                                              validator: (value) =>
                                                  value == null || value.isEmpty
                                                      ? 'Campo requerido'
                                                      : null,
                                            ),
                                          ],
                                        ),

                                        // Campo: Contraseña
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 8.0,
                                          children: [
                                            const Text('Contraseña',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            TextFormField(
                                              controller: _passwordController,
                                              obscureText: true,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              decoration: _buildInputDecoration(
                                                  '••••••••', borderColor),
                                              validator: (value) =>
                                                  value == null || value.isEmpty
                                                      ? 'Campo requerido'
                                                      : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Botón Submit (Hero Variant / Gran gradiente)
                                    Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: _isLoading
                                            ? null
                                            : const LinearGradient(
                                                colors: primaryGradient),
                                        color: _isLoading
                                            ? Colors.grey[800]
                                            : null,
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: Spinner(size: 20),
                                              )
                                            : const Text(
                                                'Ingresar',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                      ),
                                    ),

                                    // Link de Registro
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                                '¿No tienes cuenta y eres entrenador? ',
                                                style: TextStyle(
                                                    color: textMuted,
                                                    fontSize: 14)),
                                            GestureDetector(
                                              onTap: () {
                                                // Navegar al registro
                                                context.go('/register');
                                              },
                                              child: const Text(
                                                'Regístrate',
                                                style: TextStyle(
                                                  color: Color(
                                                      0xFFF97316), // text-primary
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                                '¿No tienes cuenta y no quieres entrenador? ',
                                                style: TextStyle(
                                                    color: textMuted,
                                                    fontSize: 14)),
                                            GestureDetector(
                                              onTap: () {
                                                // Navegar al registro sin entrenador
                                                context.go(
                                                    '/register-info?coachId=9');
                                              },
                                              child: const Text(
                                                'Regístrate aqui',
                                                style: TextStyle(
                                                  color: Color(
                                                      0xFFF97316), // text-primary
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // Estilo personalizado para los inputs idénticos a Shadcn/ui (Input bg-input/60)
  InputDecoration _buildInputDecoration(String hint, Color borderCol) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF27272A).withOpacity(0.6), // bg-input/60
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderCol),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
            color: Color(0xFFF97316), width: 1.5), // Foco naranja
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
