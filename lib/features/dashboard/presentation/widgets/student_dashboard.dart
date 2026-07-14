import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/features/dashboard/data/services/dashboard_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<GetDailyStudentExerciseDto> _dailyExercises = [];
  List<GetDailyStudentExerciseDto> _weeklyExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_US', null).then((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final studentId = auth.user?.studentId;
    if (studentId != null) {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final dayOfWeek = now.weekday == 7 ? 0 : now.weekday;
      final startOfWeek = now.subtract(Duration(days: dayOfWeek));
      final dateStringStart = DateFormat('yyyy-MM-dd').format(startOfWeek);
      final sixDaysLater = now.add(const Duration(days: 6));
      final sixDaysLaterStr = DateFormat('yyyy-MM-dd').format(sixDaysLater);

      final daily =
          await DashboardService.getDailyStudentExercisesByStudentIdAndDate(
              studentId, todayStr);
      final weekly =
          await DashboardService.getDailyStudentExercisesByStudentIdAndDates(
              studentId, dateStringStart, sixDaysLaterStr);

      if (mounted) {
        setState(() {
          _dailyExercises = daily;
          _weeklyExercises = weekly;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _weeklyStreak {
    if (_weeklyExercises.isEmpty) return 0;
    // Lógica simplificada: contar días únicos donde hay ejercicios completados
    final completedDays = _weeklyExercises
        .where((ex) => ex.isCompleted)
        .map((ex) => ex.scheduledDate.split('T')[0])
        .toSet();
    return completedDays.length;
  }

  int get _maxWeightLifted {
    if (_weeklyExercises.isEmpty) return 0;
    double maxWeight = 0;
    for (var ex in _weeklyExercises) {
      if (ex.isCompleted) {
        for (var set in ex.dailyExerciseSets) {
          if (set.isAchieved) {
            final double weight = (set.actualWeight ?? 0.0).toDouble();
            if (weight > maxWeight) {
              maxWeight = weight;
            }
          }
        }
      }
    }
    return maxWeight.toInt();
  }

  String get _dailyFocus {
    if (_dailyExercises.isEmpty) return 'Descanso';
    final groups = _dailyExercises
        .map((e) => e.muscleGroupName)
        .where((name) => name.isNotEmpty)
        .toSet();
    return groups.isNotEmpty ? groups.join(', ') : 'Descanso';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.firstName?.split(' ')[0] ?? '';
    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE d MMMM', 'es_US').format(now);

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primary))
        : context.pyrosStyles.buildMeshBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Color(0xFF151518)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormatted.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hola, $firstName.',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const Text(
                          'Es hora de entrenar.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hoy te toca $_dailyFocus · ${_dailyExercises.length} ejercicios.',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        if (_dailyExercises.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.go(
                                    '/rutina/${auth.user?.studentId}/${DateFormat('yyyy-MM-dd').format(now)}');
                              },
                              icon: const Icon(Icons.flash_on, size: 18),
                              label: const Text('Iniciar entrenamiento'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.local_fire_department,
                                label: 'RACHA',
                                value: '$_weeklyStreak',
                                hint: 'días completados',
                                isAccent: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.fitness_center,
                                label: 'MÁXIMO L...',
                                value: '$_maxWeightLifted kg',
                                hint: 'peso maximo levantado',
                                isAccent: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sesión de hoy
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SESIÓN DE HOY',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Entrenamiento',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                context.go(
                                    '/rutina/${auth.user?.studentId}/${DateFormat('yyyy-MM-dd').format(now)}');
                              },
                              child: const Text('Abrir >',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_dailyExercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Column(
                                children: [
                                  Text('🌿', style: TextStyle(fontSize: 48)),
                                  SizedBox(height: 8),
                                  Text('Día de descanso',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  Text('Hoy no tienes ejercicios asignados.',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._dailyExercises.take(4).map((ex) =>
                              _buildExerciseRow(
                                  ex, _dailyExercises.indexOf(ex) + 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Esta semana
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTA SEMANA',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Plan',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                            7,
                            (index) => _buildWeeklyPlanRow(
                                now.add(Duration(days: index)), index == 0)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
  }

  Widget _buildExerciseRow(GetDailyStudentExerciseDto ex, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFFC2410C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('$index',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${ex.muscleGroupName} · ${ex.dailyExerciseSets.length} series',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.fitness_center, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlanRow(DateTime date, bool isToday) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final dayName = DateFormat('EEEE', 'es_US').format(date);
    final dayShort = DateFormat('E', 'es_US').format(date);

    final dayExercises = _weeklyExercises
        .where((ex) => ex.scheduledDate.split('T')[0] == dateString)
        .toList();
    final isRest = dayExercises.isEmpty;
    final focus = dayExercises.isNotEmpty
        ? dayExercises.first.muscleGroupName
        : 'Descanso';

    return InkWell(
      onTap: () {
        final auth = context.read<AuthProvider>();
        context.go('/rutina/${auth.user?.studentId}/$dateString');
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.primary
                    : (isRest
                        ? const Color(0xFF27272A)
                        : const Color(0xFF3F3F46)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                dayShort.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? Colors.white
                      : (isRest ? Colors.grey : Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName[0].toUpperCase() + dayName.substring(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    focus,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool isAccent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccent
            ? AppTheme.primary.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isAccent
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14, color: isAccent ? AppTheme.primary : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isAccent ? AppTheme.primary : Colors.grey,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            hint,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
