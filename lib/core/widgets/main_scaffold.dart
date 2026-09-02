import 'package:pyrosfitmovil/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/rutina') || location.startsWith('/clientes')) {
      return 1;
    }
    if (location.startsWith('/ranking')) return 2;
    if (location.startsWith('/perfil')) return 3;
    return 0; // Default a Inicio (/)
  }

  void _onItemTapped(int index, BuildContext context, String role, int studentId) {
    if (role == 'coach') {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/clientes');
          break;
        case 2:
          context.go('/ranking');
          break;
        case 3:
          context.go('/perfil');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/rutina/$studentId');
          break;
        case 2:
          context.go('/ranking');
          break;
        case 3:
          context.go('/perfil');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.select((AuthProvider p) => p.user);
    final role = authUser?.role;
    final isCoach = role?.name == 'coach';

    final selectedIndex = _calculateSelectedIndex(context);
    final validIndex = selectedIndex > 3 ? 0 : selectedIndex;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: validIndex,
        onDestinationSelected: (index) =>
            _onItemTapped(index, context, role?.name ?? 'student', authUser?.studentId ?? 0),
        backgroundColor: const Color(0xFF09090B),
        indicatorColor: const Color(0xFFF97316).withValues(alpha: 0.2),
        destinations: isCoach
            ? [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Color(0xFFF97316)),
                  label: 'Inicio',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group, color: Color(0xFFF97316)),
                  label: 'Clientes',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events, color: Color(0xFFF97316)),
                  label: 'Podio',
                ),
                NavigationDestination(
                  icon: UserAvatar(
                    size: 24,
                    storageKey: authUser?.profilePictureKey,
                    imageUrl: authUser?.profilePictureUrl,
                    initial: authUser?.firstName,
                    showBorder: false,
                  ),
                  selectedIcon: UserAvatar(
                    size: 26,
                    storageKey: authUser?.profilePictureKey,
                    imageUrl: authUser?.profilePictureUrl,
                    initial: authUser?.firstName,
                    showBorder: true,
                    borderColor: const Color(0xFFF97316),
                  ),
                  label: 'Perfil',
                ),
              ]
            : [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Color(0xFFF97316)),
                  label: 'Inicio',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon:
                      Icon(Icons.fitness_center, color: Color(0xFFF97316)),
                  label: 'Rutina',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events, color: Color(0xFFF97316)),
                  label: 'Podio',
                ),
                NavigationDestination(
                  icon: UserAvatar(
                    size: 24,
                    storageKey: authUser?.profilePictureKey,
                    imageUrl: authUser?.profilePictureUrl,
                    initial: authUser?.firstName,
                    showBorder: false,
                  ),
                  selectedIcon: UserAvatar(
                    size: 26,
                    storageKey: authUser?.profilePictureKey,
                    imageUrl: authUser?.profilePictureUrl,
                    initial: authUser?.firstName,
                    showBorder: true,
                    borderColor: const Color(0xFFF97316),
                  ),
                  label: 'Perfil',
                ),
              ],
      ),
    );
  }
}
