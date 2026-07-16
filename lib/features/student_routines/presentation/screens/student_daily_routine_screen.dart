import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';

class StudentDailyRoutineScreen extends StatefulWidget {
  final int studentId;
  final String dayId;

  const StudentDailyRoutineScreen(
      {super.key, required this.studentId, required this.dayId});

  @override
  State<StudentDailyRoutineScreen> createState() =>
      _StudentDailyRoutineScreenState();
}

class _StudentDailyRoutineScreenState extends State<StudentDailyRoutineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<StudentRoutinesProvider>()
          .fetchDailyExercises(widget.studentId, widget.dayId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentRoutinesProvider>();
    final theme = Theme.of(context);
    final exercises = provider.dailyExercises;

    // Calcular info del día
    final isRest = exercises.isEmpty;
    final date = DateTime.tryParse(widget.dayId) ?? DateTime.now();
    final dayName = DateFormat('EEEE', 'es_US').format(date);
    final muscleGroup = isRest ? 'Descanso' : exercises.first.muscleGroupName;

    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/rutina/${widget.studentId}'),
          ),
          title:
              const Text('Volver a la semana', style: TextStyle(fontSize: 14)),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.transparent, Color(0xFF151518)]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 3.0,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            muscleGroup,
                            style: const TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 48,
                              height: 1.0,
                            ),
                          ),
                          if (!isRest) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${exercises.length} ejercicios',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (isRest)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Column(
                          children: [
                            Text('🌿', style: TextStyle(fontSize: 72)),
                            SizedBox(height: 16),
                            Text(
                              'Descanso',
                              style: TextStyle(
                                  fontFamily: 'BebasNeue', fontSize: 32),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Recuperarse es parte del entrenamiento. Hidrátate, duerme bien y mueve el cuerpo con calma.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ...exercises.asMap().entries.map((entry) {
                        return _ExerciseRow(
                          exercise: entry.value,
                          index: entry.key + 1,
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ExerciseRow extends StatefulWidget {
  final GetDailyStudentExerciseDto exercise;
  final int index;

  const _ExerciseRow({required this.exercise, required this.index});

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  bool _expanded = false;
  late TextEditingController _notesController;
  // Local state for sets to avoid full rebuilds on every check
  late List<bool> _setsCompleted;
  bool _isDone = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isDone = widget.exercise.isCompleted;
    _notesController =
        TextEditingController(text: widget.exercise.studentNotes);
    _setsCompleted =
        widget.exercise.dailyExerciseSets.map((s) => s.isAchieved).toList();
  }

  @override
  void didUpdateWidget(covariant _ExerciseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exercise.id != oldWidget.exercise.id ||
        widget.exercise.isCompleted != oldWidget.exercise.isCompleted) {
      _isDone = widget.exercise.isCompleted;
      _notesController.text = widget.exercise.studentNotes;
      _setsCompleted =
          widget.exercise.dailyExerciseSets.map((s) => s.isAchieved).toList();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeExercise() async {
    setState(() {
      _isSaving = true;
    });
    final provider = context.read<StudentRoutinesProvider>();
    final success = await provider.completeExercise(
        widget.exercise.id, _notesController.text);
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _isDone = true;
          _expanded = false;
        }
      });
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al terminar ejercicio')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = _isDone;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green : AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(Icons.check_circle, color: Colors.white)
                        : Text(
                            '${widget.index}',
                            style: const TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.exerciseName,
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 24,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.exercise.coachNotes.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.notes,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.exercise.coachNotes,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '${widget.exercise.dailyExerciseSets.length} series',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 12),
                  // Notas del coach enteras si existen
                  if (widget.exercise.coachNotes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppTheme.border.withOpacity(0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote,
                              color: AppTheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.exercise.coachNotes,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // Filas de series
                  ...widget.exercise.dailyExerciseSets
                      .asMap()
                      .entries
                      .map((entry) {
                    final idx = entry.key;
                    final set = entry.value;
                    final checked = _setsCompleted[idx];

                    return _SetRow(
                      index: idx,
                      set: set,
                      isChecked: checked,
                      onToggle: (val, actualReps, actualWeight) async {
                        setState(() {
                          _setsCompleted[idx] = val;
                        });

                        final provider =
                            context.read<StudentRoutinesProvider>();
                        final success = await provider.completeExerciseSet(
                            set, val, actualReps, actualWeight);
                        if (!success) {
                          if (mounted) {
                            setState(() {
                              _setsCompleted[idx] = !val;
                            });
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Error al actualizar la serie')));
                          }
                        }
                      },
                    );
                  }),

                  const SizedBox(height: 16),

                  // Notas del estudiante
                  const Text('NOTAS (Opcional)',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '¿Cómo se sintió el peso?',
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                    enabled: !isDone,
                  ),

                  const SizedBox(height: 16),

                  // Botón de guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isSaving || isDone) ? null : _completeExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Terminar Ejercicio',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int index;
  final GetDailyExerciseSetsDto set;
  final bool isChecked;
  final void Function(bool, int?, int?) onToggle;

  const _SetRow({
    required this.index,
    required this.set,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.set.actualReps?.toString() ?? "",
    );
    _weightController = TextEditingController(
      text: widget.set.actualWeight?.toString() ?? "",
    );
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.set.id != oldWidget.set.id) {
      _repsController.text =
          widget.set.actualReps?.toString() ?? widget.set.targetReps;
      _weightController.text =
          widget.set.actualWeight?.toString() ?? widget.set.targetWeight;
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checked = widget.isChecked;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: checked ? Colors.green.withValues(alpha: 0.1) : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                checked ? Colors.green.withValues(alpha: 0.3) : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Serie ${widget.index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text('Objetivo: ',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7))),
              Text(
                '${widget.set.targetReps} reps • ${widget.set.targetWeight} kg',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reps logradas',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _repsController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          color: checked ? Colors.green : Colors.white,
                          fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        hintText: "Reps",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                      onChanged: (val) {
                        if (checked) widget.onToggle(false, null, null);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peso logrado (kg)',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _weightController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          color: checked ? Colors.green : Colors.white,
                          fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        hintText: "Kg",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                      onChanged: (val) {
                        if (checked) widget.onToggle(false, null, null);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text('Hecho',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      final reps = int.tryParse(_repsController.text) ??
                          int.tryParse(widget.set.targetReps);
                      final weight = int.tryParse(_weightController.text) ??
                          int.tryParse(widget.set.targetWeight);
                      widget.onToggle(!checked, reps, weight);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: checked ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: checked ? Colors.green : Colors.grey),
                      ),
                      child: checked
                          ? const Icon(Icons.check,
                              size: 20, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
