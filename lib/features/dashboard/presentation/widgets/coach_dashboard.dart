import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/dashboard/data/models/dashboard_models.dart';
import 'package:pyrosfitmovil/features/dashboard/data/services/dashboard_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  List<CoachStudentsDto> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_US', null).then((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final coachId = auth.user?.coachId;
    if (coachId != null) {
      final students = await DashboardService.getCoachStudents(coachId);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.firstName?.split(' ')[0] ?? '';
    final now = DateTime.now();
    final dateFormatted =
        DateFormat('EEEE, d \'de\' MMMM', 'es_US').format(now);

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
                    gradient: context.pyrosStyles.gradientHero,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormatted.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryGlow,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hola, $firstName.',
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 36,
                          color: AppTheme.foreground,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            context.pyrosStyles.gradientPrimary.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: const Text(
                          'Tienes clientes\nque atender.',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 36,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.group,
                              label: 'NÚMERO DE CLIENTES',
                              value: _students.length.toString(),
                              hint: 'clientes inscritos',
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: _StatTile(
                              icon: Icons.emoji_events,
                              label: '% DE CLIENTES',
                              value: '100 %',
                              hint: 'de la totalidad',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Clients List
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
                                'REVISIÓN DE CLIENTES',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tus Clientes',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.go('/clientes'),
                            child: const Text(
                              'Ver todos >',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_students.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No tienes estudiantes asignados.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._students
                            .take(5)
                            .map((student) => _buildStudentRow(student)),
                    ],
                  ),
                ),
              ],
            ),
          ));
  }

  Widget _buildStudentRow(CoachStudentsDto student) {
    final initial =
        student.name.isNotEmpty ? student.name[0].toUpperCase() : 'U';

    return InkWell(
      onTap: () => context.go('/clientes/${student.studentId}'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF27272A),
              foregroundColor: Colors.white,
              child: Text(initial,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Ver rutina',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
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

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
