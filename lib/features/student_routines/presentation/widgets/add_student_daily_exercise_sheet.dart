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
    {'targetReps': '12', 'targetWeight': '20', 'restTime': '90'},
  ];

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
      final lastSet = _sets.isNotEmpty ? _sets.last : {'targetReps': '12', 'targetWeight': '20', 'restTime': '90'};
      _sets.add({
        'targetReps': lastSet['targetReps'] ?? '12',
        'targetWeight': lastSet['targetWeight'] ?? '20',
        'restTime': lastSet['restTime'] ?? '90',
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
                  label: const Text('Agregar serie', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Filas de Series
            ..._sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;

              return Container(
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
                        if (_sets.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            onPressed: () => _removeSet(idx),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
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
