import 'package:pyrosfitmovil/core/widgets/rest_time_input_field.dart';
import 'package:pyrosfitmovil/core/utils/weight_utils.dart';
import 'package:pyrosfitmovil/core/widgets/weight_input_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/daily_student_exercise_model.dart';
import 'package:pyrosfitmovil/core/models/muscle_group_model.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/services/routine_service.dart';
import 'package:pyrosfitmovil/core/utils/exercise_filter.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';
import 'package:pyrosfitmovil/features/clients/presentation/providers/routines_provider.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/quick_create_exercise_dialog.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class RoutineFormSheet extends StatefulWidget {
  final DailyStudentExercise? routineToEdit;

  const RoutineFormSheet({super.key, this.routineToEdit});

  @override
  State<RoutineFormSheet> createState() => _RoutineFormSheetState();
}

class _RoutineFormSheetState extends State<RoutineFormSheet> {
  MuscleGroup? _selectedMuscleGroup;
  ExerciseModel? _selectedExercise;
  bool _didInitialSync = false;

  final TextEditingController _coachNotesController = TextEditingController();

  final List<Map<String, dynamic>> _sets = [];
  Map<String, dynamic>? _copiedSet;
  late DateTime _selectedDate;

  // Serie Combinada (Superserie)
  bool _isSuperSet = false;
  String _selectedSuperSetTag = 'A';
  String _combinedRestTime = '90';

  @override
  void initState() {
    super.initState();
    if (widget.routineToEdit != null) {
      final r = widget.routineToEdit!;
      _coachNotesController.text = r.coachNotes;
      _selectedDate = DateTime.tryParse(r.scheduledDate) ?? DateTime.now();

      // Preseleccionar ejercicio inicial desde los datos de la rutina
      _selectedExercise = r.toExerciseModel();

      // Preseleccionar grupo muscular si ya est cargado en el provider
      final provider = context.read<RoutinesProvider>();
      if (provider.muscleGroups.isNotEmpty) {
        _selectedMuscleGroup = provider.muscleGroups.cast<MuscleGroup?>().firstWhere(
          (m) =>
              m != null &&
              ((r.muscleGroupId != null && r.muscleGroupId != 0 && m.id == r.muscleGroupId) ||
               (r.muscleGroupName.isNotEmpty &&
                m.name.trim().toLowerCase() == r.muscleGroupName.trim().toLowerCase())),
          orElse: () => null,
        );
      }

      // Si an no estaba en la lista de grupos, crear instancia temporal para que se muestre en el select
      if (_selectedMuscleGroup == null && (r.muscleGroupId != null || r.muscleGroupName.isNotEmpty)) {
        _selectedMuscleGroup = MuscleGroup(
          id: r.muscleGroupId ?? 0,
          name: r.muscleGroupName.isNotEmpty ? r.muscleGroupName : 'General',
        );
      }

      // Cargar ejercicios de ese grupo muscular
      final targetGroupId = _selectedMuscleGroup?.id ?? r.muscleGroupId ?? 0;
      if (targetGroupId > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadExercisesForMuscleGroup(targetGroupId);
        });
      }

      if (r.superSetTag != null && r.superSetTag!.trim().isNotEmpty) {
        _isSuperSet = true;
        _selectedSuperSetTag = r.superSetTag!.trim().toUpperCase();
        _combinedRestTime = r.dailyExerciseSets.isNotEmpty
            ? r.dailyExerciseSets.first.restTime
            : '90';
      }

      // Load sets
      for (var s in r.dailyExerciseSets) {
        _sets.add({
          'id': s.id,
          'targetReps': s.targetReps.toString(),
          'targetWeight': formatWeightNumber(s.targetWeight),
          'restTime': s.restTime,
          '_key': 'set_${s.id}',
        });
      }
    } else {
      _selectedDate = context.read<RoutinesProvider>().selectedDate;
      _addEmptySet();
    }
  }

  void _addEmptySet() {
    setState(() {
      _sets.insert(0, {
        'id': 0, // 0 implies new
        'targetReps': '',
        'targetWeight': '',
        'restTime': _isSuperSet ? _combinedRestTime : '',
        '_key': 'new_${DateTime.now().microsecondsSinceEpoch}',
      });
    });
  }

  void _copySet(Map<String, dynamic> set) {
    setState(() {
      _copiedSet = {
        'id': 0,
        'targetReps': set['targetReps']?.toString() ?? '',
        'targetWeight': set['targetWeight']?.toString() ?? '',
        'restTime': set['restTime']?.toString() ?? '',
      };
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Serie copiada: ${set['targetReps']?.toString().isNotEmpty == true ? set['targetReps'] : '0'} reps • ${formatWeightWithEquivalent(set['targetWeight'])}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateSet(Map<String, dynamic> set) {
    setState(() {
      _sets.insert(0, {
        'id': 0,
        'targetReps': set['targetReps']?.toString() ?? '',
        'targetWeight': set['targetWeight']?.toString() ?? '',
        'restTime': _isSuperSet ? _combinedRestTime : (set['restTime']?.toString() ?? ''),
        '_key': 'dup_${DateTime.now().microsecondsSinceEpoch}',
      });
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Serie duplicada: Se añadió una copia arriba'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeSet(int idx) {
    setState(() {
      _sets.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RoutinesProvider>();
    final isEditing = widget.routineToEdit != null;

    // Sincronizacin automtica cuando provider.muscleGroups o provider.exercises terminan de cargar
    if (isEditing && !_didInitialSync) {
      final r = widget.routineToEdit!;
      if ((_selectedMuscleGroup == null || _selectedMuscleGroup!.id == 0) &&
          provider.muscleGroups.isNotEmpty) {
        final matchMg = provider.muscleGroups.cast<MuscleGroup?>().firstWhere(
          (m) =>
              m != null &&
              ((r.muscleGroupId != null && r.muscleGroupId != 0 && m.id == r.muscleGroupId) ||
               (r.muscleGroupName.isNotEmpty &&
                m.name.trim().toLowerCase() == r.muscleGroupName.trim().toLowerCase())),
          orElse: () => null,
        );
        if (matchMg != null) {
          _selectedMuscleGroup = matchMg;
          provider.loadExercisesForMuscleGroup(matchMg.id);
        }
      }

      if (provider.exercises.isNotEmpty) {
        final matchEx = provider.exercises.cast<ExerciseModel?>().firstWhere(
          (e) =>
              e != null &&
              (e.id == r.exerciseId ||
               e.name.trim().toLowerCase() == r.exerciseName.trim().toLowerCase()),
          orElse: () => null,
        );
        if (matchEx != null) {
          _selectedExercise = matchEx;
          _didInitialSync = true;
        }
      }
    }

    // Lista de grupos musculares asegurando que el seleccionado est presente para evitar fallos de Flutter Dropdown
    final muscleGroupItems = List<MuscleGroup>.from(provider.muscleGroups);
    if (_selectedMuscleGroup != null &&
        !muscleGroupItems.any((m) => m.id == _selectedMuscleGroup!.id)) {
      muscleGroupItems.insert(0, _selectedMuscleGroup!);
    }

    // Lista de ejercicios asegurando que el seleccionado est presente
    final exerciseItems = List<ExerciseModel>.from(provider.exercises);
    if (_selectedExercise != null &&
        !exerciseItems.any((e) => e.id == _selectedExercise!.id)) {
      exerciseItems.insert(0, _selectedExercise!);
    }

    final selectedDateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final supersetExercisesOnDate = provider.routines.where((r) {
      final rDate = r.scheduledDate.contains('T')
          ? r.scheduledDate.split('T')[0]
          : r.scheduledDate;
      if (isEditing && r.dailyExerciseId == widget.routineToEdit!.dailyExerciseId) {
        return false;
      }
      return (r.superSetTag != null && r.superSetTag!.trim().isNotEmpty) &&
          rDate == selectedDateStr;
    }).toList();

    final Map<String, List<DailyStudentExercise>> existingSuperSetsByTag = {};
    for (final r in supersetExercisesOnDate) {
      final tag = (r.superSetTag ?? '').trim().toUpperCase();
      if (tag.isEmpty) continue;
      existingSuperSetsByTag.putIfAbsent(tag, () => []).add(r);
    }
    for (final tag in existingSuperSetsByTag.keys) {
      existingSuperSetsByTag[tag]!
          .sort((a, b) => (a.superSetOrder ?? 1).compareTo(b.superSetOrder ?? 1));
    }

    final existingTags = existingSuperSetsByTag.keys.toList()..sort();
    final nextAvailableTag = getNextAvailableSuperSetTag(existingTags);
    final effectiveTag = _isSuperSet
        ? (_selectedSuperSetTag.isNotEmpty
            ? _selectedSuperSetTag
            : (existingTags.isNotEmpty ? existingTags.first : 'A'))
        : '';

    final currentTagExercises = existingSuperSetsByTag[effectiveTag] ?? [];
    final hasExistingInSelectedTag = currentTagExercises.isNotEmpty;
    final firstExerciseInSelectedTag =
        hasExistingInSelectedTag ? currentTagExercises.first : null;
    final establishedRestInSelectedTag =
        firstExerciseInSelectedTag?.dailyExerciseSets.isNotEmpty == true
            ? firstExerciseInSelectedTag!.dailyExerciseSets.first.restTime
            : '90';

    final effectiveOrder =
        hasExistingInSelectedTag ? currentTagExercises.length + 1 : 1;

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

              // Muscle Group (Habilitado tanto en creacin como en edicin)
              Text('GRUPO MUSCULAR', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              DropdownButtonFormField<MuscleGroup>(
                key: ValueKey('mg_${_selectedMuscleGroup?.id}'),
                isExpanded: true,
                initialValue: _selectedMuscleGroup,
                hint: const Text('Seleccionar grupo muscular', style: TextStyle(fontSize: 14)),
                items: muscleGroupItems
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (MuscleGroup? data) {
                  setState(() {
                    _selectedMuscleGroup = data;
                    _selectedExercise = null;
                  });
                  if (data != null && data.id > 0) {
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
                      .withValues(alpha: 0.3),
                ),
                dropdownColor: theme.colorScheme.surfaceContainerHighest,
              ),

              const SizedBox(height: 8),
              Center(
                child: InkWell(
                  onTap: () async {
                    final newEx = await showDialog<ExerciseModel>(
                      context: context,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: QuickCreateExerciseDialog(
                          initialMuscleGroupId: _selectedMuscleGroup?.id,
                        ),
                      ),
                    );
                    if (newEx != null && mounted) {
                      if (_selectedMuscleGroup == null ||
                          _selectedMuscleGroup!.id != newEx.muscleGroupId) {
                        final matchingGroup = provider.muscleGroups.cast<MuscleGroup?>().firstWhere(
                          (m) => m != null && m.id == newEx.muscleGroupId,
                          orElse: () => provider.muscleGroups.isNotEmpty ? provider.muscleGroups.first : null,
                        );
                        setState(() {
                          _selectedMuscleGroup = matchingGroup;
                        });
                      }
                      await provider.loadExercisesForMuscleGroup(newEx.muscleGroupId);
                      if (!mounted || !context.mounted) return;
                      setState(() {
                        _selectedExercise = provider.exercises.cast<ExerciseModel?>().firstWhere(
                          (e) =>
                              e != null &&
                              (e.id == newEx.id ||
                               e.name.toLowerCase() == newEx.name.toLowerCase()),
                          orElse: () => newEx,
                        );
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ejercicio "${newEx.name}" creado y seleccionado',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 16, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          '¿No encuentras el ejercicio? Crear nuevo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Exercise (Habilitado tanto en creacin como en edicin)
              Text('EJERCICIO', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ExerciseModel>(
                key: ValueKey('ex_${_selectedExercise?.id}'),
                isExpanded: true,
                initialValue: _selectedExercise,
                hint: const Text('Seleccionar ejercicio', style: TextStyle(fontSize: 14)),
                items: exerciseItems
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (ExerciseModel? data) {
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
                      .withValues(alpha: 0.3),
                ),
                dropdownColor: theme.colorScheme.surfaceContainerHighest,
              ),

              const SizedBox(height: 16),

              // Date Picker
              Text('FECHA ASIGNADA', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Serie Combinada (Superserie / Biseries)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuperSet
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuperSet
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: _isSuperSet
                              ? const Color(0xFFF59E0B)
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Serie Combinada (Superserie)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _isSuperSet
                                      ? const Color(0xFFF59E0B)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Combina ejercicios sin descanso entre ellos.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isSuperSet,
                          activeThumbColor: const Color(0xFFF59E0B),
                          onChanged: (val) {
                            setState(() {
                              _isSuperSet = val;
                              if (val) {
                                if (hasExistingInSelectedTag && establishedRestInSelectedTag.isNotEmpty) {
                                  _combinedRestTime = establishedRestInSelectedTag;
                                }
                                for (var s in _sets) {
                                  s['restTime'] = _combinedRestTime;
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    if (_isSuperSet) ...[
                      const Divider(height: 16),
                      Text(
                        'COMBINACIN (IDENTIFICADOR)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF59E0B),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('tag_$_selectedSuperSetTag'),
                        isExpanded: true,
                        initialValue: existingTags.contains(_selectedSuperSetTag)
                            ? _selectedSuperSetTag
                            : (_selectedSuperSetTag == nextAvailableTag
                                ? nextAvailableTag
                                : (existingTags.isNotEmpty ? existingTags.first : nextAvailableTag)),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        dropdownColor: theme.colorScheme.surfaceContainerHighest,
                        items: [
                          ...existingTags.map((tag) {
                            final count = existingSuperSetsByTag[tag]?.length ?? 0;
                            return DropdownMenuItem<String>(
                              value: tag,
                              child: Text(
                                'Unir a Serie #$tag ($count ejercicio${count == 1 ? '' : 's'})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }),
                          DropdownMenuItem<String>(
                            value: nextAvailableTag,
                            child: Text(
                              'Nueva Serie Combinada #$nextAvailableTag',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSuperSetTag = val;
                              final newTagExercises = existingSuperSetsByTag[val] ?? [];
                              if (newTagExercises.isNotEmpty) {
                                final firstEx = newTagExercises.first;
                                if (firstEx.dailyExerciseSets.isNotEmpty) {
                                  _combinedRestTime = firstEx.dailyExerciseSets.first.restTime;
                                  for (var s in _sets) {
                                    s['restTime'] = _combinedRestTime;
                                  }
                                }
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Descanso de la ronda combinada
                      Text(
                        hasExistingInSelectedTag
                            ? 'DESCANSO DE LA COMBINACIN (Heredado de la serie existente)'
                            : 'DESCANSO AL TERMINAR LA COMBINACIN COMPLETA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF59E0B),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RestTimeInputField(
                        key: ValueKey('combined_rest_$_combinedRestTime'),
                        initialValue: _combinedRestTime,
                        label: 'Descanso de ronda',
                        enabled: !hasExistingInSelectedTag,
                        onChanged: (val) {
                          setState(() {
                            _combinedRestTime = val;
                            for (var s in _sets) {
                              s['restTime'] = val;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasExistingInSelectedTag
                            ? 'Este ejercicio se aadir como #$effectiveOrder de la combinacin #$effectiveTag. El descanso ser de ${_combinedRestTime.isNotEmpty ? _combinedRestTime : "90"}s al completar toda la ronda.'
                            : 'Los ejercicios combinados se realizan seguidos sin descanso. El cronmetro de descanso se activar slo al completar el ltimo ejercicio de la ronda.',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Coach Notes
              Text('NOTAS DEL ENTRENADOR', style: _labelStyle(theme)),
              const SizedBox(height: 8),
              TextField(
                controller: _coachNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Instrucciones o recomendaciones...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
              ),

              const SizedBox(height: 24),

              // Sets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SERIES', style: _labelStyle(theme)),
                  Row(
                    children: [
                      if (_copiedSet != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _sets.insert(0, {
                                'id': 0,
                                'targetReps': _copiedSet!['targetReps'],
                                'targetWeight': _copiedSet!['targetWeight'],
                                'restTime': _isSuperSet ? _combinedRestTime : _copiedSet!['restTime'],
                                '_key': 'paste_${DateTime.now().microsecondsSinceEpoch}',
                              });
                            });
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nueva serie pegada arriba'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.paste_rounded, size: 14),
                          label: const Text('Pegar nueva',
                              style: TextStyle(fontSize: 12)),
                        ),
                      TextButton.icon(
                        onPressed: _addEmptySet,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Añadir Serie',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sets List
              ..._sets.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> set = entry.value;
                return Container(
                  key: ValueKey(set['_key'] ?? 'set_$idx'),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () => _copySet(set),
                                icon: const Icon(Icons.copy_rounded, size: 13),
                                label: const Text('Copiar',
                                    style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: () => _duplicateSet(set),
                                icon: const Icon(
                                    Icons.control_point_duplicate_rounded,
                                    size: 13),
                                label: const Text('Duplicar',
                                    style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              if (_sets.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: theme.colorScheme.error, size: 18),
                                  onPressed: () => _removeSet(idx),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  tooltip: 'Eliminar serie',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('reps_${set['_key'] ?? idx}'),
                              initialValue: set['targetReps'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Reps', isDense: true),
                              onChanged: (v) => set['targetReps'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: WeightInputField(
                              key: ValueKey('weight_${set['_key'] ?? idx}'),
                              initialValue: set['targetWeight'],
                              onChanged: (v) => set['targetWeight'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: RestTimeInputField(
                              key: ValueKey('rest_${set['_key'] ?? idx}'),
                              initialValue: set['restTime'] ?? '',
                              enabled: !_isSuperSet,
                              label: _isSuperSet ? 'Descanso (Fijo)' : 'Descanso',
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
                  onPressed: () => _save(
                    context,
                    provider,
                    effectiveTag: effectiveTag,
                    effectiveOrder: effectiveOrder,
                  ),
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

  Future<void> _save(
    BuildContext context,
    RoutinesProvider provider, {
    required String effectiveTag,
    required int effectiveOrder,
  }) async {
    final isEditing = widget.routineToEdit != null;

    if (_selectedMuscleGroup == null || _selectedExercise == null) {
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
      final dailyExerciseId = widget.routineToEdit!.dailyExerciseId;

      // 1. Eliminar sets que fueron removidos por el usuario en la interfaz
      final originalSetIds = widget.routineToEdit!.dailyExerciseSets
          .map((s) => s.id)
          .where((id) => id > 0)
          .toSet();
      final currentSetIds = _sets
          .map((s) => (s['id'] as int?) ?? 0)
          .where((id) => id > 0)
          .toSet();
      final deletedSetIds = originalSetIds.difference(currentSetIds);

      if (deletedSetIds.isNotEmpty) {
        await Future.wait(
          deletedSetIds.map((id) => RoutineService.deleteDailyExercisesSets(id)),
        );
      }

      // 2. Mapear todos los sets (existentes con su ID y nuevos con id: 0)
      final allSetsPayload = _sets.mapIndexed((index, s) {
        final rawId = (s['id'] as int?) ?? 0;
        return {
          'id': rawId > 0 ? rawId : 0,
          'dailyStudentExerciseId': dailyExerciseId,
          'setNumber': index + 1,
          'targetReps': int.tryParse(s['targetReps'].toString()) ?? 0,
          'targetWeight': parseWeightNum(s['targetWeight']),
          'restTime': s['restTime'].toString(),
          'isAchieved': false,
        };
      }).toList();

      final effectiveExId = _selectedExercise!.id;
      final effectiveExName = _selectedExercise!.name;
      final effectiveMuscleName = _selectedMuscleGroup!.name;
      final effectiveMuscleId = _selectedMuscleGroup!.id;

      final Map<String, dynamic> data = {
        'id': dailyExerciseId,
        'coachId': widget.routineToEdit!.coachId,
        'studentId': widget.routineToEdit!.studentId,
        'exerciseId': effectiveExId,
        'scheduledDate': _selectedDate.toIso8601String(),
        'exerciseName': effectiveExName,
        'muscleGroupId': effectiveMuscleId > 0 ? effectiveMuscleId : null,
        'muscleGroupName': effectiveMuscleName,
        'coachNotes': _coachNotesController.text,
        'superSetTag': _isSuperSet ? effectiveTag : null,
        'superSetOrder': _isSuperSet ? effectiveOrder : null,
        'dailyExerciseSets': allSetsPayload,
      };

      logDebug('Updating routine: $data');

      final success = await provider.updateRoutine(dailyExerciseId, data, const []);
      if (success && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
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
                'targetReps': int.tryParse(entry.value['targetReps'].toString()) ?? 0,
                'targetWeight': parseWeightNum(entry.value['targetWeight']),
                'restTime': entry.value['restTime'].toString(),
                'isAchieved': false,
              })
          .toList();

      final Map<String, dynamic> data = {
        'assign': <String, dynamic>{
          'coachId': provider.authProvider.user?.coachId,
          'studentId': 0,
          'exerciseId': _selectedExercise!.id,
          'scheduledDate': _selectedDate.toIso8601String(),
          'dailyExerciseSets': setsData,
          'coachNotes': _coachNotesController.text,
          'superSetTag': _isSuperSet ? effectiveTag : null,
          'superSetOrder': _isSuperSet ? effectiveOrder : null,
        }
      };

      Navigator.pop(context, data);
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
