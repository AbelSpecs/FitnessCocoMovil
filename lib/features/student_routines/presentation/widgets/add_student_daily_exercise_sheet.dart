import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/models/muscle_group_model.dart';
import 'package:pyrosfitmovil/core/services/routine_service.dart';
import 'package:pyrosfitmovil/core/utils/exercise_filter.dart';
import 'package:pyrosfitmovil/core/widgets/rest_time_input_field.dart';
import 'package:pyrosfitmovil/core/utils/weight_utils.dart';
import 'package:pyrosfitmovil/core/widgets/weight_input_field.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/quick_create_exercise_dialog.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class AddStudentDailyExerciseSheet extends StatefulWidget {
  final int studentId;
  final String scheduledDate;
  final List<GetDailyStudentExerciseDto> existingExercises;

  const AddStudentDailyExerciseSheet({
    super.key,
    required this.studentId,
    required this.scheduledDate,
    this.existingExercises = const [],
  });

  static Future<bool?> show(
    BuildContext context, {
    required int studentId,
    required String scheduledDate,
    List<GetDailyStudentExerciseDto> existingExercises = const [],
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
        existingExercises: existingExercises,
      ),
    );
  }

  @override
  State<AddStudentDailyExerciseSheet> createState() =>
      _AddStudentDailyExerciseSheetState();
}

class _AddStudentDailyExerciseSheetState
    extends State<AddStudentDailyExerciseSheet> {
  static Map<String, dynamic>? _studentDraft;
  bool _wasSavedSuccessfully = false;

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

  // Serie Combinada (Superserie)
  bool _isSuperSet = false;
  String _selectedSuperSetTag = 'A';
  String _combinedRestTime = '90';

  @override
  void initState() {
    super.initState();
    if (_studentDraft != null) {
      _notesController.text = _studentDraft!['notes'] as String? ?? '';
      _isSuperSet = _studentDraft!['isSuperSet'] as bool? ?? false;
      _selectedSuperSetTag = _studentDraft!['selectedSuperSetTag'] as String? ?? 'A';
      _combinedRestTime = _studentDraft!['combinedRestTime'] as String? ?? '90';
      final savedSets = _studentDraft!['sets'] as List?;
      if (savedSets != null && savedSets.isNotEmpty) {
        _sets.clear();
        _sets.addAll(List<Map<String, String>>.from(
            savedSets.map((s) => Map<String, String>.from(s))));
      }
      _selectedGroup = _studentDraft!['group'] as MuscleGroup?;
      _selectedExercise = _studentDraft!['exercise'] as ExerciseModel?;
    }
    _loadMuscleGroups();
  }

  bool get _hasDraftContent {
    return _selectedGroup != null ||
        _selectedExercise != null ||
        _notesController.text.trim().isNotEmpty ||
        _sets.length > 1 ||
        _sets.any((s) =>
            (s['targetReps'] != null && s['targetReps'] != '12' && s['targetReps']!.isNotEmpty) ||
            (s['targetWeight'] != null && s['targetWeight'] != '20' && s['targetWeight']!.isNotEmpty) ||
            (s['restTime'] != null && s['restTime'] != '90' && s['restTime']!.isNotEmpty));
  }

  void _resetForm() {
    setState(() {
      _studentDraft = null;
      _selectedExercise = null;
      _notesController.clear();
      _isSuperSet = false;
      _selectedSuperSetTag = 'A';
      _combinedRestTime = '90';
      _sets.clear();
      _sets.add({
        'targetReps': '12',
        'targetWeight': '20',
        'restTime': '90',
        '_key': 'init_${DateTime.now().microsecondsSinceEpoch}',
      });
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Borrador limpiado: Se han restablecido los campos del ejercicio'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    if (!_wasSavedSuccessfully) {
      if (_hasDraftContent) {
        _studentDraft = {
          'group': _selectedGroup,
          'exercise': _selectedExercise,
          'notes': _notesController.text,
          'isSuperSet': _isSuperSet,
          'selectedSuperSetTag': _selectedSuperSetTag,
          'combinedRestTime': _combinedRestTime,
          'sets': _sets.map((s) => Map<String, String>.from(s)).toList(),
        };
      } else {
        _studentDraft = null;
      }
    }
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
        final list = raw.map((e) => ExerciseModel.fromJson(e)).toList();
        final auth = context.read<AuthProvider>();
        final filtered = filterExercisesForUser(list, auth.user, widget.studentId);
        setState(() {
          _exercises = filtered;
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
      _sets.insert(0, {
        'targetReps': '12',
        'targetWeight': '20',
        'restTime': _isSuperSet ? _combinedRestTime : '90',
        '_key': 'set_${DateTime.now().microsecondsSinceEpoch}',
      });
    });
  }

  void _copySet(Map<String, String> set) {
    setState(() {
      _copiedSet = {
        'targetReps': set['targetReps'] ?? '12',
        'targetWeight': set['targetWeight'] ?? '20',
        'restTime': set['restTime'] ?? '90',
      };
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Serie copiada: ${set['targetReps']} reps • ${formatWeightWithEquivalent(set['targetWeight'])}',
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
        'restTime': _isSuperSet ? _combinedRestTime : (set['restTime'] ?? ''),
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
        'restTime': _isSuperSet ? _combinedRestTime : (_copiedSet!['restTime'] ?? '90'),
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

  void _toggleSuperSet(bool value, String restToApply) {
    setState(() {
      _isSuperSet = value;
      if (value) {
        for (var s in _sets) {
          s['restTime'] = restToApply;
        }
      }
    });
  }

  void _selectSuperSetTag(String tag, String restToApply) {
    setState(() {
      _selectedSuperSetTag = tag.trim().toUpperCase();
      for (var s in _sets) {
        s['restTime'] = restToApply;
      }
    });
  }

  void _updateCombinedRestTime(String newRest) {
    setState(() {
      _combinedRestTime = newRest;
      for (var s in _sets) {
        s['restTime'] = newRest;
      }
    });
  }

  Future<void> _handleSave({
    required String effectiveTag,
    required int effectiveOrder,
  }) async {
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
        'targetWeight': parseWeightNum(s['targetWeight']),
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
      'superSetTag': _isSuperSet ? effectiveTag : null,
      'superSetOrder': _isSuperSet ? effectiveOrder : null,
      'dailyExerciseSets': setsData,
    };

    try {
      final response = await RoutineService.postDailyStudentExercises(payload);
      if (response != null && mounted) {
        await context
            .read<StudentRoutinesProvider>()
            .fetchDailyExercises(widget.studentId, widget.scheduledDate);
        if (mounted) {
          _wasSavedSuccessfully = true;
          _studentDraft = null;
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

    // Superset data calculation based on existingExercises
    final Map<String, List<GetDailyStudentExerciseDto>> existingSuperSetsByTag = {};
    for (final r in widget.existingExercises) {
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
// effectiveRestTime

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
                    Icon(Icons.fitness_center_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AGREGAR EJERCICIO',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grupo Muscular
            const Text(
              'GRUPO MUSCULAR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            if (_isLoadingGroups)
              const LinearProgressIndicator(color: AppTheme.primary, minHeight: 2)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MuscleGroup>(
                    value: _selectedGroup,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E22),
                    items: _muscleGroups.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedGroup = val);
                        _loadExercisesForGroup(val.id);
                      }
                    },
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Ejercicio
            const Text(
              'EJERCICIO',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            if (_isLoadingExercises)
              const LinearProgressIndicator(color: AppTheme.primary, minHeight: 2)
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ExerciseModel>(
                    value: _selectedExercise,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E22),
                    hint: const Text('Selecciona un ejercicio', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    items: _exercises.map((ex) {
                      return DropdownMenuItem(
                        value: ex,
                        child: Text(ex.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedExercise = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final created = await showDialog<ExerciseModel>(
                      context: context,
                      builder: (_) => QuickCreateExerciseDialog(
                        initialMuscleGroupId: _selectedGroup?.id,
                      ),
                    );
                    if (created != null && mounted) {
                      if (_selectedGroup != null) {
                        await _loadExercisesForGroup(_selectedGroup!.id);
                      }
                      setState(() {
                        _selectedExercise = _exercises.firstWhere(
                          (e) => e.name.toLowerCase() == created.name.toLowerCase(),
                          orElse: () => created,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 14, color: AppTheme.primary),
                  label: const Text(
                    '¿No encuentras el ejercicio? Crear nuevo',
                    style: TextStyle(color: AppTheme.primary, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Serie Combinada (Superserie / Biserie)
            Container(
              decoration: BoxDecoration(
                color: _isSuperSet
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                    : const Color(0xFF1A1A1D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isSuperSet
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                      : AppTheme.border.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¿Es una Serie Combinada (Superserie)?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ejecuta este ejercicio junto a otros en la misma ronda sin descanso intermedio.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSuperSet,
                        activeThumbColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          final targetTag = _selectedSuperSetTag.isNotEmpty
                              ? _selectedSuperSetTag
                              : (existingTags.isNotEmpty ? existingTags.first : 'A');
                          final tagExs = existingSuperSetsByTag[targetTag] ?? [];
                          final restToApply = tagExs.isNotEmpty &&
                                  tagExs.first.dailyExerciseSets.isNotEmpty
                              ? tagExs.first.dailyExerciseSets.first.restTime
                              : _combinedRestTime;
                          _toggleSuperSet(val, restToApply);
                        },
                      ),
                    ],
                  ),
                  if (_isSuperSet) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),

                    // Selección de Serie / Grupo
                    const Text(
                      'SELECCIONA EL BLOQUE COMBINADO',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...existingTags.map((tag) {
                          final count = (existingSuperSetsByTag[tag] ?? []).length;
                          final isSelected = effectiveTag == tag;
                          return ChoiceChip(
                            selected: isSelected,
                            selectedColor: const Color(0xFFF59E0B),
                            backgroundColor: Colors.white10,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            avatar: Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: isSelected ? Colors.black : const Color(0xFFF59E0B),
                            ),
                            label: Text('Serie #$tag ($count ejerc.)'),
                            onSelected: (_) {
                              final tagExs = existingSuperSetsByTag[tag] ?? [];
                              final rest = tagExs.isNotEmpty &&
                                      tagExs.first.dailyExerciseSets.isNotEmpty
                                  ? tagExs.first.dailyExerciseSets.first.restTime
                                  : _combinedRestTime;
                              _selectSuperSetTag(tag, rest);
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: Color(0xFFF59E0B)),
                          label: Text('+ Nueva Serie (#$nextAvailableTag)'),
                          backgroundColor: effectiveTag == nextAvailableTag
                              ? const Color(0xFFF59E0B)
                              : Colors.transparent,
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          labelStyle: TextStyle(
                            color: effectiveTag == nextAvailableTag
                                ? Colors.black
                                : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onPressed: () {
                            _selectSuperSetTag(nextAvailableTag, _combinedRestTime);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Detalle del bloque seleccionado
                    if (hasExistingInSelectedTag) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$effectiveTag • Ejercicio #$effectiveOrder',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vinculado a Serie #$effectiveTag existente',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Descanso sincronizado con el 1er ejercicio (${firstExerciseInSelectedTag?.exerciseName ?? "Ejercicio #1"}): ${establishedRestInSelectedTag}s',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.65)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$effectiveTag • Ejercicio #1',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Descanso Único para Serie #$effectiveTag',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            RestTimeInputField(
                              initialValue: _combinedRestTime,
                              onChanged: (val) {
                                _updateCombinedRestTime(
                                    val.trim().isNotEmpty ? val.trim() : '90');
                              },
                              label: 'Descanso único de la ronda combinada',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

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
                    'Pegar serie (${_copiedSet!['targetReps']} reps • ${formatWeightWithEquivalent(_copiedSet!['targetWeight'])})',
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
                          'Serie #${_sets.length - idx}',
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
                          flex: 2,
                          child: WeightInputField(
                            key: ValueKey('weight_${set['_key'] ?? idx}'),
                            initialValue: set['targetWeight'] ?? '',
                            onChanged: (v) => set['targetWeight'] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: RestTimeInputField(
                            key: ValueKey('rest_${set['_key'] ?? idx}'),
                            initialValue: set['restTime'] ?? '90',
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

            if (_hasDraftContent) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.white70),
                  label: const Text(
                    'Limpiar campos',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _handleSave(
                          effectiveTag: effectiveTag,
                          effectiveOrder: effectiveOrder,
                        ),
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
                  _isSaving ? 'Guardando ejercicio...' : 'Agregar Ejercicio a Rutina',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
