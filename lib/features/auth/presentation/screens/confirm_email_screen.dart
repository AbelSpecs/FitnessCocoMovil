import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pyrosfitmovil/features/auth/data/services/auth_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

enum ConfirmEmailStatus { validating, success, error }

class ConfirmEmailScreen extends StatefulWidget {
  final String? userId;
  final String? token;
  final String? code;

  const ConfirmEmailScreen({
    super.key,
    this.userId,
    this.token,
    this.code,
  });

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen>
    with SingleTickerProviderStateMixin {
  ConfirmEmailStatus _status = ConfirmEmailStatus.validating;
  String _errorMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _executeConfirmation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _executeConfirmation() async {
    final activeToken = widget.token?.isNotEmpty == true
        ? widget.token!
        : (widget.code?.isNotEmpty == true ? widget.code! : '');

    if (activeToken.isEmpty) {
      if (mounted) {
        setState(() {
          _status = ConfirmEmailStatus.error;
          _errorMessage =
              'El enlace no contiene el token o código de activación requerido.';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _status = ConfirmEmailStatus.validating);
      }

      final parsedUserId = widget.userId != null ? int.tryParse(widget.userId!) : null;

      await AuthService.confirmEmail(
        userId: parsedUserId,
        code: activeToken,
      );

      if (mounted) {
        setState(() {
          _status = ConfirmEmailStatus.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = ConfirmEmailStatus.error;
          final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
          _errorMessage = rawMsg.isNotEmpty
              ? rawMsg
              : 'El enlace de activación ha expirado o ya ha sido utilizado.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Header
                    _buildBrandHeader(),
                    const SizedBox(height: 24),

                    // Dynamic State Card
                    _buildStateCard(),
                    const SizedBox(height: 24),

                    // Footer Info
                    Text(
                      '© ${DateTime.now().year} PyrosFit. Todos los derechos reservados.',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.fireGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PYROSFIT',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'ACTIVACIÓN DE CUENTA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
            color: AppTheme.primaryGlow,
          ),
        ),
      ],
    );
  }

  Widget _buildStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildCurrentStateContent(),
      ),
    );
  }

  Widget _buildCurrentStateContent() {
    switch (_status) {
      case ConfirmEmailStatus.validating:
        return _buildValidatingState();
      case ConfirmEmailStatus.success:
        return _buildSuccessState();
      case ConfirmEmailStatus.error:
        return _buildErrorState();
    }
  }

  // 1. ESTADO: VALIDANDO (CARGA)
  Widget _buildValidatingState() {
    return Column(
      key: const ValueKey('validating'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppTheme.primaryGlow,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Validando tu cuenta...',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Barlow',
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Estamos verificando tu enlace de activación en nuestros servidores. Solo tomará unos segundos.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: AppTheme.primaryGlow,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Procesando confirmación segura',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. ESTADO: ÉXITO (VALIDADA)
  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4010B981),
                blurRadius: 25,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF34D399),
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Cuenta Verificada',
            style: TextStyle(
              color: Color(0xFF34D399),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '¡Tu cuenta ha sido validada!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Barlow',
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Tu dirección de correo ha sido confirmada con éxito. Ya puedes iniciar sesión con tus credenciales y acceder a tus entrenamientos.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppTheme.primary.withValues(alpha: 0.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. ESTADO: ERROR (EXPIRADO / INVÁLIDO)
  Widget _buildErrorState() {
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40EF4444),
                blurRadius: 25,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF87171),
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Enlace No Válido',
            style: TextStyle(
              color: Color(0xFFF87171),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Enlace no válido o expirado',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Barlow',
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage.isNotEmpty
              ? _errorMessage
              : 'El enlace de activación ha caducado (límite de 24 horas) o ya ha sido utilizado para validar tu cuenta.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppTheme.primary.withValues(alpha: 0.4),
            ),
            child: const Text(
              'Ir al Inicio de Sesión',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => context.go('/register'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Crear una nueva cuenta',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
