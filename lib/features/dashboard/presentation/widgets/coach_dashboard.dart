import 'package:pyrosfitmovil/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/core/services/streak_service.dart';
import 'package:pyrosfitmovil/core/utils/streak_helpers.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/features/dashboard/data/services/dashboard_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  List<CoachStudentsDto> _coachStudents = [];
  List<RiskStudentInfo> _radarStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all' | 'high' | 'medium' | 'low'

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_US', null).then((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final coachId = auth.user?.coachId;
    if (coachId != null) {
      try {
        final results = await Future.wait([
          DashboardService.getCoachStudents(coachId),
          StreakService.getCoachRiskRadar(coachId),
        ]);

        final studentsList = results[0] as List<CoachStudentsDto>;
        final riskRadarList = results[1] as List<RiskRadarStudentDto>;

        if (mounted) {
          setState(() {
            _coachStudents = studentsList;
            _radarStudents = riskRadarStudentsMapper(riskRadarList);
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _radarStudents = defaultStudentsMock;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _radarStudents = defaultStudentsMock;
          _isLoading = false;
        });
      }
    }
  }

  String get _kpiTotalStudents {
    if (_coachStudents.isNotEmpty) {
      return _coachStudents.length.toString();
    }
    return _radarStudents.length.toString();
  }

  String get _kpiAverageStreak {
    if (_radarStudents.isEmpty) return '0.0';
    final totalStreak = _radarStudents.fold<int>(0, (acc, curr) => acc + curr.streak);
    return (totalStreak / _radarStudents.length).toStringAsFixed(1);
  }

  String get _kpiHighRiskCount {
    return _radarStudents.where((s) => s.risk == 'high').length.toString();
  }

  List<RiskStudentInfo> get _filteredStudents {
    return _radarStudents.where((s) {
      final matchesFilter = _selectedFilter == 'all' || s.risk == _selectedFilter;
      final matchesQuery = s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  void _openMotivationalDialog(RiskStudentInfo student) {
    showDialog(
      context: context,
      builder: (ctx) => _MotivationalMessageDialog(
        student: student,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, d \'de\' MMMM', 'es_US').format(now);
    final highRiskCountNum = int.tryParse(_kpiHighRiskCount) ?? 0;

    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : context.pyrosStyles.buildMeshBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Coach Panel Title (T-06)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'COACH PANEL',
                            style: TextStyle(
                              color: AppTheme.primaryGlow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          Text(
                            dateFormatted.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Churn Risk Radar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'BebasNeue',
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Text(
                        'Detectá alumnos en riesgo de abandono antes de perderlos.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // KPIs (T-06)
                  Row(
                    children: [
                      Expanded(
                        child: _CoachKpiCard(
                          icon: Icons.people_outline,
                          label: 'ALUMNOS',
                          value: _kpiTotalStudents,
                          hint: 'en seguimiento',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CoachKpiCard(
                          icon: Icons.trending_up,
                          label: 'RACHA PROM.',
                          value: _kpiAverageStreak,
                          hint: 'días por alumno',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CoachKpiCard(
                          icon: Icons.warning_amber_rounded,
                          label: 'RIESGO ALTO',
                          value: _kpiHighRiskCount,
                          hint: 'requieren contacto',
                          isDanger: highRiskCountNum > 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Main Radar Container (T-06)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar alumno...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.35),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('all', 'Todos'),
                              const SizedBox(width: 8),
                              _buildFilterChip('high', '🔴 Alto Riesgo'),
                              const SizedBox(width: 8),
                              _buildFilterChip('medium', '🟡 Medio Riesgo'),
                              const SizedBox(width: 8),
                              _buildFilterChip('low', '🟢 Normal'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Students List
                        if (_filteredStudents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36.0),
                            child: Center(
                              child: Text(
                                'Sin resultados para esta búsqueda.',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredStudents.length,
                            separatorBuilder: (context, index) => Divider(
                              color: AppTheme.border.withValues(alpha: 0.4),
                              height: 24,
                            ),
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return _buildStudentCard(student);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border.withValues(alpha: 0.6),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(RiskStudentInfo student) {
    Color riskColor;
    Color riskBg;
    String riskLabel;

    switch (student.risk) {
      case 'high':
        riskColor = const Color(0xFFEF4444);
        riskBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        riskLabel = '🔴 Riesgo Alto';
        break;
      case 'medium':
        riskColor = const Color(0xFFF59E0B);
        riskBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        riskLabel = '🟡 Riesgo Medio';
        break;
      default:
        riskColor = const Color(0xFF10B981);
        riskBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        riskLabel = '🟢 Normal';
        break;
    }

    final double inactivityPercent = (student.inactivity / 8.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Avatar + Name + Risk Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(
              size: 42,
              borderRadius: 12,
              shape: BoxShape.rectangle,
              initial: student.initials,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${student.streak} días racha',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGlow,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Text(
                        student.lastWorkout,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: riskBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                riskLabel,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Inactivity bar & Contact button
        Row(
          children: [
            // Inactivity progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inactividad',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      Text(
                        '${student.inactivity}d',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      color: const Color(0xFF27272A),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: inactivityPercent > 0 ? inactivityPercent : 0.05,
                        child: Container(color: riskColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Contact Action Button
            ElevatedButton.icon(
              onPressed: () => _openMotivationalDialog(student),
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Contactar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: student.risk == 'high'
                    ? AppTheme.primary
                    : const Color(0xFF27272A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: student.risk == 'high'
                        ? AppTheme.primaryGlow
                        : AppTheme.border,
                    width: 1,
                  ),
                ),
                elevation: student.risk == 'high' ? 4 : 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta KPI de Estadísticas del Coach (T-06)
class _CoachKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool isDanger;

  const _CoachKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final dangerBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
    final dangerBorder = const Color(0xFFEF4444).withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDanger ? dangerBg : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDanger ? dangerBorder : AppTheme.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isDanger ? const Color(0xFFEF4444) : AppTheme.primaryGlow,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: isDanger ? const Color(0xFFEF4444) : Colors.grey,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'BebasNeue',
              color: isDanger ? const Color(0xFFEF4444) : Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Diálogo de Mensaje de Motivación para WhatsApp / Notificación (T-06)
class _MotivationalMessageDialog extends StatefulWidget {
  final RiskStudentInfo student;
  final VoidCallback onDismiss;

  const _MotivationalMessageDialog({
    required this.student,
    required this.onDismiss,
  });

  @override
  State<_MotivationalMessageDialog> createState() => _MotivationalMessageDialogState();
}

class _MotivationalMessageDialogState extends State<_MotivationalMessageDialog> {
  late TextEditingController _textController;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final firstName = widget.student.name.split(' ')[0];
    final days = widget.student.inactivity;
    _textController = TextEditingController(
      text: '¡Hola $firstName! Notamos que hace $days días que no entrenás. ¿Coordinamos tu próxima sesión? 💪🔥',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221F1B), Color(0xFF171719)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: _sent
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 30,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Mensaje enviado!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Le llegará por WhatsApp y notificación en la app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Entendido'),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mensaje de motivación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enviar a ${widget.student.name} · ${widget.student.lastWorkout.toLowerCase()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onDismiss,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _sent = true),
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text(
                            'Enviar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
