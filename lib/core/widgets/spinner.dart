import 'dart:ui';
import 'package:flutter/material.dart';

class Spinner extends StatefulWidget {
  final double size;
  final String? label;

  const Spinner({
    super.key,
    this.size = 40.0, // md size equivalent
    this.label,
  });

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Outer track
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3C3C3E).withOpacity(0.4), // border-border/40
                    width: widget.size * 0.075,
                  ),
                ),
              ),
              // Spinning arc
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2.0 * 3.141592653589793,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.transparent,
                          width: widget.size * 0.075,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _SpinnerArcPainter(
                          color: const Color(0xFFF95A0B), // primary
                          strokeWidth: widget.size * 0.075,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Glow dot
              Center(
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(253, 91, 11, 1),
                        Color.fromRGBO(255, 170, 48, 1)
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF95A0B).withOpacity(0.55),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!.toUpperCase(),
            style: const TextStyle(
              fontSize: 12, // text-sm
              color: Color(0xFFA1A1AA), // text-muted-foreground
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SpinnerArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _SpinnerArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -3.141592653589793 / 2, 3.141592653589793 / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpinnerOverlay extends StatelessWidget {
  final String? label;

  const SpinnerOverlay({super.key, this.label = "CARGANDO"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: const Color(0xFF131314).withOpacity(0.7), // bg-background/70
              ),
            ),
          ),
          // Content
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withOpacity(0.9), // bg-popover/90
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3C3C3E)), // border-border
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xD9000000),
                    offset: Offset(0, 20),
                    blurRadius: 60,
                    spreadRadius: -20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spinner(size: 64.0), // lg
                  if (label != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      label!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 3.0, // tracking-[0.3em]
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
