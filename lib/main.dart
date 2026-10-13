import 'package:pyrosfitmovil/features/exercises/presentation/controllers/exercises_provider.dart';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/globals.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/core/router/route_tree.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envFile = kReleaseMode ? '.env.production' : '.env.development';
  await dotenv.load(fileName: envFile);
  await initializeDateFormatting('es_US', null);

  // Inicializar y esperar la sesión guardada ANTES de inicializar el router y los widgets
  final authProvider = AuthProvider();
  await authProvider.initAuth();

  final router = AppRouter.createRouter(authProvider);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => StudentRoutinesProvider()),
      ChangeNotifierProvider(create: (_) => ExercisesProvider()),
    ],
    child: MyApp(router: router),
  ));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      title: 'PyrosFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
    );
  }
}
