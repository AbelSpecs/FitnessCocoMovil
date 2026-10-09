import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_video_modal.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/core/utils/weight_utils.dart';
import 'package:pyrosfitmovil/core/utils/time_utils.dart';
import 'package:pyrosfitmovil/core/models/daily_exercise_set_model.dart';

class RoutineCard extends StatelessWidget {
  final DailyStudentExercise routine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = routine.isCompleted;
    final completedSets =
        routine.dailyExerciseSets.where((s) => s.isAchieved).length;
    final totalSets = routine.dailyExerciseSets.length;

    return Card(
      elevation: isDone ? 3 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? Colors.green.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono de estado (Check si está completado como en Web)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono de estado: Check verde si está completado, Mancuerna si está pendiente
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.withValues(alpha: 0.15)
                        : AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.5)
                          : AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.fitness_center_rounded,
                    color: isDone ? Colors.green : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              routine.muscleGroupName.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.bold,
                                color: isDone
                                    ? Colors.greenAccent
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (isDone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check,
                                      size: 11, color: Colors.green),
                                  SizedBox(width: 3),
                                  Text(
                                    'COMPLETADO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (routine.hasVideo)
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline, size: 22),
                        onPressed: () {
                          ExerciseVideoModal.show(
                              context, routine.toExerciseModel());
                        },
                        color: AppTheme.primary,
                        tooltip: 'Ver video',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                        color: theme.colorScheme.onSurfaceVariant,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDelete(context),
                        color: theme.colorScheme.error,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                  ],
                ),
              ],
            ),

            // Notas del coach
            if (routine.coachNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        routine.coachNotes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Comentario / notas del alumno (si completó el ejercicio con feedback)
            if (routine.studentNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comentario del cliente:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            routine.studentNotes,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Encabezado de Series con resumen de progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Series ($totalSets)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalSets > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (completedSets == totalSets && totalSets > 0)
                          ? Colors.green.withValues(alpha: 0.15)
                          : (completedSets > 0)
                              ? Colors.amber.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (completedSets == totalSets && totalSets > 0)
                            ? Colors.green.withValues(alpha: 0.4)
                            : (completedSets > 0)
                                ? Colors.amber.withValues(alpha: 0.4)
                                : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (completedSets == totalSets && totalSets > 0)
                              ? Icons.check_circle_rounded
                              : (completedSets > 0)
                                  ? Icons.timelapse_rounded
                                  : Icons.radio_button_unchecked,
                          size: 13,
                          color: (completedSets == totalSets && totalSets > 0)
                              ? Colors.green
                              : (completedSets > 0)
                                  ? Colors.amber
                                  : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedSets de $totalSets completadas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (completedSets == totalSets && totalSets > 0)
                                ? Colors.green
                                : (completedSets > 0)
                                    ? Colors.amber
                                    : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Filas individuales de series con estado y datos reales
            ...routine.dailyExerciseSets
                .map((set) => _buildSetRow(context, set)),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, DailyExerciseSet set) {
    final theme = Theme.of(context);
    final isAchieved = set.isAchieved;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAchieved
            ? Colors.green.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAchieved
              ? Colors.green.withValues(alpha: 0.35)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Número de serie (verde con check si está realizada)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAchieved
                      ? Colors.green.withValues(alpha: 0.25)
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAchieved
                        ? Colors.green.withValues(alpha: 0.6)
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: isAchieved
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.green)
                    : Text(
                        '${set.setNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Estadísticas del objetivo
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(label: 'Objetivo', value: '${set.targetReps} reps'),
                    _Stat(
                        label: 'Peso',
                        value: formatWeightWithEquivalent(set.targetWeight)),
                    _Stat(
                      label: 'Descanso',
                      value: set.restTime.isNotEmpty
                          ? formatRestTimeDisplay(set.restTime)
                          : '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge de Hecha / Pendiente
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isAchieved
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAchieved
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAchieved
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 12,
                      color: isAchieved ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isAchieved ? 'Hecha' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAchieved ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Si el cliente realizó la serie y registró datos reales
          if (isAchieved &&
              (set.actualReps != null || set.actualWeight != null)) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.done_all_rounded,
                      size: 13, color: Colors.green),
                  const SizedBox(width: 5),
                  Text(
                    'Cliente realizó: ${set.actualReps ?? set.targetReps} reps • ${formatWeightWithEquivalent(set.actualWeight ?? set.targetWeight)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: Text('¿Seguro que deseas eliminar "${routine.exerciseName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
