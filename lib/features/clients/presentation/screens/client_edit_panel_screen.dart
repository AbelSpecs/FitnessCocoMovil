import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/core/services/streak_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ClientEditPanelScreen extends StatefulWidget {
  final StudentInfo client;

  const ClientEditPanelScreen({super.key, required this.client});

  @override
  State<ClientEditPanelScreen> createState() => _ClientEditPanelScreenState();
}

class _ClientEditPanelScreenState extends State<ClientEditPanelScreen> {
  bool _isLoading = true;
  bool _saving = false;

  late TextEditingController _currentStreakController;
  late TextEditingController _longestStreakController;
  late TextEditingController _shieldsController;
  late TextEditingController _reasonController;

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _shields = 0;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _currentStreakController = TextEditingController(text: '0');
    _longestStreakController = TextEditingController(text: '0');
    _shieldsController = TextEditingController(text: '0');
    _reasonController = TextEditingController();

    _loadStudentStreak();
  }

  Future<void> _loadStudentStreak() async {
    try {
      final streakData = await StreakService.getStudentStreak(widget.client.studentId);
      if (mounted) {
        setState(() {
          _currentStreak = streakData?.currentStreak ?? 0;
          _longestStreak = streakData?.longestStreak ?? _currentStreak;
          _shields = streakData?.freezeShieldsAvailable ?? 0;

          _currentStreakController.text = _currentStreak.toString();
          _longestStreakController.text = _longestStreak.toString();
          _shieldsController.text = _shields.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentStreakController.dispose();
    _longestStreakController.dispose();
    _shieldsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final reasonTrimmed = _reason.trim();
    if (reasonTrimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes ingresar el motivo o justificación del ajuste.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final adjustDto = AdjustStreakDto(
        currentStreak: _currentStreak,
        longestStreak: _longestStreak,
        freezeShields: _shields,
        reason: reasonTrimmed,
      );

      await StreakService.adjustStudentStreak(widget.client.studentId, adjustDto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se guardaron los cambios de ${widget.client.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo guardar el ajuste de racha. Intenta nuevamente.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.client.name.isNotEmpty ? widget.client.name[0].toUpperCase() : '?';
    final goalText = widget.client.fitnessGoal.isNotEmpty
        ? widget.client.fitnessGoal
        : 'Entrenamiento personalizado';

    final bool canSave = !_saving && _reason.trim().isNotEmpty;

    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Volver a rutinas',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con Avatar y Rol
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.fireGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PANEL DE EDICIÓN',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    color: AppTheme.primaryGlow,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.client.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'BebasNeue',
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF27272A),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.border),
                                      ),
                                      child: const Text(
                                        'PLAN ACTIVO',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        goalText,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.manage_accounts_rounded,
                                  color: AppTheme.primaryGlow,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Métricas del alumno',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Ajusta rachas y escudos para gamificación.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3 Inputs en fila
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricInput(
                                  controller: _currentStreakController,
                                  label: 'RACHA ACTUAL',
                                  hint: 'Días activos',
                                  icon: Icons.local_fire_department,
                                  onChanged: (val) {
                                    setState(() {
                                      _currentStreak = int.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricInput(
                                  controller: _longestStreakController,
                                  label: 'RACHA MÁXIMA',
                                  hint: 'Récord hist.',
                                  icon: Icons.emoji_events_rounded,
                                  onChanged: (val) {
                                    setState(() {
                                      _longestStreak = int.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricInput(
                                  controller: _shieldsController,
                                  label: 'ESCUDOS',
                                  hint: 'Disponibles',
                                  icon: Icons.shield_rounded,
                                  onChanged: (val) {
                                    setState(() {
                                      _shields = int.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // TextArea: Razón de ajuste
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: Colors.grey,
                                fontFamily: 'Barlow',
                              ),
                              children: [
                                TextSpan(text: 'RAZÓN DE AJUSTE '),
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reasonController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (val) => setState(() => _reason = val),
                            decoration: InputDecoration(
                              hintText: 'Escribe el motivo o justificación del ajuste...',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
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
                          const SizedBox(height: 6),
                          const Text(
                            'Obligatorio. Quedará registrado en la auditoría de cambios del alumno.',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          const SizedBox(height: 24),

                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: canSave ? _handleSave : null,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_rounded, size: 16),
                                  label: Text(
                                    _saving ? 'Guardando...' : 'Guardar cambios',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(0xFF27272A),
                                    disabledForegroundColor: Colors.grey,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: canSave ? 4 : 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Preview Card ("Vista previa")
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_fire_department, color: AppTheme.primaryGlow, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'VISTA PREVIA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPreviewTile(
                                  value: _currentStreak.toString(),
                                  label: 'RACHA ACTUAL',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPreviewTile(
                                  value: _longestStreak.toString(),
                                  label: 'RACHA MÁXIMA',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPreviewTile(
                                  value: _shields.toString(),
                                  label: 'ESCUDOS',
                                ),
                              ),
                            ],
                          ),
                          if (_reason.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RAZÓN REGISTRADA',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _reason.trim(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.primaryGlow),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'BebasNeue',
              color: Colors.white,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 8.5, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTile({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'BebasNeue',
              color: AppTheme.primaryGlow,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
