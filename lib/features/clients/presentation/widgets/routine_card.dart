import 'package:pyrosfitmovil/core/widgets/expandable_text.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_video_modal.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/core/utils/weight_utils.dart';
import 'package:pyrosfitmovil/core/utils/time_utils.dart';
import 'package:pyrosfitmovil/core/models/daily_exercise_set_model.dart';

class RoutineCard extends StatelessWidget {
  final DailyStudentExercise routine;
  final List<DailyStudentExercise>? allRoutines;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    this.allRoutines,
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

    final superSetTag = (routine.superSetTag ?? '').trim().toUpperCase();
    final isSuperSet = superSetTag.isNotEmpty;

    final superSetGroup = isSuperSet && allRoutines != null
        ? (allRoutines!
            .where((r) =>
                (r.superSetTag ?? '').trim().toUpperCase() == superSetTag)
            .toList()
          ..sort((a, b) => (a.superSetOrder ?? 1).compareTo(b.superSetOrder ?? 1)))
        : <DailyStudentExercise>[];
    final groupPartners = superSetGroup
        .where((r) => r.dailyExerciseId != routine.dailyExerciseId)
        .toList();
    final totalInGroup = superSetGroup.length;

    return Card(
      elevation: isDone ? 3 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone
          ? const Color(0xFF141E16)
          : isSuperSet
              ? const Color(0xFF1E1A14)
              : const Color(0xFF1D1A17), // Fondo cálido con matiz PyrosFit en lugar de gris plano
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? Colors.green.withValues(alpha: 0.5)
              : isSuperSet
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                  : AppTheme.primary.withValues(alpha: 0.38), // Naranja característico PyrosFit
          width: 1.2,
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
                        : isSuperSet
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.55)
                          : isSuperSet
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                              : AppTheme.primary.withValues(alpha: 0.45),
                      width: 1.2,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: isDone
                                    ? Colors.greenAccent
                                    : AppTheme.primary, // Naranja PyrosFit destacado
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
                      if (isSuperSet) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link_rounded,
                                  size: 11, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Serie Combinada #$superSetTag • ${routine.superSetOrder ?? 1} de $totalInGroup',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF59E0B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        routine.exerciseName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        color: Colors.white70,
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

            // Notas del coach (expandible para no desbordar ni tapar elementos)
            if (routine.coachNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ExpandableText(
                        text: routine.coachNotes,
                        maxLines: 2,
                        buttonColor: AppTheme.primary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
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
                          ExpandableText(
                            text: routine.studentNotes,
                            maxLines: 2,
                            buttonColor: Colors.greenAccent,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
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
            Divider(
              color: AppTheme.primary.withValues(alpha: 0.15),
              height: 1,
            ),
            const SizedBox(height: 8),

            // Encabezado de Series con resumen de progreso en acento naranja
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Series ($totalSets)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                              ? AppTheme.primary.withValues(alpha: 0.18)
                              : AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (completedSets == totalSets && totalSets > 0)
                            ? Colors.green.withValues(alpha: 0.45)
                            : (completedSets > 0)
                                ? AppTheme.primary.withValues(alpha: 0.5)
                                : AppTheme.primary.withValues(alpha: 0.2),
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
                                  ? AppTheme.primary
                                  : AppTheme.primary.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedSets de $totalSets completadas',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (completedSets == totalSets && totalSets > 0)
                                ? Colors.green
                                : (completedSets > 0)
                                    ? AppTheme.primary
                                    : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Compañeros de la serie combinada si existen
            if (isSuperSet && groupPartners.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.layers_outlined,
                            size: 13, color: Color(0xFFF59E0B)),
                        SizedBox(width: 5),
                        Text(
                          'Ejercicios en esta combinación:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...groupPartners.map((partner) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Text(
                                '• #${partner.superSetOrder ?? 1}: ',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70),
                              ),
                              Expanded(
                                child: Text(
                                  partner.exerciseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white70),
                                ),
                              ),
                              Text(
                                '${partner.dailyExerciseSets.length} sets',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white54),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            // Lista de series (idéntico a Web: orden del array y displaySetNumber = totalSets - index)
            ...(() {
              final sortedSets = [...routine.dailyExerciseSets]..sort((a, b) {
                final aNum = int.tryParse(a.setNumber.toString()) ?? 0;
                final bNum = int.tryParse(b.setNumber.toString()) ?? 0;
                return aNum.compareTo(bNum);
              });
              return sortedSets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                final displaySetNumber = sortedSets.length - index;
                return _buildSetRow(context, set, displaySetNumber);
              });
            })(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, DailyExerciseSet set, int displaySetNumber) {
    final isAchieved = set.isAchieved;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAchieved
            ? Colors.green.withValues(alpha: 0.08)
            : AppTheme.primary.withValues(alpha: 0.04), // Sutil toque cálido PyrosFit
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAchieved
              ? Colors.green.withValues(alpha: 0.35)
              : AppTheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Número de serie (verde con check si está realizada, naranja si pendiente)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAchieved
                      ? Colors.green.withValues(alpha: 0.25)
                      : AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAchieved
                        ? Colors.green.withValues(alpha: 0.6)
                        : AppTheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: isAchieved
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.green)
                    : Text(
                        '$displaySetNumber',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              // Estadísticas del objetivo con distribución flexible anti-overflow
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Objetivo',
                        value: '${set.targetReps} reps',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _Stat(
                        label: 'Peso',
                        value: formatWeightWithEquivalent(set.targetWeight),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _Stat(
                        label: 'Descanso',
                        value: set.restTime.isNotEmpty
                            ? formatRestTimeDisplay(set.restTime)
                            : '-',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
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
                children: [
                  const Icon(Icons.done_all_rounded,
                      size: 13, color: Colors.green),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Cliente realizó: ${set.actualReps ?? set.targetReps} reps • ${formatWeightWithEquivalent(set.actualWeight ?? set.targetWeight)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: AppTheme.primary.withValues(alpha: 0.9),
            letterSpacing: 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
