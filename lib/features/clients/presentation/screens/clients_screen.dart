import 'package:pyrosfitmovil/core/widgets/pyros_pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pyrosfitmovil/core/services/tutorial_service.dart';
import 'package:pyrosfitmovil/core/widgets/pyros_showcase.dart';
import 'package:pyrosfitmovil/features/release_notes/services/release_notes_service.dart';
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

class _ClientsScreenContent extends StatefulWidget {
  const _ClientsScreenContent();

  @override
  State<_ClientsScreenContent> createState() => _ClientsScreenContentState();
}

class _ClientsScreenContentState extends State<_ClientsScreenContent> {
  final GlobalKey _searchClientsKey = GlobalKey();
  final GlobalKey _clientsListKey = GlobalKey();

  late final ShowcaseView _showcaseView;
  bool _tourChecked = false;
  VoidCallback? _whatsNewListener;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      scope: 'clients_tour',
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      blurValue: 1.5,
      onFinish: () {
        TutorialService.instance.markTutorialCompleted(TutorialService.coachClientsTour);
      },
      onDismiss: (_) {
        TutorialService.instance.markTutorialCompleted(TutorialService.coachClientsTour);
      },
    );
  }

  @override
  void dispose() {
    if (_whatsNewListener != null) {
      ReleaseNotesService.instance.isWhatsNewOpen.removeListener(_whatsNewListener!);
      _whatsNewListener = null;
    }
    _showcaseView.unregister();
    super.dispose();
  }

  void _startClientsTour() {
    if (!mounted || ReleaseNotesService.instance.isWhatsNewShowing) return;
    _showcaseView.startShowCase([
      _searchClientsKey,
      _clientsListKey,
    ]);
  }

  void _checkAndStartTour(ClientsProvider provider) async {
    if (_tourChecked || provider.isLoading) return;

    final releaseNotesService = ReleaseNotesService.instance;
    final hasPendingWhatsNew = await releaseNotesService.shouldShowWhatsNew();

    if (hasPendingWhatsNew || releaseNotesService.isWhatsNewShowing) {
      _whatsNewListener = () {
        if (!releaseNotesService.isWhatsNewShowing) {
          if (_whatsNewListener != null) {
            releaseNotesService.isWhatsNewOpen.removeListener(_whatsNewListener!);
            _whatsNewListener = null;
          }
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted && !provider.isLoading) {
              _startTourIfEligible(provider);
            }
          });
        }
      };
      releaseNotesService.isWhatsNewOpen.addListener(_whatsNewListener!);
      return;
    }

    _startTourIfEligible(provider);
  }

  void _startTourIfEligible(ClientsProvider provider) async {
    if (_tourChecked || provider.isLoading || ReleaseNotesService.instance.isWhatsNewShowing) return;
    _tourChecked = true;

    final shouldShow = await TutorialService.instance.shouldShowTutorial(TutorialService.coachClientsTour);
    if (shouldShow && mounted && !provider.isLoading) {
      TutorialService.instance.markTutorialStarted(TutorialService.coachClientsTour);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !provider.isLoading) {
          _startClientsTour();
        }
      });
    }
  }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primaryGlow, size: 22),
              tooltip: 'Ver tour interactivo',
              onPressed: () {
                if (!ReleaseNotesService.instance.isWhatsNewShowing) {
                  _startClientsTour();
                }
              },
            ),
          ],
        ),
        body: Consumer<ClientsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.clients.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Iniciar verificación del tour cuando la lista esté disponible
            _checkAndStartTour(provider);

            return PyrosPullToRefresh(
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
                          PyrosShowcase(
                            showcaseKey: _searchClientsKey,
                            scope: 'clients_tour',
                            title: 'Buscador de Alumnos',
                            description: 'Filtra rápidamente a tus alumnos por nombre, condición física u objetivo para consultar sus fichas.',
                            child: TextField(
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
                            final card = ClientCard(
                              client: client,
                              onTap: () {
                                context.push('/clientes/${client.studentId}', extra: client);
                              },
                            );
                            if (index == 0) {
                              return PyrosShowcase(
                                showcaseKey: _clientsListKey,
                                scope: 'clients_tour',
                                title: 'Gestión y Agendas',
                                description: 'Selecciona a un alumno para acceder a su agenda diaria de ejercicios, historial clínico y personalización de rutinas.',
                                child: card,
                              );
                            }
                            return card;
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
      ),
    );
  }
}
