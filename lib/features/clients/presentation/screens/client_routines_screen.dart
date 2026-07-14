import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/providers/routines_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/widgets/routine_card.dart';
import 'package:pyrosfitmovil/features/clients/presentation/widgets/routine_form_sheet.dart';
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

class _ClientRoutinesScreenContent extends StatelessWidget {
  final StudentInfo client;

  const _ClientRoutinesScreenContent({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RoutinesProvider>();
    final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';

    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Agenda del Cliente',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tarjeta superior del cliente
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: context.pyrosStyles.gradientPrimary,
                        shape: BoxShape.circle,
                        boxShadow: context.pyrosStyles.shadowGlow,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALUMNO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              // color: theme.colorScheme.primary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => context
                                .pyrosStyles.gradientPrimary
                                .createShader(
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Controles de Fecha y Botón de añadir
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: provider.selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          provider.loadRoutinesForStudent(
                              client.studentId, date);
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        DateFormat('dd MMM yyyy').format(provider.selectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showAddRoutineSheet(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva Rutina',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Lista de rutinas o estados
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.routines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
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
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.routines.length,
                  itemBuilder: (context, index) {
                    final routine = provider.routines[index];
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final selected = DateTime(provider.selectedDate.year,
                        provider.selectedDate.month, provider.selectedDate.day);
                    final isFutureOrToday = !selected.isBefore(today);

                    return RoutineCard(
                      routine: routine,
                      onEdit: isFutureOrToday
                          ? () =>
                              _showEditRoutineSheet(context, provider, routine)
                          : null,
                      onDelete: isFutureOrToday
                          ? () =>
                              provider.deleteRoutine(routine.dailyExerciseId)
                          : null,
                    );
                  },
                ),

              // Espaciado final de seguridad
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ));
  }

  void _showAddRoutineSheet(
      BuildContext context, RoutinesProvider provider) async {
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
      result['assign']['studentId'] = client.studentId;
      final success = await provider.saveNewRoutine(result);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rutina creada exitosamente'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showEditRoutineSheet(BuildContext context, RoutinesProvider provider,
      DailyStudentExercise routine) {
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
