import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:pyrosfitmovil/features/student_routines/presentation/providers/student_routines_provider.dart';

class StudentWeeklyRoutineScreen extends StatefulWidget {
  final int studentId;
  const StudentWeeklyRoutineScreen({super.key, required this.studentId});

  @override
  State<StudentWeeklyRoutineScreen> createState() => _StudentWeeklyRoutineScreenState();
}

class _StudentWeeklyRoutineScreenState extends State<StudentWeeklyRoutineScreen> {
  late PageController _pageController;
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Empezamos en la página 500 (centro) para simular scroll infinito
    _pageController = PageController(initialPage: 500);
    _currentWeekStart = _getStartOfWeek(DateTime.now());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeek(_currentWeekStart);
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    // 0 = Sunday en web, pero en Dart DateTime.monday es 1 y sunday es 7.
    // Ajustaremos para que la semana empiece en Domingo.
    int daysToSubtract = date.weekday == DateTime.sunday ? 0 : date.weekday;
    return date.subtract(Duration(days: daysToSubtract));
  }

  void _loadWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final provider = context.read<StudentRoutinesProvider>();
    
    provider.fetchWeeklyExercises(
      widget.studentId,
      DateFormat('yyyy-MM-dd').format(startOfWeek),
      DateFormat('yyyy-MM-dd').format(endOfWeek),
    );
  }

  void _onPageChanged(int page) {
    // 500 es el punto de partida (semana actual)
    final diff = page - 500;
    final newStart = _getStartOfWeek(DateTime.now()).add(Duration(days: diff * 7));
    setState(() {
      _currentWeekStart = newStart;
    });
    _loadWeek(newStart);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentRoutinesProvider>();
    final theme = Theme.of(context);
    final isTodayWeek = _getStartOfWeek(DateTime.now()).isAtSameMomentAs(_currentWeekStart);

    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Es el root del tab
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            Text(
              isTodayWeek
                  ? 'Esta Semana'
                  : 'Semana del ${DateFormat('d MMM', 'es_US').format(_currentWeekStart)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TU PROGRAMA',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3.0,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rutina semanal',
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 40,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pulsa cualquier día para ver los ejercicios, registrar tu sesión y consultar el historial.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // PageView Slider
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return _buildWeekGrid(provider, theme);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWeekGrid(StudentRoutinesProvider provider, ThemeData theme) {
    // Construir la lista de 7 días
    final days = List.generate(7, (index) {
      final date = _currentWeekStart.add(Duration(days: index));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateString;
      
      final dayExercises = provider.weeklyExercises.where((ex) => ex.scheduledDate.startsWith(dateString)).toList();
      final isRest = dayExercises.isEmpty;
      final muscleGroup = isRest ? 'Descanso' : dayExercises.first.muscleGroupName;
      final dayShort = DateFormat('E', 'es_US').format(date).substring(0, 1).toUpperCase();
      final dayName = DateFormat('EEEE', 'es_US').format(date);

      return _buildDayCard(
        date: date,
        dateString: dateString,
        isToday: isToday,
        isRest: isRest,
        muscleGroup: muscleGroup,
        dayShort: dayShort,
        dayName: dayName,
        exerciseCount: dayExercises.length,
        theme: theme,
      );
    });

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: days,
    );
  }

  Widget _buildDayCard({
    required DateTime date,
    required String dateString,
    required bool isToday,
    required bool isRest,
    required String muscleGroup,
    required String dayShort,
    required String dayName,
    required int exerciseCount,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () {
        context.go('/rutina/${widget.studentId}/$dateString');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday ? null : AppTheme.card.withValues(alpha: 0.15),
          gradient: isToday
              ? const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday ? AppTheme.primary : AppTheme.border.withValues(alpha: 0.2),
          ),
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'HOY' : dayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: isToday ? Colors.white70 : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayShort,
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 40,
                        color: isToday ? Colors.white : Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  color: isToday ? Colors.white54 : Colors.white24,
                ),
              ],
            ),
            const Spacer(),
            Text(
              muscleGroup,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 24,
                color: isToday ? Colors.white : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (isRest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white24 : AppTheme.border,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Descanso',
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? Colors.white : Colors.white70,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 12,
                    color: isToday ? Colors.white70 : Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$exerciseCount ej.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.white70 : Colors.white54,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
