import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Widget centralizado de Pull-to-Refresh para toda la aplicación PyrosFit.
/// Estandariza la animación, colores, respuesta háptica y física de scroll.
class PyrosPullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const PyrosPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  /// Constructor conveniente que envuelve automáticamente un contenido no scrolleable
  /// o estático en un [SingleChildScrollView] con [AlwaysScrollableScrollPhysics]
  /// para garantizar que el gesto de jalar hacia abajo siempre funcione.
  factory PyrosPullToRefresh.scrollable({
    Key? key,
    required Future<void> Function() onRefresh,
    required Widget child,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    Color? color,
    Color? backgroundColor,
    double displacement = 40.0,
    double edgeOffset = 0.0,
  }) {
    return PyrosPullToRefresh(
      key: key,
      onRefresh: onRefresh,
      color: color,
      backgroundColor: backgroundColor,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: SingleChildScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color ?? AppTheme.primary,
      backgroundColor: backgroundColor ?? const Color(0xFF1E1E22),
      strokeWidth: 2.5,
      displacement: displacement,
      edgeOffset: edgeOffset,
      onRefresh: () async {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}
        try {
          await onRefresh();
        } catch (e) {
          debugPrint('Error during PyrosPullToRefresh: ');
        }
      },
      child: child,
    );
  }
}
