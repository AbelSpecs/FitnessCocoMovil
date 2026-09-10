import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

enum PyrosLogoVariant {
  icon,
  square,
  circle,
  full,
}

class PyrosFlameLogo extends StatelessWidget {
  final double size;
  final PyrosLogoVariant variant;
  final bool showGlow;
  final double borderRadius;
  final VoidCallback? onTap;

  const PyrosFlameLogo({
    super.key,
    this.size = 64,
    this.variant = PyrosLogoVariant.icon,
    this.showGlow = true,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (variant) {
      case PyrosLogoVariant.circle:
        assetPath = 'assets/brand/pyros_circle.png';
        break;
      case PyrosLogoVariant.square:
        assetPath = 'assets/brand/pyros_square.png';
        break;
      case PyrosLogoVariant.icon:
      case PyrosLogoVariant.full:
      default:
        assetPath = 'assets/brand/pyros_flame_centered.png';
        break;
    }

    final glowDecoration = showGlow
        ? [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ]
        : null;

    final logoIcon = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: glowDecoration,
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          width: size * 0.76,
          height: size * 0.76,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.local_fire_department_rounded,
            color: AppTheme.primary,
            size: 32,
          ),
        ),
      ),
    );

    if (variant == PyrosLogoVariant.full) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logoIcon,
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PYROSFIT',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: size * 0.55,
                  letterSpacing: 2.0,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Text(
                'BY GEEKSOLUTIONS',
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: AppTheme.primaryGlow,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: logoIcon);
    }

    return logoIcon;
  }
}
