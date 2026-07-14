import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pyrosfitmovil/core/router/router.dart';
import 'package:pyrosfitmovil/features/auth/presentation/screens/login_screen.dart';
import 'package:pyrosfitmovil/features/auth/presentation/screens/register_screen.dart';
import 'package:pyrosfitmovil/features/auth/presentation/screens/register_info_screen.dart';

import 'package:pyrosfitmovil/features/clients/presentation/screens/clients_screen.dart';
import 'package:pyrosfitmovil/features/clients/presentation/screens/client_routines_screen.dart';
import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/core/widgets/main_scaffold.dart';
import 'package:pyrosfitmovil/features/dashboard/presentation/screens/home_screen.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/screens/student_weekly_routine_screen.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/screens/student_daily_routine_screen.dart';

import 'package:pyrosfitmovil/features/profile/presentation/screens/profile_screen.dart';

// 1. Definimos las rutas de manera organizada
class AppRouter {
  // Privado para que no se instancie la clase accidentalmente
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/login',
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainScaffold(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/rutina/:studentId',
              builder: (context, state) {
                final studentId = int.tryParse(state.pathParameters['studentId'] ?? '');
                if (studentId == null) return const Scaffold(body: Center(child: Text('ID Invalido')));
                return StudentWeeklyRoutineScreen(studentId: studentId);
              },
              routes: [
                GoRoute(
                  path: ':dayId',
                  builder: (context, state) {
                    final studentId = int.tryParse(state.pathParameters['studentId'] ?? '');
                    final dayId = state.pathParameters['dayId'] ?? '';
                    if (studentId == null) return const Scaffold(body: Center(child: Text('ID Invalido')));
                    return StudentDailyRoutineScreen(studentId: studentId, dayId: dayId);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/clientes',
              builder: (context, state) => const ClientsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final client = state.extra as StudentInfo?;
                    if (client == null) {
                      return const Scaffold(body: Center(child: Text('Cliente no encontrado')));
                    }
                    return ClientRoutinesScreen(client: client);
                  },
                ),
              ],
            ),
            // GoRoute(
            //   path: '/progreso',
            //   builder: (context, state) => const Scaffold(body: Center(child: Text('Progreso'))),
            // ),
            GoRoute(
              path: '/perfil',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: LoginPage(),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/register-info',
          builder: (context, state) => const RegisterInfoScreen(),
        )
      ],
      errorBuilder: (context, state) {
        return DefaultErrorScreen(
          error: state.error,
          onRetry: () {
            // Si necesitas invalidar el router completo en go_router,
            // normalmente haces un pushReplacement o limpias el estado del provider.
          },
        );
      }
      // const Scaffold(
      // body: Center(child: Text('404 - Not Found')),
      );
}
