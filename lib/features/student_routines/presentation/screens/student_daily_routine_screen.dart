import 'package:pyrosfitmovil/core/utils/exercise_filter.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/widgets/add_student_daily_exercise_sheet.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_video_modal.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/video_thumbnail_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/core/services/streak_service.dart';
import 'package:pyrosfitmovil/core/widgets/rest_timer_widget.dart';
import 'package:pyrosfitmovil/core/utils/time_utils.dart';
import 'package:pyrosfitmovil/core/utils/weight_utils.dart';

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
  bool _isTimerActive = false;
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  String? _timerLabel;
  int _timerKey = 0;

  void _startRestTimer(String rawRestTime, String label) {
    final seconds = parseRestTimeToSeconds(rawRestTime);
    final actualSeconds = seconds > 0 ? seconds : 60;

    // Si ya existe un cronómetro activo o visible, cerrarlo primero para garantizar una única instancia
    if (_isTimerActive) {
      _closeRestTimer();
      // Desmontar completamente la instancia anterior antes de montar la nueva
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _timerSeconds = actualSeconds;
          _timerLabel = label;
          _timerKey++;
          _isTimerActive = true;
          _isTimerRunning = true;
        });
      });
    } else {
      setState(() {
        _timerSeconds = actualSeconds;
        _timerLabel = label;
        _timerKey++;
        _isTimerActive = true;
        _isTimerRunning = true;
      });
    }
  }

  void _handleTimerFinish() {
    setState(() {
      _isTimerRunning = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.timer_off_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Descanso completado! Listo para continuar con tu siguiente serie 🔥',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleTimerRestart() {
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _closeRestTimer() {
    setState(() {
      _isTimerActive = false;
      _isTimerRunning = false;
    });
  }
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
    final auth = context.watch<AuthProvider>();
    final isIndependent = isUserIndependent(auth.user);
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
            : SizedBox.expand(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (!isRest)
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
                              if (isIndependent) ...[
                                if (!isRest) const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    AddStudentDailyExerciseSheet.show(
                                      context,
                                      studentId: widget.studentId,
                                      scheduledDate: widget.dayId,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Agregar ejercicio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          )
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
                        child: Column(
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 72)),
                            const SizedBox(height: 16),
                            const Text(
                              'Descanso',
                              style: TextStyle(
                                  fontFamily: 'BebasNeue', fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Recuperarse es parte del entrenamiento. Hidrátate, duerme bien y mueve el cuerpo con calma.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (isIndependent) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  AddStudentDailyExerciseSheet.show(
                                    context,
                                    studentId: widget.studentId,
                                    scheduledDate: widget.dayId,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Agregar ejercicio a este día',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      ...exercises.asMap().entries.map((entry) {
                        return _ExerciseRow(
                          exercise: entry.value,
                          index: entry.key + 1,
                          isRestTimerRunning: _isTimerRunning,
                          onStartTimer: _startRestTimer,
                        );
                      }),
                  ],
                ),
              ),
                    ),
                    if (_isTimerActive && _timerSeconds > 0)
                      RestTimerWidget(
                        key: ValueKey('rest_timer_$_timerKey'),
                        seconds: _timerSeconds,
                        label: _timerLabel,
                        onClose: _closeRestTimer,
                        onFinished: _handleTimerFinish,
                        onRestart: _handleTimerRestart,
                      ),
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
  final bool isRestTimerRunning;
  final void Function(String restTime, String label)? onStartTimer;

  const _ExerciseRow({
    required this.exercise,
    required this.index,
    this.isRestTimerRunning = false,
    this.onStartTimer,
  });

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

  List<GetDailyExerciseSetsDto> get _sortedSets {
    final list = [...widget.exercise.dailyExerciseSets];
    list.sort((a, b) =>
        (int.tryParse(a.setNumber) ?? 0).compareTo(int.tryParse(b.setNumber) ?? 0));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _isDone = widget.exercise.isCompleted;
    _notesController =
        TextEditingController(text: widget.exercise.studentNotes);
    _setsCompleted =
        _sortedSets.map((s) => s.isAchieved).toList();
  }

  @override
  void didUpdateWidget(covariant _ExerciseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isDone = widget.exercise.isCompleted;
    _notesController.text = widget.exercise.studentNotes;
    _setsCompleted =
        _sortedSets.map((s) => s.isAchieved).toList();
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
      if (success) {
        // Verificar si todos los ejercicios de la rutina diaria están completados
        final currentExercises = provider.dailyExercises;
        final allCompleted = currentExercises.isNotEmpty &&
            currentExercises.every((item) =>
                item.id == widget.exercise.id ? true : item.isCompleted);

        if (allCompleted) {
          // Formatear fecha localmente sin desfases de UTC
          final rawDate = widget.exercise.scheduledDate;
          final dateStr = rawDate.isNotEmpty
              ? (rawDate.contains('T') ? rawDate.split('T')[0] : rawDate)
              : DateFormat('yyyy-MM-dd').format(DateTime.now());
          final isoActivityDate = '${dateStr}T12:00:00Z';

          try {
            await StreakService.postWorkoutCompleted(
              widget.exercise.studentId,
              isoActivityDate,
            );
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Rutina completada! Has completado todos los ejercicios del día. Racha y progreso actualizados 🔥',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Ejercicio completado! Progreso guardado 💪',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al terminar ejercicio')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (widget.exercise.hasVideo)
                    GestureDetector(
                      onTap: () {
                        ExerciseVideoModal.show(
                          context,
                          widget.exercise.toExerciseModel(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded, size: 14, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

                  // Miniatura interactiva de video si está disponible (como en la web)
                  if (widget.exercise.hasVideo) ...[
                    GestureDetector(
                      onTap: () {
                        ExerciseVideoModal.show(
                          context,
                          widget.exercise.toExerciseModel(),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.7),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            VideoThumbnailBadge(
                              videoKey: widget.exercise.videoKey,
                              videoUrl: widget.exercise.videoUrl,
                              height: 140,
                              width: double.infinity,
                              onTap: () {
                                ExerciseVideoModal.show(
                                  context,
                                  widget.exercise.toExerciseModel(),
                                );
                              },
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.85),
                                      Colors.black.withValues(alpha: 0.95),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Ver técnica de ${widget.exercise.exerciseName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Reproducir',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Notas del coach enteras si existen
                  if (widget.exercise.coachNotes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
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

                  // Filas de series ordenadas por setNumber
                  ..._sortedSets.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final set = entry.value;
                    final checked = idx < _setsCompleted.length ? _setsCompleted[idx] : false;

                    // Una serie se bloquea si alguna serie anterior aún no está completada
                    final isLocked = idx > 0 &&
                        !_setsCompleted.sublist(0, idx).every((achieved) => achieved);

                    return _SetRow(
                      index: idx,
                      set: set,
                      isChecked: checked,
                      isLocked: isLocked,
                      isRestTimerRunning: widget.isRestTimerRunning,
                      onStartTimer: () {
                        widget.onStartTimer?.call(
                          set.restTime,
                          '${widget.exercise.exerciseName} • Serie #${set.setNumber}',
                        );
                      },
                      onToggle: (val, actualReps, actualWeight) async {
                        setState(() {
                          if (idx < _setsCompleted.length) {
                            _setsCompleted[idx] = val;
                          }
                        });

                        // Disparar inmediatamente el cronómetro de descanso si se marca como completada
                        if (val) {
                          final restSec = parseRestTimeToSeconds(set.restTime);
                          if (restSec > 0) {
                            widget.onStartTimer?.call(
                              set.restTime,
                              '${widget.exercise.exerciseName} • Serie #${set.setNumber}',
                            );
                          }
                        }

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
                          (_isSaving || isDone || widget.isRestTimerRunning) ? null : _completeExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (!isDone && widget.isRestTimerRunning)
                            ? AppTheme.primary.withValues(alpha: 0.4)
                            : (isDone
                                ? Colors.grey.withValues(alpha: 0.3)
                                : AppTheme.primary),
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
                          : Text(
                              (!isDone && widget.isRestTimerRunning)
                                  ? 'Descanso en curso...'
                                  : (isDone ? 'Completado' : 'Terminar Ejercicio'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
  final bool isLocked;
  final bool isRestTimerRunning;
  final void Function(bool, int?, int?) onToggle;
  final VoidCallback? onStartTimer;

  const _SetRow({
    required this.index,
    required this.set,
    required this.isChecked,
    this.isLocked = false,
    this.isRestTimerRunning = false,
    required this.onToggle,
    this.onStartTimer,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.set.actualReps != null
          ? widget.set.actualReps.toString()
          : (widget.isChecked ? widget.set.targetReps : ""),
    );
    _weightController = TextEditingController(
      text: widget.set.actualWeight != null
          ? widget.set.actualWeight.toString()
          : (widget.isChecked ? widget.set.targetWeight : ""),
    );
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.set.id != oldWidget.set.id ||
        widget.set.actualReps != oldWidget.set.actualReps ||
        widget.set.actualWeight != oldWidget.set.actualWeight ||
        widget.isChecked != oldWidget.isChecked) {
      if (widget.set.actualReps != null) {
        _repsController.text = widget.set.actualReps.toString();
      } else if (widget.isChecked && _repsController.text.isEmpty) {
        _repsController.text = widget.set.targetReps;
      }

      if (widget.set.actualWeight != null) {
        _weightController.text = widget.set.actualWeight.toString();
      } else if (widget.isChecked && _weightController.text.isEmpty) {
        _weightController.text = widget.set.targetWeight;
      }
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
    final isLocked = widget.isLocked;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: checked
              ? Colors.green.withValues(alpha: 0.1)
              : (isLocked
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.black12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked
                ? Colors.green.withValues(alpha: 0.3)
                : (isLocked ? Colors.white12 : Colors.white24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Serie #${widget.set.setNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Bloqueada hasta completar la serie anterior',
                    child: Icon(Icons.lock_outline,
                        size: 14, color: Colors.white54),
                  ),
                ],
                if (widget.set.restTime.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final restSec =
                          parseRestTimeToSeconds(widget.set.restTime);
                      if (restSec <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: (widget.isRestTimerRunning || isLocked)
                              ? null
                              : widget.onStartTimer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (widget.isRestTimerRunning || isLocked)
                                  ? Colors.white10
                                  : AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (widget.isRestTimerRunning || isLocked)
                                    ? Colors.white24
                                    : AppTheme.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 11,
                                    color: (widget.isRestTimerRunning || isLocked)
                                        ? Colors.white54
                                        : AppTheme.primary),
                                const SizedBox(width: 3),
                                Text(
                                  '${restSec}s',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: (widget.isRestTimerRunning || isLocked)
                                        ? Colors.white54
                                        : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const Spacer(),
                Text('Objetivo: ',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7))),
                Text(
                  '${widget.set.targetReps} reps • ${formatWeightWithEquivalent(widget.set.targetWeight)}',
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
                        enabled: !checked && !isLocked,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: checked
                                ? Colors.green
                                : (isLocked ? Colors.white38 : Colors.white),
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
                        enabled: !checked && !isLocked,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: checked
                                ? Colors.green
                                : (isLocked ? Colors.white38 : Colors.white),
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
                      onTap: _isSaving
                          ? null
                          : () async {
                              if (isLocked) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Debes completar la serie anterior antes de continuar',
                                    ),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              if (!checked && widget.isRestTimerRunning) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Descanso en curso. Espera a que el cronómetro termine o ciérralo.',
                                    ),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              final reps =
                                  int.tryParse(_repsController.text) ??
                                      int.tryParse(widget.set.targetReps);
                              final weight =
                                  int.tryParse(_weightController.text) ??
                                      int.tryParse(widget.set.targetWeight);
                              setState(() => _isSaving = true);
                              try {
                                widget.onToggle(!checked, reps, weight);
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: checked
                              ? Colors.green
                              : (!checked &&
                                      (widget.isRestTimerRunning || isLocked))
                                  ? Colors.white10
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: checked
                                ? Colors.green
                                : (!checked &&
                                        (widget.isRestTimerRunning || isLocked))
                                    ? Colors.white24
                                    : Colors.grey,
                          ),
                        ),
                        child: checked
                            ? const Icon(Icons.check,
                                size: 20, color: Colors.white)
                            : isLocked
                                ? const Icon(Icons.lock_outline,
                                    size: 16, color: Colors.white38)
                                : (!checked && widget.isRestTimerRunning)
                                    ? const Icon(Icons.timer_outlined,
                                        size: 16, color: Colors.white38)
                                    : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
