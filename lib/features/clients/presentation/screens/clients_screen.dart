import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/providers/clients_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/widgets/client_card.dart';

import 'package:pyrosfitmovil/theme/app_theme.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ClientsProvider(context.read<AuthProvider>()),
      child: const _ClientsScreenContent(),
    );
  }
}

class _ClientsScreenContent extends StatelessWidget {
  const _ClientsScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => context.pyrosStyles.gradientPrimary.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: const Text('Clientes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<ClientsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.clients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Busca un cliente y entra a su rutina para revisarla o ajustarla.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: provider.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre u objetivo...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (provider.filteredClients.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No se encontraron clientes.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final client = provider.filteredClients[index];
                          return ClientCard(
                            client: client,
                            onTap: () {
                              context.push('/clientes/${client.studentId}', extra: client);
                            },
                          );
                        },
                        childCount: provider.filteredClients.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ));
  }
}
