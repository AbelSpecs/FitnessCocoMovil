import 'package:pyrosfitmovil/core/widgets/pyros_pull_to_refresh.dart';
import 'package:pyrosfitmovil/features/clients/presentation/widgets/student_clinical_overview_card.dart';
import 'package:pyrosfitmovil/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pyrosfitmovil/core/services/tutorial_service.dart';
import 'package:pyrosfitmovil/core/widgets/pyros_showcase.dart';
import 'package:pyrosfitmovil/features/release_notes/services/release_notes_service.dart';

import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/providers/routines_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/widgets/routine_card.dart';
import 'package:pyrosfitmovil/features/clients/presentation/widgets/routine_form_sheet.dart';
import 'package:pyrosfitmovil/features/clients/presentation/screens/client_edit_panel_screen.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ClientRoutinesScreen extends StatelessWidget {
  final StudentInfo client;

  const ClientRoutinesScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = RoutinesProvider(context.read<AuthProvider>());
        // Se llama de forma asíncrona segura sin romper el frame actual
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadRoutinesForStudent(client.studentId, DateTime.now());
        });
        return provider;
      },
      child: _ClientRoutinesScreenContent(client: client),
    );
  }
}

class _ClientRoutinesScreenContent extends StatefulWidget {
  final StudentInfo client;

  const _ClientRoutinesScreenContent({required this.client});

  @override
  State<_ClientRoutinesScreenContent> createState() => _ClientRoutinesScreenContentState();
}

class _ClientRoutinesScreenContentState extends State<_ClientRoutinesScreenContent> {
  final GlobalKey _studentHeaderTourKey = GlobalKey();
  final GlobalKey _clinicalCardTourKey = GlobalKey();
  final GlobalKey _routineControlsTourKey = GlobalKey();
  final GlobalKey _routinesListTourKey = GlobalKey();

  late final ShowcaseView _showcaseView;
  bool _tourChecked = false;
  VoidCallback? _whatsNewListener;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      scope: 'client_routines_tour',
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      blurValue: 1.5,
      onFinish: () {
        TutorialService.instance.markTutorialCompleted(TutorialService.coachClientRoutinesTour);
      },
      onDismiss: (_) {
        TutorialService.instance.markTutorialCompleted(TutorialService.coachClientRoutinesTour);
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

  void _startRoutinesTour() {
    if (!mounted || ReleaseNotesService.instance.isWhatsNewShowing) return;
    _showcaseView.startShowCase([
      _studentHeaderTourKey,
      _clinicalCardTourKey,
      _routineControlsTourKey,
      _routinesListTourKey,
    ]);
  }

  void _checkAndStartTour(RoutinesProvider provider) async {
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

  void _startTourIfEligible(RoutinesProvider provider) async {
    if (_tourChecked || provider.isLoading || ReleaseNotesService.instance.isWhatsNewShowing) return;
    _tourChecked = true;

    final shouldShow = await TutorialService.instance.shouldShowTutorial(TutorialService.coachClientRoutinesTour);
    if (shouldShow && mounted && !provider.isLoading) {
      TutorialService.instance.markTutorialStarted(TutorialService.coachClientRoutinesTour);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !provider.isLoading) {
          _startRoutinesTour();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RoutinesProvider>();
    final client = widget.client;
    final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';

    // Evaluar inicio del tour tras cargar datos
    if (!provider.isLoading) {
      _checkAndStartTour(provider);
    }

    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Agenda del Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppTheme.primaryGlow, size: 22),
              tooltip: 'Ver tour interactivo',
              onPressed: () {
                if (!ReleaseNotesService.instance.isWhatsNewShowing) {
                  _startRoutinesTour();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: PyrosPullToRefresh(
            onRefresh: () async {
              await provider.loadRoutinesForStudent(client.studentId, provider.selectedDate);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Tarjeta superior del cliente con acento naranja PyrosFit
                  PyrosShowcase(
                    showcaseKey: _studentHeaderTourKey,
                    scope: 'client_routines_tour',
                    title: 'Ficha del Alumno',
                    description: 'Consulta los datos del alumno y accede a sus ajustes de métricas corporales y objetivos.',
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1A17),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            size: 64,
                            userId: client.userId,
                            storageKey: client.profilePictureKey,
                            imageUrl: client.profilePictureUrl,
                            initial: initial,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALUMNO',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => context.pyrosStyles.gradientPrimary.createShader(
                                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                  ),
                                  child: Text(
                                    client.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ClientEditPanelScreen(client: client),
                                ),
                              );
                            },
                            icon: const Icon(Icons.manage_accounts_rounded, size: 22),
                            tooltip: 'Ajustar cliente y métricas del alumno',
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.primaryGlow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ficha Clínica y Antropométrica del Alumno (Actividad T-19)
                  PyrosShowcase(
                    showcaseKey: _clinicalCardTourKey,
                    scope: 'client_routines_tour',
                    title: 'Historial Clínico',
                    description: 'Revisa patologías, lesiones y alertas de salud antes de prescribir cargas de trabajo.',
                    child: StudentClinicalOverviewCard(
                      studentId: client.studentId,
                      initiallyExpanded: false,
                    ),
                  ),

                  // 2. Controles de Fecha y Botón de añadir
                  PyrosShowcase(
                    showcaseKey: _routineControlsTourKey,
                    scope: 'client_routines_tour',
                    title: 'Planificación y Calendario',
                    description: 'Selecciona la fecha en el calendario y crea nuevas rutinas personalizadas para este alumno.',
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: provider.selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                provider.loadRoutinesForStudent(client.studentId, date);
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(provider.selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _showAddRoutineSheet(context, provider),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nueva Rutina', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Lista de rutinas o estados
                  PyrosShowcase(
                    showcaseKey: _routinesListTourKey,
                    scope: 'client_routines_tour',
                    title: 'Ejercicios Programados',
                    description: 'Visualiza la lista de ejercicios asignados para el día. Podrás editar repeticiones, series o eliminarlos si cambias el plan.',
                    child: provider.isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : provider.routines.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sin rutinas programadas',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No hay ejercicios para el día seleccionado.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.routines.length,
                                itemBuilder: (context, index) {
                                  final routine = provider.routines[index];
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final selected = DateTime(provider.selectedDate.year, provider.selectedDate.month, provider.selectedDate.day);
                                  final isFutureOrToday = !selected.isBefore(today);

                                  return RoutineCard(
                                    routine: routine,
                                    allRoutines: provider.routines,
                                    onEdit: isFutureOrToday ? () => _showEditRoutineSheet(context, provider, routine) : null,
                                    onDelete: isFutureOrToday ? () => provider.deleteRoutine(routine.dailyExerciseId) : null,
                                  );
                                },
                              ),
                  ),

                  // Espaciado final de seguridad
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddRoutineSheet(BuildContext context, RoutinesProvider provider) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const RoutineFormSheet(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      result['assign']['studentId'] = widget.client.studentId;
      final success = await provider.saveNewRoutine(result);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showEditRoutineSheet(BuildContext context, RoutinesProvider provider, DailyStudentExercise routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: RoutineFormSheet(routineToEdit: routine),
      ),
    );
  }
}
