import 'package:pyrosfitmovil/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/presentation/widgets/coach_dashboard.dart';
import 'package:pyrosfitmovil/features/dashboard/presentation/widgets/student_dashboard.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role;
    logger.i('HomeScreen: Rol del usuario actual: $role');
    final isCoach = role?.name == 'coach';
    logger.i('isCoach: $isCoach');
    final firstName = auth.user?.firstName ?? '';
    final initial =
        firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PYROSFIT',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            letterSpacing: 2,
            color: AppTheme.foreground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<String>(
              color: AppTheme.card,
              icon: UserAvatar(
                size: 34,
                storageKey: auth.user?.profilePictureKey,
                imageUrl: auth.user?.profilePictureUrl,
                initial: firstName,
                showBorder: true,
                borderColor: AppTheme.border,
              ),
              offset: const Offset(0, 48),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.go('/perfil');
                } else if (value == 'logout') {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: AppTheme.primaryGlow),
                      SizedBox(width: 8),
                      Text('Mi Perfil',
                          style: TextStyle(color: AppTheme.foreground)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Cerrar sesión',
                          style: TextStyle(color: AppTheme.foreground)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isCoach ? const CoachDashboard() : const StudentDashboard(),
      ),
    );
  }
}
