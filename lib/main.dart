import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/globals.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/core/router/route_tree.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';

import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es_US', null);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => StudentRoutinesProvider()),
      // Aquí puedes agregar más providers si los necesitas
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        routerConfig: AppRouter.router,
        title: 'PyrosFit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme);
  }
}
