import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/core/models/muscle_group_model.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';
import 'package:pyrosfitmovil/features/clients/presentation/providers/routines_provider.dart';

class RoutineFormSheet extends StatefulWidget {
  final DailyStudentExercise? routineToEdit;

  const RoutineFormSheet({super.key, this.routineToEdit});

  @override
  State<RoutineFormSheet> createState() => _RoutineFormSheetState();
}

class _RoutineFormSheetState extends State<RoutineFormSheet> {
  MuscleGroup? _selectedMuscleGroup;
  ExerciseModel? _selectedExercise;

  final TextEditingController _coachNotesController = TextEditingController();

  final List<Map<String, dynamic>> _sets = [];

  @override
  void initState() {
    super.initState();
    if (widget.routineToEdit != null) {
      final r = widget.routineToEdit!;
      _coachNotesController.text = r.coachNotes;

      // Load sets
      for (var s in r.dailyExerciseSets) {
        _sets.add({
          'id': s.id,
          'targetReps': s.targetReps.toString(),
          'targetWeight': s.targetWeight.toString(),
          'restTime': s.restTime,
        });
      }
    } else {
      _addEmptySet();
    }
  }

  void _addEmptySet() {
    setState(() {
      _sets.add({
        'id': 0, // 0 implies new
        'targetReps': '',
        'targetWeight': '',
        'restTime': '',
      });
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RoutinesProvider>();
    final isEditing = widget.routineToEdit != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Actualizar Rutina' : 'Nueva Rutina',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Muscle Group
              Text('GRUPO MUSCULAR', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              DropdownButtonFormField<MuscleGroup>(
                isExpanded: true,
                value: _selectedMuscleGroup,
                items: provider.muscleGroups
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: isEditing
                    ? null
                    : (MuscleGroup? data) {
                        setState(() {
                          _selectedMuscleGroup = data;
                          _selectedExercise = null;
                        });
                        if (data != null) {
                          provider.loadExercisesForMuscleGroup(data.id);
                        }
                      },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                ),
                dropdownColor: theme.colorScheme.surfaceContainerHighest,
              ),

              const SizedBox(height: 16),

              // Exercise
              Text('EJERCICIO', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ExerciseModel>(
                isExpanded: true,
                value: _selectedExercise,
                items: provider.exercises
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: isEditing
                    ? null
                    : (ExerciseModel? data) {
                        setState(() {
                          _selectedExercise = data;
                        });
                      },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                ),
                dropdownColor: theme.colorScheme.surfaceContainerHighest,
              ),

              const SizedBox(height: 16),

              // Notes
              Text('NOTAS DEL ENTRENADOR', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              TextField(
                controller: _coachNotesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Escribe algunas notas...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 24),

              // Sets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SERIES', style: _labelStyle(theme)),
                  TextButton.icon(
                    onPressed: _addEmptySet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sets List
              ..._sets.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> set = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Serie ${idx + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (_sets.length > 1)
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: theme.colorScheme.error, size: 20),
                              onPressed: () => _removeSet(idx),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: set['targetReps'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Reps', isDense: true),
                              onChanged: (v) => set['targetReps'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: set['targetWeight'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Peso (kg)', isDense: true),
                              onChanged: (v) => set['targetWeight'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: set['restTime'],
                              decoration: const InputDecoration(
                                  labelText: 'Descanso', isDense: true),
                              onChanged: (v) => set['restTime'] = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _save(context, provider),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEditing ? 'Guardar Cambios' : 'Crear Rutina'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? _labelStyle(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  Future<void> _save(BuildContext context, RoutinesProvider provider) async {
    final isEditing = widget.routineToEdit != null;

    if (!isEditing &&
        (_selectedMuscleGroup == null || _selectedExercise == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona grupo muscular y ejercicio')));
      return;
    }

    // Validate sets
    for (var s in _sets) {
      if (s['targetReps'].isEmpty ||
          s['targetWeight'].isEmpty ||
          s['restTime'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Completa todos los campos de las series')));
        return;
      }
    }

    if (isEditing) {
      // Update logic
      final dailyExerciseId = widget.routineToEdit!.dailyExerciseId;
      final data = {
        'coachId': widget.routineToEdit!.coachId,
        'studentId': widget.routineToEdit!.studentId,
        'exerciseId': widget.routineToEdit!.exerciseId,
        'scheduledDate': widget.routineToEdit!.scheduledDate,
        'exerciseName': widget.routineToEdit!.exerciseName,
        'muscleGroupName': widget.routineToEdit!.muscleGroupName,
        'coachNotes': _coachNotesController.text,
        'dailyExerciseSets': _sets
            .where((s) => s['id'] != 0)
            .mapIndexed((index, s) => {
                  'id': s['id'],
                  'dailyStudentExerciseId': dailyExerciseId,
                  'setNumber': index + 1,
                  'targetReps': int.tryParse(s['targetReps']) ?? 0,
                  'targetWeight': int.tryParse(s['targetWeight']) ?? 0,
                  'restTime': s['restTime'],
                  'isAchieved': false,
                })
            .toList(),
      };

      final newSets = _sets
          .where((s) => s['id'] == 0)
          .mapIndexed((index, s) => {
                'dailyStudentExerciseId': dailyExerciseId,
                'setNumber': index + 1,
                'targetReps': int.tryParse(s['targetReps']) ?? 0,
                'targetWeight': int.tryParse(s['targetWeight']) ?? 0,
                'restTime': s['restTime'],
                'isAchieved': false,
              })
          .toList();

      logDebug(newSets);

      final success =
          await provider.updateRoutine(dailyExerciseId, data, newSets);
      if (success && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rutina actualizada')));
      }
    } else {
      // Create logic
      final setsData = _sets
          .asMap()
          .entries
          .map((entry) => {
                'id': 0,
                'dailyStudentExerciseId': 0,
                'setNumber': entry.key + 1,
                'targetReps': int.tryParse(entry.value['targetReps']) ?? 0,
                'targetWeight': int.tryParse(entry.value['targetWeight']) ?? 0,
                'restTime': entry.value['restTime'],
                'isAchieved': false,
              })
          .toList();

      final data = {
        'assign': {
          'coachId': provider.authProvider.user?.coachId,
          'studentId': 0, // WILL INJECT BEFORE SENDING IF WE PASS FROM SCREEN
          'exerciseId': _selectedExercise!.id,
          'scheduledDate': provider.selectedDate.toIso8601String(),
          'dailyExerciseSets': setsData,
          'coachNotes': _coachNotesController.text,
        }
      };

      Navigator.pop(context, data); // We will handle studentId in the screen
    }
  }
}

// Extension to map with index
extension IterableExtension<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index, item);
      index++;
    }
  }
}
