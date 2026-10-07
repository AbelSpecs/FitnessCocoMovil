import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/models/muscle_group_model.dart';
import 'package:pyrosfitmovil/core/services/routine_service.dart';
import 'package:pyrosfitmovil/core/utils/exercise_filter.dart';
import 'package:pyrosfitmovil/core/widgets/rest_time_input_field.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/quick_create_exercise_dialog.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class AddStudentDailyExerciseSheet extends StatefulWidget {
  final int studentId;
  final String scheduledDate;

  const AddStudentDailyExerciseSheet({
    super.key,
    required this.studentId,
    required this.scheduledDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int studentId,
    required String scheduledDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddStudentDailyExerciseSheet(
        studentId: studentId,
        scheduledDate: scheduledDate,
      ),
    );
  }

  @override
  State<AddStudentDailyExerciseSheet> createState() =>
      _AddStudentDailyExerciseSheetState();
}

class _AddStudentDailyExerciseSheetState
    extends State<AddStudentDailyExerciseSheet> {
  bool _isLoadingGroups = true;
  bool _isLoadingExercises = false;
  bool _isSaving = false;

  List<MuscleGroup> _muscleGroups = [];
  List<ExerciseModel> _exercises = [];

  MuscleGroup? _selectedGroup;
  ExerciseModel? _selectedExercise;

  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _sets = [
    {'targetReps': '12', 'targetWeight': '20', 'restTime': '90', '_key': 'init_0'},
  ];
  Map<String, String>? _copiedSet;

  @override
  void initState() {
    super.initState();
    _loadMuscleGroups();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMuscleGroups() async {
    try {
      final raw = await RoutineService.getMuscleGroups();
      if (raw != null && mounted) {
        setState(() {
          _muscleGroups = raw.map((e) => MuscleGroup.fromJson(e)).toList();
          _isLoadingGroups = false;
          if (_muscleGroups.isNotEmpty) {
            _selectedGroup = _muscleGroups.first;
            _loadExercisesForGroup(_selectedGroup!.id);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadExercisesForGroup(int groupId) async {
    setState(() {
      _isLoadingExercises = true;
      _selectedExercise = null;
    });

    try {
      final raw = await RoutineService.getExerciseByMuscleGroupId(groupId);
      if (raw != null && mounted) {
        final auth = context.read<AuthProvider>();
        final parsed = raw.map((e) => ExerciseModel.fromJson(e)).toList();
        final visible = filterExercisesForUser(parsed, auth.user, widget.studentId);

        setState(() {
          _exercises = visible;
          _isLoadingExercises = false;
          if (_exercises.isNotEmpty) {
            _selectedExercise = _exercises.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingExercises = false);
    }
  }

  void _addSet() {
    setState(() {
      final firstSet = _sets.isNotEmpty ? _sets.first : {'targetReps': '12', 'targetWeight': '20', 'restTime': '90'};
      _sets.insert(0, {
        'targetReps': firstSet['targetReps'] ?? '12',
        'targetWeight': firstSet['targetWeight'] ?? '20',
        'restTime': firstSet['restTime'] ?? '90',
        '_key': 'new_${DateTime.now().microsecondsSinceEpoch}',
      });
    });
  }

  void _copySet(Map<String, String> set) {
    setState(() {
      _copiedSet = {
        'targetReps': set['targetReps'] ?? '',
        'targetWeight': set['targetWeight'] ?? '',
        'restTime': set['restTime'] ?? '',
      };
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Serie copiada: ${set['targetReps']?.isNotEmpty == true ? set['targetReps'] : '0'} reps • ${set['targetWeight']?.isNotEmpty == true ? set['targetWeight'] : '0'} kg',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateSet(Map<String, String> set) {
    setState(() {
      _sets.insert(0, {
        'targetReps': set['targetReps'] ?? '',
        'targetWeight': set['targetWeight'] ?? '',
        'restTime': set['restTime'] ?? '',
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

  void _pasteSet() {
    if (_copiedSet == null) return;
    setState(() {
      _sets.insert(0, {
        'targetReps': _copiedSet!['targetReps'] ?? '12',
        'targetWeight': _copiedSet!['targetWeight'] ?? '20',
        'restTime': _copiedSet!['restTime'] ?? '90',
        '_key': 'paste_${DateTime.now().microsecondsSinceEpoch}',
      });
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Serie pegada: Se añadió la serie copiada arriba'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un ejercicio para agregar')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final setsData = _sets.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      return {
        'id': 0,
        'dailyStudentExerciseId': 0,
        'setNumber': idx + 1,
        'targetReps': int.tryParse(s['targetReps'] ?? '12') ?? 12,
        'targetWeight': int.tryParse(s['targetWeight'] ?? '0') ?? 0,
        'restTime': (s['restTime']?.trim().isNotEmpty == true) ? s['restTime']! : '90',
        'isAchieved': false,
      };
    }).toList();

    final dateStr = widget.scheduledDate.contains('T')
        ? widget.scheduledDate
        : '${widget.scheduledDate}T12:00:00Z';

    final payload = {
      'coachId': null,
      'studentId': widget.studentId,
      'exerciseId': _selectedExercise!.id,
      'scheduledDate': dateStr,
      'coachNotes': _notesController.text.trim(),
      'dailyExerciseSets': setsData,
    };

    try {
      final response = await RoutineService.postDailyStudentExercises(payload);
      if (response != null && mounted) {
        await context
            .read<StudentRoutinesProvider>()
            .fetchDailyExercises(widget.studentId, widget.scheduledDate);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Error al registrar ejercicio diario');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo agregar el ejercicio a la rutina.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_task_rounded, color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Agregar ejercicio al día',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Añade un ejercicio con sus series y tiempos de descanso a tu rutina de hoy.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 18),

            // Grupo Muscular Dropdown
            const Text(
              'GRUPO MUSCULAR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            if (_isLoadingGroups)
              const LinearProgressIndicator(color: AppTheme.primary)
            else
              DropdownButtonFormField<MuscleGroup>(
                initialValue: _selectedGroup,
                isExpanded: true,
                dropdownColor: const Color(0xFF202024),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1B1B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _muscleGroups.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g.name));
                }).toList(),
                onChanged: (g) {
                  if (g != null) {
                    setState(() => _selectedGroup = g);
                    _loadExercisesForGroup(g.id);
                  }
                },
              ),
            const SizedBox(height: 14),

            // Ejercicio Dropdown
            const Text(
              'EJERCICIO',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            if (_isLoadingExercises)
              const LinearProgressIndicator(color: AppTheme.primary)
            else ...[
              DropdownButtonFormField<ExerciseModel>(
                initialValue: _selectedExercise,
                isExpanded: true,
                dropdownColor: const Color(0xFF202024),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1B1B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _exercises.map((ex) {
                  return DropdownMenuItem(
                    value: ex,
                    child: Text(cleanExerciseDescription(ex.name)),
                  );
                }).toList(),
                onChanged: (ex) {
                  if (ex != null) setState(() => _selectedExercise = ex);
                },
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final created = await showDialog<ExerciseModel>(
                      context: context,
                      builder: (_) => QuickCreateExerciseDialog(
                        initialMuscleGroupId: _selectedGroup?.id,
                      ),
                    );
                    if (created != null && mounted) {
                      await _loadExercisesForGroup(_selectedGroup!.id);
                      setState(() {
                        _selectedExercise = _exercises.firstWhere(
                          (e) => e.id == created.id,
                          orElse: () => created,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 14, color: AppTheme.primaryGlow),
                  label: const Text(
                    '¿No encuentras el ejercicio? Crea uno',
                    style: TextStyle(
                      color: AppTheme.primaryGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Series Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SERIES (${_sets.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2),
                ),
                TextButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                  label: const Text('Agregar serie (arriba)', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (_copiedSet != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pasteSet,
                  icon: const Icon(Icons.paste_rounded, size: 14, color: AppTheme.primaryGlow),
                  label: Text(
                    'Pegar serie (${_copiedSet!['targetReps']} reps • ${_copiedSet!['targetWeight']} kg)',
                    style: const TextStyle(color: AppTheme.primaryGlow, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6)),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),

            // Filas de Series
            ..._sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;

              return Container(
                key: ValueKey(set['_key'] ?? 'set_$idx'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Serie #${idx + 1}',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => _copySet(set),
                              icon: const Icon(Icons.copy_rounded, size: 13, color: Colors.white70),
                              label: const Text('Copiar', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => _duplicateSet(set),
                              icon: const Icon(Icons.control_point_duplicate_rounded, size: 13, color: Colors.white70),
                              label: const Text('Duplicar', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            if (_sets.length > 1) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('reps_${set['_key'] ?? idx}'),
                            initialValue: set['targetReps'],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                            onChanged: (v) => set['targetReps'] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('weight_${set['_key'] ?? idx}'),
                            initialValue: set['targetWeight'],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Peso (kg)', isDense: true),
                            onChanged: (v) => set['targetWeight'] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: RestTimeInputField(
                            key: ValueKey('rest_${set['_key'] ?? idx}'),
                            initialValue: set['restTime'] ?? '90',
                            onChanged: (v) => set['restTime'] = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Notas
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Notas / Instrucciones (opcional)',
                hintText: 'Ej. Controlar la bajada en 3 segundos',
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isSaving ? 'Guardando...' : 'Agregar a la Rutina',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
