import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/student_clinical_data_model.dart';
import 'package:pyrosfitmovil/core/services/student_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class StudentClinicalOverviewCard extends StatefulWidget {
  final int studentId;
  final bool initiallyExpanded;

  const StudentClinicalOverviewCard({
    super.key,
    required this.studentId,
    this.initiallyExpanded = false,
  });

  @override
  State<StudentClinicalOverviewCard> createState() => _StudentClinicalOverviewCardState();
}

class _StudentClinicalOverviewCardState extends State<StudentClinicalOverviewCard> {
  StudentClinicalData? _data;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _loadClinicalData();
  }

  Future<void> _loadClinicalData() async {
    try {
      final res = await StudentService.getStudentClinicalData(widget.studentId);
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
            SizedBox(width: 14),
            Text(
              'Cargando ficha clínica y antropométrica…',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final hasAlert = data.hasHealthAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasAlert
              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
              : AppTheme.border.withValues(alpha: 0.8),
          width: hasAlert ? 1.5 : 1.0,
        ),
        boxShadow: hasAlert
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Trigger
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasAlert
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasAlert
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      hasAlert ? Icons.health_and_safety_rounded : Icons.medical_information_rounded,
                      color: hasAlert ? const Color(0xFFFBBF24) : AppTheme.primaryGlow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'FICHA CLÍNICA & ANTROPOMETRÍA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                            if (hasAlert)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'ALERTA DE SALUD',
                                      style: TextStyle(
                                        color: Color(0xFFF87171),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Quick Stats Row
                        Text(
                          '${data.formattedWeight} · ${data.formattedHeight} · IMC ${data.bmi?.toStringAsFixed(1) ?? "--"} (${data.bmiCategory})',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFF27272A)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Biometrics Grid (4 Cards)
                  const Text(
                    'MÉTRICAS ANTROPOMÉTRICAS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricTile(
                        icon: Icons.scale_rounded,
                        label: 'PESO',
                        value: data.formattedWeight,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        icon: Icons.height_rounded,
                        label: 'ALTURA',
                        value: data.formattedHeight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricTile(
                        icon: Icons.pie_chart_outline_rounded,
                        label: '% GRASA',
                        value: data.formattedBodyFat,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: data.bmiColor.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.monitor_heart_rounded, color: data.bmiColor, size: 16),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'IMC (OMS)',
                                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    data.bmi != null ? data.bmi!.toStringAsFixed(1) : '--',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: data.bmiColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      data.bmiCategory,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: data.bmiColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Sports Profile
                  const Text(
                    'PERFIL DEPORTIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        _buildProfileRow('Objetivo Principal:', data.formattedGoal, Icons.flag_rounded),
                        const Divider(height: 14, color: Color(0xFF27272A)),
                        _buildProfileRow('Nivel de Actividad:', data.formattedActivityLevel, Icons.directions_run_rounded),
                        const Divider(height: 14, color: Color(0xFF27272A)),
                        _buildProfileRow('Experiencia Fitness:', data.formattedExperience, Icons.fitness_center_rounded),
                      ],
                    ),
                  ),

                  // 3. Clinical Alerts & Medical Warnings
                  if (hasAlert || data.hasGeneralNotes) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'CONDICIONES MÉDICAS & SEGURIDAD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Medical conditions badge
                    if (data.hasMedicalConditions)
                      _buildAlertTile(
                        title: 'Condición Médica Diagnosticada:',
                        content: data.medicalConditions!,
                        icon: Icons.health_and_safety_rounded,
                        accentColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFF450A0A),
                      ),

                    // Allergies badge
                    if (data.hasAllergies) ...[
                      const SizedBox(height: 8),
                      _buildAlertTile(
                        title: 'Alergias Registradas:',
                        content: data.allergies!,
                        icon: Icons.warning_amber_rounded,
                        accentColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFF451A03),
                      ),
                    ],

                    // General notes
                    if (data.hasGeneralNotes) ...[
                      const SizedBox(height: 8),
                      _buildAlertTile(
                        title: 'Notas Generales del Alumno:',
                        content: data.generalNotes!,
                        icon: Icons.notes_rounded,
                        accentColor: AppTheme.primary,
                        bgColor: const Color(0xFF18181B),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertTile({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
