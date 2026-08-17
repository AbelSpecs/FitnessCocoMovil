import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/core/utils/streak_helpers.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Painter para dibujar ondas de radar concéntricas que se expanden y desvanecen hacia afuera
class _RadarWavePainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final Color waveColor;
  final double baseRadius;
  final double maxExpansion;

  _RadarWavePainter({
    required this.progress1,
    required this.progress2,
    required this.waveColor,
    required this.baseRadius,
    required this.maxExpansion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    void drawWave(double p) {
      if (p <= 0.0 || p >= 1.0) return;
      final currentRadius = baseRadius + (p * maxExpansion);
      final opacity = ((1.0 - p) * 0.7).clamp(0.0, 1.0);
      final strokeWidth = (2.5 * (1.0 - (p * 0.4))).clamp(1.0, 3.0);

      // Glow suave de la onda
      final glowPaint = Paint()
        ..color = waveColor.withValues(alpha: (opacity * 0.5).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(center, currentRadius, glowPaint);

      // Línea nítida de la onda
      final strokePaint = Paint()
        ..color = waveColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, currentRadius, strokePaint);
    }

    drawWave(progress1);
    drawWave(progress2);
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) =>
      oldDelegate.progress1 != progress1 ||
      oldDelegate.progress2 != progress2 ||
      oldDelegate.waveColor != waveColor;
}

/// Widget del Orbe de Fuego con animación de ondas de radar saliendo del borde exterior
class PyrosFireOrb extends StatefulWidget {
  final StreakTier tier;
  final double size;

  const PyrosFireOrb({
    super.key,
    required this.tier,
    this.size = 72,
  });

  @override
  State<PyrosFireOrb> createState() => _PyrosFireOrbState();
}

class _PyrosFireOrbState extends State<PyrosFireOrb>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Controlador de la onda tipo radar que se expande hacia afuera
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Controlador del pulso sutil de la llama
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double maxExpansion = 24.0;
    final double totalBoxSize = widget.size + (maxExpansion * 2);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ondas de radar expansivas (solo la onda se expande hacia afuera)
          Positioned(
            left: -maxExpansion,
            top: -maxExpansion,
            child: SizedBox(
              width: totalBoxSize,
              height: totalBoxSize,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  final p1 = _waveController.value;
                  final p2 = (_waveController.value + 0.5) % 1.0;

                  return CustomPaint(
                    painter: _RadarWavePainter(
                      progress1: p1,
                      progress2: p2,
                      waveColor: widget.tier.textColor,
                      baseRadius: (widget.size / 2) + 1.0,
                      maxExpansion: maxExpansion,
                    ),
                  );
                },
              ),
            ),
          ),

          // Orbe central principal fijo con gradiente y resplandor
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.tier.orbGradient,
              boxShadow: widget.tier.glow,
            ),
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Icon(
                Icons.local_fire_department,
                size: widget.size * 0.55,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de la Medalla de Peso Máximo (PR Medal) con animación de toque y tooltip flotante
class PrMedal extends StatefulWidget {
  final int record;
  final StreakTier tier;

  const PrMedal({
    super.key,
    required this.record,
    required this.tier,
  });

  @override
  State<PrMedal> createState() => _PrMedalState();
}

class _PrMedalState extends State<PrMedal> with TickerProviderStateMixin {
  bool _showTooltip = false;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  late AnimationController _tooltipController;
  late Animation<double> _tooltipFadeAnimation;
  late Animation<Offset> _tooltipSlideAnimation;

  @override
  void initState() {
    super.initState();
    // Animación de rebote al cliquear la medalla
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );

    // Animación de float-up y fade para el tooltip "Peso Máx"
    _tooltipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _tooltipFadeAnimation = CurvedAnimation(
      parent: _tooltipController,
      curve: Curves.easeOut,
    );

    _tooltipSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tooltipController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _tapController.dispose();
    _tooltipController.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (!_tapController.isAnimating) {
      _tapController.forward().then((_) {
        if (mounted) _tapController.reverse();
      });
    }

    setState(() {
      _showTooltip = !_showTooltip;
    });

    if (_showTooltip) {
      _tooltipController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Tooltip animado "Peso Máx" flotante
            if (_showTooltip)
              Positioned(
                top: -26,
                child: FadeTransition(
                  opacity: _tooltipFadeAnimation,
                  child: SlideTransition(
                    position: _tooltipSlideAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1C1B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.tier.textColor.withValues(alpha: 0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.tier.textColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        'Peso Máx',
                        style: TextStyle(
                          color: widget.tier.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Circular Progress Ring
            SizedBox(
              width: 76,
              height: 76,
              child: CustomPaint(
                painter: _PrMedalRingPainter(
                  ringColor: widget.tier.textColor,
                  glowColor: widget.tier.textColor.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Center Icon & Info
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF18181B).withValues(alpha: 0.85),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                boxShadow: widget.tier.glow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: widget.tier.textColor,
                  ),
                  Text(
                    '${widget.record}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'KG',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrMedalRingPainter extends CustomPainter {
  final Color ringColor;
  final Color glowColor;

  _PrMedalRingPainter({required this.ringColor, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, basePaint);

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final activePaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    // Draw full circumference with glow
    const sweepAngle = math.pi * 2;
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PrMedalRingPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor || oldDelegate.glowColor != glowColor;
}

/// Botón interactivo de Escudos de Hielo
class IceShieldsButton extends StatelessWidget {
  final int shields;
  final VoidCallback? onTap;

  const IceShieldsButton({
    super.key,
    required this.shields,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escudos de Hielo 🛡️',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Protegen tu racha un día',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Text(
                '$shields/2',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de experiencia con hitos de fuego (Milestones)
class ExperienceMilestoneBar extends StatelessWidget {
  final int streak;
  final StreakTier currentTier;

  const ExperienceMilestoneBar({
    super.key,
    required this.streak,
    required this.currentTier,
  });

  @override
  Widget build(BuildContext context) {
    final next = nextTierFor(streak);
    final progress = next != null
        ? ((streak - currentTier.min) / (next.min - currentTier.min)) * 100
        : 100.0;
    final expPercent = calculateStreakExperience(streak, streakTiers);

    return Column(
      children: [
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final fillWidth = barWidth * (expPercent / 100.0).clamp(0.0, 1.0);

            return SizedBox(
              width: barWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Background track
                  Container(
                    height: 4,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
                    ),
                  ),
                  // Filled progress track
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: fillWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: currentTier.orbGradient,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: currentTier.glow,
                      ),
                    ),
                  ),
                  // Milestone Nodes
                  SizedBox(
                    width: barWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: streakTiers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final t = entry.value;
                        final isReached = streak >= t.min;
                        final double nodeSize = 30.0 + (i * 4.0);
                        final double flameSize = 16.0 + (i * 2.0);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: nodeSize,
                              height: nodeSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isReached
                                    ? t.orbGradient
                                    : const LinearGradient(
                                        colors: [Color(0xFF27272A), Color(0xFF1E1E20)],
                                      ),
                                border: Border.all(
                                  color: isReached ? t.ringColor : AppTheme.border,
                                  width: 1.5,
                                ),
                                boxShadow: isReached ? t.glow : [],
                              ),
                              child: Icon(
                                Icons.local_fire_department,
                                size: flameSize,
                                color: isReached ? Colors.white : Colors.grey.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.min == 0 ? '1d' : '${t.min}d',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isReached ? t.textColor : Colors.grey.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          next != null
              ? '${next.min - streak} días para ${next.label} · ${progress.toInt()}%'
              : 'Nivel máximo: ${streakTiers.last.label} 🔥',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Tarjeta Principal de Racha (Pyros Streak Card)
class PyrosStreakCard extends StatelessWidget {
  final int streak;
  final int shields;
  final String dailyFocus;
  final int dailyExercisesNum;
  final int prRecord;
  final VoidCallback? onUseShield;

  const PyrosStreakCard({
    super.key,
    required this.streak,
    required this.shields,
    required this.dailyFocus,
    required this.dailyExercisesNum,
    this.prRecord = 100,
    this.onUseShield,
  });

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(streak);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: tier.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tier.ringColor.withValues(alpha: 0.35)),
        boxShadow: tier.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label & Tier Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PYROS STREAK',
                style: TextStyle(
                  color: tier.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tier.ringColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tier.ringColor),
                ),
                child: Text(
                  tier.label.toUpperCase(),
                  style: TextStyle(
                    color: tier.textColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Focus text
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Barlow'),
              children: [
                const TextSpan(text: 'Hoy te toca '),
                TextSpan(
                  text: dailyFocus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' · $dailyExercisesNum ejercicios.'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Flame Orb & Streak counter + PR Medal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  PyrosFireOrb(
                    tier: tier,
                    size: 72,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Días Seguidos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PrMedal(
                record: prRecord,
                tier: tier,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ice Shields button
          IceShieldsButton(
            shields: shields,
            onTap: onUseShield,
          ),

          // Milestone Experience Bar
          ExperienceMilestoneBar(
            streak: streak,
            currentTier: tier,
          ),
        ],
      ),
    );
  }
}

/// Diálogo de Celebración al Incrementar la Racha
class StreakCelebrationDialog extends StatelessWidget {
  final int streak;
  final String studentName;
  final VoidCallback onDismiss;

  const StreakCelebrationDialog({
    super.key,
    required this.streak,
    required this.studentName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221F1B), Color(0xFF171719)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFFF9500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Racha Incrementada a $streak días! 🔥',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seguís encendido, $studentName. Mantén el fuego mañana también.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.celebration, size: 18),
                label: const Text('¡Vamos!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
