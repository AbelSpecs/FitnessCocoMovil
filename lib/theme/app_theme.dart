import 'dart:ui';
import 'package:flutter/material.dart';

/// Clase centralizada que mapea el `style.css` de PyrosFit a objetos Flutter.
class AppTheme {
  // -------------------------------------------------------------------------
  // 1. EQUIVALENCIAS EXACTAS DE COLOR DESDE OKLCH / CSS RADICAL
  // -------------------------------------------------------------------------
  static const Color background = Color(0xFF131314); // oklch(0.12 0.005 60)
  static const Color foreground = Color(0xFFFAFAFA); // oklch(0.98 0.005 80)

  static const Color card = Color(0xFF222224); // oklch(0.17 0.008 60)
  static const Color cardForeground = Color(0xFFFAFAFA);

  static const Color primary =
      Color(0xFFF95A0B); // oklch(0.72 0.19 50) - Naranja Pyros
  static const Color primaryForeground = Color(0xFF1E1C1B);
  static const Color primaryGlow = Color(0xFFFF8243); // oklch(0.82 0.17 65)

  static const Color secondary = Color(0xFF313133); // oklch(0.22 0.01 60)
  static const Color muted = Color(0xFF2D2D2F); // oklch(0.2 0.01 60)
  static const Color mutedForeground = Color(0xFFACACAF); // oklch(0.7 0.02 70)

  static const Color border = Color(0xFF3C3C3E); // oklch(0.26 0.015 60)
  static const Color input = Color(0xFF2D2D2F); // oklch(0.2 0.01 60)

  static const Color destructive = Color(0xFFBA1A1A); // oklch(0.65 0.22 22)
  static const Color success = Color(0xFF34D399); // oklch(0.74 0.17 155)

  // -------------------------------------------------------------------------
  // 2. CONSTRUCCIÓN DEL THEMEDATA (Hoja de Estilos de Componentes)
  // -------------------------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      dividerColor: border,

      // Configuración de las fuentes base (Barlow para todo por defecto)
      fontFamily: 'Barlow',

      // Estilo de Tarjetas (.bg-card / rounded-2xl)
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // 0.875rem = 14px
          side: const BorderSide(color: border),
        ),
      ),

      // Entorno de Formulario Idéntico a Shadcn (bg-input/60)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // --radius-sm
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructive),
        ),
      ),

      // Botón con variante "Hero" por defecto (FilledButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Barlow',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Tipografía estructural (Jerarquía de Títulos h1, h2, h3 con Bebas Neue)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 48,
            letterSpacing: 0.5,
            color: foreground), // h1
        displayMedium: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 36,
            letterSpacing: 0.5,
            color: foreground), // h2
        titleLarge: TextStyle(
            fontFamily: 'Barlow',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: foreground),
        bodyLarge:
            TextStyle(fontFamily: 'Barlow', fontSize: 16, color: foreground),
        bodyMedium:
            TextStyle(fontFamily: 'Barlow', fontSize: 14, color: foreground),
        bodySmall: TextStyle(
            fontFamily: 'Barlow',
            fontSize: 14,
            color: mutedForeground), // text-muted-foreground
      ),

      // Inyección de Utilidades Especiales (Gradientes, Sombras y Mallas)
      extensions: [
        PyrosStylesExtension(
          gradientPrimary: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(253, 91, 11, 1),
              Color.fromRGBO(255, 170, 48, 1)
            ],
          ),
          gradientHero: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF131314), Color(0xFF2E2421), Color(0xFF573221)],
          ),
          gradientCard: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D2D2F), Color(0xFF1A1A1B)],
          ),
          shadowGlow: [
            BoxShadow(
              color: primary.withOpacity(0.55),
              offset: const Offset(0, 10),
              blurRadius: 40,
              spreadRadius: -10,
            )
          ],
          shadowCard: const [
            BoxShadow(
              color: Color(0xB3000000), // oklch(0.02 0 0 / 0.7)
              offset: Offset(0, 4),
              blurRadius: 24,
              spreadRadius: -8,
            )
          ],
          shadowElevated: const [
            BoxShadow(
              color: Color(0xD9000000), // oklch(0.02 0 0 / 0.85)
              offset: Offset(0, 20),
              blurRadius: 60,
              spreadRadius: -20,
            )
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------------
// 3. EXTENSIÓN DE UTILIDAD (Clase contenedora para Gradientes y Sombras)
// -------------------------------------------------------------------------
class PyrosStylesExtension extends ThemeExtension<PyrosStylesExtension> {
  final LinearGradient gradientPrimary;
  final LinearGradient gradientHero;
  final LinearGradient gradientCard;
  final List<BoxShadow> shadowGlow;
  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowElevated;

  PyrosStylesExtension({
    required this.gradientPrimary,
    required this.gradientHero,
    required this.gradientCard,
    required this.shadowGlow,
    required this.shadowCard,
    required this.shadowElevated,
  });

  // El Widget contenedor de la malla animada fija de fondo (--gradient-mesh)
  Widget buildMeshBackground({required Widget child}) {
    return Stack(
      children: [
        Container(color: AppTheme.background),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -0.8), // at 20% 10%
              radius: 1.2,
              colors: [
                AppTheme.primary.withOpacity(0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.6, 0.8), // at 80% 90%
              radius: 1.2,
              colors: [
                AppTheme.primaryGlow.withOpacity(0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  PyrosStylesExtension copyWith({
    LinearGradient? gradientPrimary,
    LinearGradient? gradientHero,
    LinearGradient? gradientCard,
    List<BoxShadow>? shadowGlow,
    List<BoxShadow>? shadowCard,
    List<BoxShadow>? shadowElevated,
  }) {
    return PyrosStylesExtension(
      gradientPrimary: gradientPrimary ?? this.gradientPrimary,
      gradientHero: gradientHero ?? this.gradientHero,
      gradientCard: gradientCard ?? this.gradientCard,
      shadowGlow: shadowGlow ?? this.shadowGlow,
      shadowCard: shadowCard ?? this.shadowCard,
      shadowElevated: shadowElevated ?? this.shadowElevated,
    );
  }

  @override
  PyrosStylesExtension lerp(
      ThemeExtension<PyrosStylesExtension>? other, double t) {
    if (other is! PyrosStylesExtension) return this;
    return PyrosStylesExtension(
      gradientPrimary:
          LinearGradient.lerp(gradientPrimary, other.gradientPrimary, t)!,
      gradientHero: LinearGradient.lerp(gradientHero, other.gradientHero, t)!,
      gradientCard: LinearGradient.lerp(gradientCard, other.gradientCard, t)!,
      shadowGlow: BoxShadow.lerpList(shadowGlow, other.shadowGlow, t)!,
      shadowCard: BoxShadow.lerpList(shadowCard, other.shadowCard, t)!,
      shadowElevated:
          BoxShadow.lerpList(shadowElevated, other.shadowElevated, t)!,
    );
  }
}

// Shortcut global para acceder a las utilidades directamente desde cualquier vista
extension PyrosThemeContext on BuildContext {
  PyrosStylesExtension get pyrosStyles =>
      Theme.of(this).extension<PyrosStylesExtension>()!;
}
