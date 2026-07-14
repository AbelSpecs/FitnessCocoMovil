import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart'; // Tu Enum Role

/// Definición de los elementos de navegación (Tu constante const nav)
class NavigationItem {
  final String label;
  final String targetPath;
  final IconData icon;
  final List<Role> roles;

  const NavigationItem({
    required this.label,
    required this.targetPath,
    required this.icon,
    required this.roles,
  });
}

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  /// Lista maestra de navegación basada en tu código de React
  static const List<NavigationItem> _navItems = [
    NavigationItem(
      label: "Dashboard",
      targetPath: "/",
      icon: Icons.dashboard_outlined,
      roles: [Role.coach, Role.student],
    ),
    NavigationItem(
      label: "Rutina",
      targetPath: "/rutina", // GoRouter resolverá el /:studentId internamente
      icon: Icons.calendar_today_outlined,
      roles: [Role.student],
    ),
    NavigationItem(
      label: "Perfil",
      targetPath: "/perfil",
      icon: Icons.person_outline,
      roles: [Role.coach, Role.student],
    ),
    NavigationItem(
      label: "Clientes",
      targetPath: "/clientes",
      icon: Icons.people_outline,
      roles: [Role.coach],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Escuchamos al AuthProvider global para conocer el rol del usuario actual
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userRole = user?.role ?? Role.student;

    // 2. Filtramos los elementos de navegación por rol (Tu visibleItems.map)
    final visibleItems =
        _navItems.where((item) => item.roles.contains(userRole)).toList();

    // 3. Obtenemos el ancho de pantalla para definir si renderizamos Layout Web/Tablet o Móvil
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen =
        screenWidth >= 1024; // Equivalente a lg: de Tailwind

    // Mapeamos el índice activo de GoRouter con los elementos visibles filtrados
    int currentIndex = navigationShell.currentIndex;

    if (isLargeScreen) {
      // --- DISEÑO DESKTOP / TABLET (Sidebar + Body) ---
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: screenWidth >=
                  1200, // Se expande automáticamente si hay espacio (collapsed toggle)
              minWidth: 80,
              minExtendedWidth: 256,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              selectedIndex: currentIndex,
              // Al presionar un elemento cambiamos de pestaña en el shell
              onDestinationSelected: (int index) =>
                  _onTabSelected(context, index, visibleItems),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center,
                        color: Theme.of(context).colorScheme.primary, size: 30),
                    if (screenWidth >= 1200) ...[
                      const SizedBox(width: 8),
                      const Text(
                        "PYROSFIT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2),
                      ),
                    ]
                  ],
                ),
              ),
              destinations: visibleItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                );
              }).toList(),
              // Parte inferior del sidebar: Información de perfil del usuario
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                          user?.firstName?.substring(0, 1).toUpperCase() ??
                              "U"),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // El contenido dinámico que cambia de página (children)
            Expanded(
              child: navigationShell,
            ),
          ],
        ),
      );
    } else {
      // --- DISEÑO MÓVIL (Topbar + Body + Bottom Navigation) ---
      return Scaffold(
        appBar: AppBar(
          title: const Text("PYROSFIT",
              style:
                  TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                // Acción de notificaciones (Tu botón Bell)
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                    user?.firstName?.substring(0, 1).toUpperCase() ?? "U",
                    style: const TextStyle(fontSize: 12)),
              ),
            )
          ],
        ),
        // El cuerpo que despliega la pantalla activa manteniendo su estado vivo
        body: navigationShell,

        // Barra inferior nativa de navegación móvil (Tu Mobile bottom nav)
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) =>
              _onTabSelected(context, index, visibleItems),
          destinations: visibleItems.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      );
    }
  }

  /// Gestiona la redirección inyectando los parámetros en las rutas asumiendo tu esquema
  void _onTabSelected(
      BuildContext context, int index, List<NavigationItem> items) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final targetItem = items[index];

    // Construcción dinámica de la ruta basándonos en tu Record<string, () => Record<string, string>>
    String fullPath = targetItem.targetPath;

    if (targetItem.label == "Rutina") {
      final studentId = user?.studentId ?? 0;
      fullPath = "/rutina/$studentId";
    } else if (targetItem.label == "Perfil") {
      final userId = user?.id ?? 0;
      fullPath = "/perfil/$userId";
    }

    // Usamos el branch de StatefulNavigationShell para cambiar la vista respetando el estado de navegación
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
