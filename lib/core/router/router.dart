import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Necesario para kDebugMode
import 'package:go_router/go_router.dart';

/// 1. Equivalente a DefaultErrorComponent
class DefaultErrorScreen extends StatelessWidget {
  final Exception? error;
  final VoidCallback? onRetry; // Equivalente a la prop 'reset'

  const DefaultErrorScreen({
    super.key,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos el tema global de la app para imitar las variables de Tailwind (primary, destructive, etc)
    final theme = Theme.of(context);

    // Scaffold es el "body" de una pantalla en Flutter
    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // bg-background
      body: Center(
        // min-h-screen items-center justify-center
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // px-4
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de Error (bg-destructive/10)
                Container(
                  margin: const EdgeInsets.only(bottom: 24), // mb-6
                  height: 64, // h-16
                  width: 64, // w-16
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle, // rounded-full
                  ),
                  child: Icon(
                    // En lugar del SVG largo, usamos un icono nativo de Material
                    Icons.warning_amber_rounded,
                    size: 32, // h-8 w-8
                    color: theme.colorScheme.error, // text-destructive
                  ),
                ),

                // Título
                Text(
                  "Something went wrong",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, // font-bold
                    letterSpacing: -0.5, // tracking-tight
                    color: theme.colorScheme.onSurface, // text-foreground
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8), // mt-2

                // Subtítulo
                Text(
                  "An unexpected error occurred. Please try again.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme
                        .colorScheme.onSurfaceVariant, // text-muted-foreground
                  ),
                  textAlign: TextAlign.center,
                ),

                // Equivalente a: {import.meta.env.DEV && error.message && (...)}
                if (kDebugMode && error != null) ...[
                  const SizedBox(height: 16), // mt-4
                  Container(
                    constraints:
                        const BoxConstraints(maxHeight: 160), // max-h-40
                    width: double.infinity,
                    padding: const EdgeInsets.all(12), // p-3
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.surfaceContainerHighest, // bg-muted
                      borderRadius: BorderRadius.circular(6), // rounded-md
                    ),
                    // SingleChildScrollView hace el equivalente a 'overflow-auto'
                    child: SingleChildScrollView(
                      child: Text(
                        error.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace', // font-mono
                          fontSize: 12, // text-xs
                          color: theme.colorScheme.error, // text-destructive
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24), // mt-6

                // Botones (flex gap-3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón Try Again
                    ElevatedButton(
                      onPressed: () {
                        // Lógica de reseteo (equivalente a router.invalidate() y reset())
                        if (onRetry != null) onRetry!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.primary, // bg-primary
                        foregroundColor: theme
                            .colorScheme.onPrimary, // text-primary-foreground
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6), // rounded-md
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12), // px-4 py-2
                      ),
                      child: const Text("Try again"),
                    ),

                    const SizedBox(width: 12), // gap-3

                    // Botón Go Home
                    OutlinedButton(
                      onPressed: () {
                        // Equivalente a href="/"
                        context.go('/');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme
                                .colorScheme.outline), // border border-input
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text("Go home"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. Equivalente a getRouter()
GoRouter getRouter() {
  return GoRouter(
    initialLocation: '/',
    // Aquí defines tu routeTree
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text("Dashboard - PyrosFit"))),
      ),
      // ... más rutas
    ],
    // Equivalente a defaultErrorComponent
    errorBuilder: (context, state) {
      return DefaultErrorScreen(
        error: state.error,
        onRetry: () {
          // Si necesitas invalidar el router completo en go_router,
          // normalmente haces un pushReplacement o limpias el estado del provider.
        },
      );
    },
  );
}
