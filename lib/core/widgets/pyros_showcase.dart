import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Componente visual reutilizable para los pasos de tutoriales interactivos en PyrosFit.
/// Aplica la paleta oscura, bordes redondeados y tipografía oficial de la app.
///
/// Si [hasNext] es true, muestra fuera del diálogo un botón "Siguiente" con flecha.
/// Si [hasNext] es false (último paso), muestra un botón "Entendido" con check para finalizar.
/// Se desactiva [disposeOnTap] para evitar que el usuario cierre el onboarding por accidente
/// al pulsar sobre el diálogo de texto.
class PyrosShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final ShapeBorder? targetShapeBorder;
  final EdgeInsets? targetPadding;
  final VoidCallback? onTargetClick;
  final bool hasNext;
  final String? nextButtonText;
  final String? finishButtonText;
  final VoidCallback? onNext;
  final String? scope;

  const PyrosShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.targetShapeBorder,
    this.targetPadding,
    this.onTargetClick,
    this.hasNext = true,
    this.nextButtonText = 'Siguiente',
    this.finishButtonText = 'Entendido',
    this.onNext,
    this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final actionButton = hasNext
        ? TooltipActionButton(
            type: TooltipDefaultActionType.next,
            name: nextButtonText ?? 'Siguiente',
            backgroundColor: AppTheme.primary,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            tailIcon: const ActionButtonIcon(
              icon: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
            ),
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            onTap: onNext,
          )
        : TooltipActionButton(
            type: TooltipDefaultActionType.next,
            name: finishButtonText ?? 'Entendido',
            backgroundColor: const Color(0xFF10B981),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            tailIcon: const ActionButtonIcon(
              icon: Icon(Icons.check_rounded, size: 14, color: Colors.white),
            ),
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            onTap: onNext,
          );

    return Showcase(
      key: showcaseKey,
      scope: scope,
      title: title,
      description: description,
      tooltipBackgroundColor: const Color(0xFF18181B),
      textColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 20,
        letterSpacing: 1.2,
        color: AppTheme.primaryGlow,
      ),
      descTextStyle: const TextStyle(
        fontSize: 13,
        height: 1.4,
        color: Color(0xFFE4E4E7),
        fontWeight: FontWeight.normal,
      ),
      tooltipBorderRadius: BorderRadius.circular(16),
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      targetPadding: targetPadding ?? const EdgeInsets.all(6),
      targetShapeBorder: targetShapeBorder ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
      targetBorderRadius: BorderRadius.circular(16),
      blurValue: 1.5,
      // No pasamos disposeOnTap para evitar el assertion error (`disposeOnTap == null || onTargetClick != null`)
      // que causaba la pantalla blanca. Al ser null, tocar el tooltip no cierra el tutorial.
      tooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.outside,
        alignment: MainAxisAlignment.end,
        gapBetweenContentAndAction: 10,
      ),
      tooltipActions: [actionButton],
      onTargetClick: onTargetClick,
      child: child,
    );
  }
}
