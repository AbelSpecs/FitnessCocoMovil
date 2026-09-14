import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/core/utils/time_utils.dart';

/// Widget flotante y arrastrable de cronómetro de descanso para rutinas de entrenamiento.
/// Réplica visual y funcional del componente RestTimer de la versión web de PyrosFit.
class RestTimerWidget extends StatefulWidget {
  final int seconds;
  final String? label;
  final VoidCallback onClose;
  final VoidCallback? onFinished;

  const RestTimerWidget({
    super.key,
    required this.seconds,
    this.label,
    required this.onClose,
    this.onFinished,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late int _initialSeconds;
  bool _isPaused = false;
  Timer? _timer;

  // Posición flotante en pantalla
  Offset? _position;
  bool _isDragging = false;

  // Controlador de pulso para cuando el tiempo finaliza
  late AnimationController _pulseController;
  late Animation<double> _pulseScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initialSeconds = widget.seconds > 0 ? widget.seconds : 60;
    _remaining = _initialSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RestTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds != oldWidget.seconds || widget.label != oldWidget.label) {
      _initialSeconds = widget.seconds > 0 ? widget.seconds : 60;
      _restart();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused) return;

      if (_remaining > 1) {
        setState(() {
          _remaining--;
        });
      } else {
        setState(() {
          _remaining = 0;
        });
        t.cancel();
        _onComplete();
      }
    });
  }

  void _onComplete() {
    _pulseController.repeat(reverse: true);
    // Retroalimentación háptica para alertar al alumno en el gimnasio
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.heavyImpact();
    });
    widget.onFinished?.call();
  }

  void _restart() {
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _remaining = _initialSeconds;
      _isPaused = false;
    });
    _startTimer();
  }

  void _togglePause() {
    if (_remaining == 0) {
      _restart();
      return;
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double widgetSize = 126.0;

    // Posición inicial: abajo a la derecha sobre la barra de navegación
    _position ??= Offset(
      screenSize.width - widgetSize - 16,
      screenSize.height - widgetSize - 120,
    );

    final double progress =
        _initialSeconds > 0 ? (_remaining / _initialSeconds) : 0.0;
    final bool isFinished = _remaining == 0;

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final newX = (_position!.dx + details.delta.dx)
                .clamp(10.0, screenSize.width - widgetSize - 10.0);
            final newY = (_position!.dy + details.delta.dy)
                .clamp(10.0, screenSize.height - widgetSize - 40.0);
            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        child: AnimatedBuilder(
          animation: _pulseScaleAnimation,
          builder: (context, child) {
            final scale = isFinished ? _pulseScaleAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: widgetSize,
            height: widgetSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF161618).withValues(alpha: 0.94),
              border: Border.all(
                color: isFinished
                    ? AppTheme.primary
                    : (_isDragging
                        ? AppTheme.primaryGlow
                        : AppTheme.primary.withValues(alpha: 0.45)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isFinished ? AppTheme.primary : Colors.black)
                      .withValues(alpha: isFinished ? 0.35 : 0.5),
                  blurRadius: isFinished ? 18 : 12,
                  spreadRadius: isFinished ? 3 : 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Anillo de progreso circular
                CustomPaint(
                  size: const Size(widgetSize, widgetSize),
                  painter: _TimerCirclePainter(
                    progress: progress,
                    trackColor: AppTheme.border.withValues(alpha: 0.35),
                    progressColor: isFinished
                        ? AppTheme.primary
                        : (_isPaused ? Colors.amber : AppTheme.primary),
                    strokeWidth: 5.5,
                  ),
                ),

                // 2. Información central
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.label != null && widget.label!.isNotEmpty)
                        Text(
                          widget.label!,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppTheme.primaryGlow.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 1),
                      Text(
                        formatSecondsToMS(_remaining),
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 27,
                          height: 1.0,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFinished
                            ? '¡LISTO!'
                            : (_isPaused ? 'PAUSADO' : 'DESCANSO'),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isFinished
                              ? AppTheme.primary
                              : (_isPaused ? Colors.amber : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Botón de cerrar (X) en la esquina superior derecha
                Positioned(
                  top: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222224),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.border,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),

                // 4. Botón inferior de Acción (Play / Pause / Reset)
                Positioned(
                  bottom: -6,
                  child: GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGlow,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFinished
                            ? Icons.replay
                            : (_isPaused ? Icons.play_arrow : Icons.pause),
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter para dibujar el anillo de progreso circular del cronómetro
class _TimerCirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerCirclePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Fondo del anillo (Track)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progreso
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
