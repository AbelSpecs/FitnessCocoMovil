import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/core/services/streak_service.dart';
import 'package:pyrosfitmovil/core/utils/streak_helpers.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/features/dashboard/data/services/dashboard_service.dart';
import 'package:pyrosfitmovil/features/dashboard/presentation/widgets/streak_card.dart';
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

  int _streak = 0;
  int _shields = 0;
  bool _completed = false;
  List<HistoryItem> _history = [];
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

      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final yesterday = now.subtract(const Duration(days: 1));
      final threeDaysAgoStr = DateFormat('yyyy-MM-dd').format(threeDaysAgo);
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

      try {
        final results = await Future.wait([
          DashboardService.getDailyStudentExercisesByStudentIdAndDate(studentId, todayStr),
          DashboardService.getDailyStudentExercisesByStudentIdAndDates(studentId, dateStringStart, sixDaysLaterStr),
          DashboardService.getDailyStudentExercisesByStudentIdAndDates(studentId, threeDaysAgoStr, yesterdayStr),
          StreakService.getStudentStreak(studentId),
          StreakService.getStudentStreakHistory(studentId, limit: 30),
        ]);

        final daily = results[0] as List<GetDailyStudentExerciseDto>;
        final weekly = results[1] as List<GetDailyStudentExerciseDto>;
        final historyEx = results[2] as List<GetDailyStudentExerciseDto>;
        final streakData = results[3] as StudentStreakDto?;
        final streakLogs = results[4] as List<StreakHistoryLogDto>;

        if (mounted) {
          final newStreak = streakData?.currentStreak ?? 0;
          final wasZero = _streak == 0;
          final shouldCelebrate = !wasZero && newStreak > _streak;

          setState(() {
            _dailyExercises = daily;
            _weeklyExercises = weekly;

            _streak = newStreak;
            _shields = streakData?.freezeShieldsAvailable ?? 0;
            _completed = streakData?.isCompletedToday ?? false;

            _history = combinedHistoryMapper(streakLogs, historyEx);
            _isLoading = false;
          });

          if (shouldCelebrate) {
            _showCelebrationDialog(newStreak, auth.user?.firstName ?? '');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCelebrationDialog(int streakVal, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => StreakCelebrationDialog(
        streak: streakVal,
        studentName: studentName,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showFreezeShieldDialog(int? studentId) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => FreezeShieldDialog(
        shields: _shields,
        streak: _streak,
        onDismiss: () => Navigator.of(ctx).pop(),
        onConfirmUse: () async {
          if (studentId == null || _shields <= 0) return;
          try {
            await StreakService.useFreezeShield(studentId);
            if (mounted) {
              setState(() {
                if (_shields > 0) _shields--;
              });
              messenger.showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.shield, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '¡Escudo de Hielo activado! Tu racha está protegida ante inactividad 🛡️❄️',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E242B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('No se pudo usar el escudo de hielo. Intenta nuevamente.'),
                  backgroundColor: Colors.red.shade900,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }
        },
      ),
    );
  }

  int get _maxWeightLifted {
    if (_weeklyExercises.isEmpty) return 0;
    double maxWeight = 0;
    for (final ex in _weeklyExercises) {
      if (ex.isCompleted) {
        for (final set in ex.dailyExerciseSets) {
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
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentTier = tierFor(_streak);

    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : context.pyrosStyles.buildMeshBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Student Avatar & Greeting
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primary, Color(0xFFFF9500)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Hola,',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '$firstName!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta Principal de Racha (T-01, T-04)
                  PyrosStreakCard(
                    streak: _streak,
                    shields: _shields,
                    dailyFocus: _dailyFocus,
                    dailyExercisesNum: _dailyExercises.length,
                    prRecord: _maxWeightLifted > 0 ? _maxWeightLifted : 100,
                    onUseShield: () => _showFreezeShieldDialog(auth.user?.studentId),
                  ),
                  const SizedBox(height: 16),

                  // Botón CTA Principal: Completar Rutina de Hoy
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _completed
                          ? null
                          : () {
                              context.go('/rutina/${auth.user?.studentId}/$todayStr');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _completed
                            ? const Color(0xFF27272A)
                            : AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF27272A),
                        disabledForegroundColor: Colors.grey,
                        elevation: _completed ? 0 : 6,
                        shadowColor: currentTier.ringColor.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _completed
                                ? AppTheme.border
                                : currentTier.ringColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        _completed
                            ? 'Rutina completada ✅'
                            : 'Completar Rutina de Hoy 💪',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección: Actividad Reciente (T-02)
                  const Text(
                    'ACTIVIDAD RECIENTE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      ),
                      child: const Center(
                        child: Text(
                          'No existen actividades recientes',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._history.take(4).map((item) => _buildRecentActivityItem(item)),

                  const SizedBox(height: 24),

                  // Sección: Esta Semana (Plan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.card.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTA SEMANA',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Plan',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          7,
                          (index) => _buildWeeklyPlanRow(
                            now.add(Duration(days: index)),
                            index == 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
  }

  Widget _buildRecentActivityItem(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item.date,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${item.min}′',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
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
                borderRadius: BorderRadius.circular(10),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                dayShort.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isToday
                      ? Colors.white
                      : (isRest ? Colors.grey : Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName[0].toUpperCase() + dayName.substring(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    focus,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
