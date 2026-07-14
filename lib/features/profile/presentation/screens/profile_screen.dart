import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/profile/presentation/controllers/profile_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.select((AuthProvider p) => p.user);
    if (authUser == null) {
      return const Scaffold(
        body: Center(child: Text("No autorizado")),
      );
    }

    final isCoach = authUser.role?.name == 'coach';

    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..fetchProfile(authUser.id, isCoach),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'PERFIL',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 24,
              letterSpacing: 2,
              color: AppTheme.foreground,
            ),
          ),
        ),
        body: SafeArea(
          child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              logger.i(provider.qrBase64);
              if (provider.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary));
              }

              return context.pyrosStyles.buildMeshBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Card (Avatar y datos principales)
                      _buildHeroCard(
                          context, provider, authUser.firstName, isCoach),
                      const SizedBox(height: 16),

                      if (isCoach) ...[
                        _buildQrSection(context, provider),
                      ] else ...[
                        _buildBasicDataForm(context, provider),
                        const SizedBox(height: 16),
                        _buildGoalsSection(context, provider),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, provider),
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ProfileProvider provider,
      String? firstName, bool isCoach) {
    final initial = (firstName != null && firstName.isNotEmpty)
        ? firstName.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            firstName ?? 'Usuario',
            style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 32,
                color: AppTheme.foreground),
          ),
          if (isCoach)
            const Text("Entrenador",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          if (!isCoach) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Edad', _calculateAge(provider.studentData?['birthdate']?.toString() ?? provider.userData?['birthdate']?.toString())),
                _buildStat(
                    'Peso', '${provider.studentData?['weight'] ?? '-'} kg'),
                // Ocultar racha temporalmente
                // _buildStat('Racha', '${provider.userData?['streak'] ?? '-'}d'),
              ],
            ),
            if (!provider.isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    onPressed: () => provider.setEditing(true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.foreground,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              )
          ]
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 24,
                color: AppTheme.foreground)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _calculateAge(String? birthdateStr) {
    if (birthdateStr == null || birthdateStr.isEmpty) return '-';
    try {
      final birthDate = DateTime.parse(birthdateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      final monthDifference = today.month - birthDate.month;
      if (monthDifference < 0 ||
          (monthDifference == 0 && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return '-';
    }
  }

  Widget _buildBasicDataForm(BuildContext context, ProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos básicos',
              style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 24,
                  color: AppTheme.foreground)),
          const SizedBox(height: 16),
          _buildTextField('Peso (kg)', provider.editingWeight?.toString() ?? '',
              provider.isEditing, (v) => provider.updateField('weight', v),
              keyboardType: TextInputType.number),
          _buildTextField(
              'Altura (cm)',
              provider.editingHeight?.toString() ?? '',
              provider.isEditing,
              (v) => provider.updateField('height', v),
              keyboardType: TextInputType.number),
          _buildTextField(
              '% de grasa',
              provider.editingBodyFatPercentage?.toString() ?? '',
              provider.isEditing,
              (v) => provider.updateField('bodyFatPercentage', v),
              keyboardType: TextInputType.number),
          _buildTextField(
              'Nivel de actividad',
              provider.editingActivityLevel ?? '',
              provider.isEditing,
              (v) => provider.updateField('activityLevel', v)),
          _buildTextField(
              'Condiciones médicas',
              provider.editingMedicalConditions ?? '',
              provider.isEditing,
              (v) => provider.updateField('medicalConditions', v)),
          _buildTextField('Alergias', provider.editingAllergies ?? '',
              provider.isEditing, (v) => provider.updateField('allergies', v)),
          _buildTextField('Experiencia',
              provider.studentData?['fitnessExperience'] ?? '', false, null),
          _buildTextField('Notas', provider.studentData?['generalNotes'] ?? '',
              false, null),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String value, bool enabled, Function(String)? onChanged,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.foreground),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary)),
          filled: true,
          fillColor:
              enabled ? Colors.transparent : Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, ProfileProvider provider) {
    final Map<String, String> goalLabels = {
      'muscle': 'Ganancia muscular',
      'fat-loss': 'Perder grasa',
      'strength': 'Ganar fuerza',
      'endurance': 'Ganar resistencia',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Objetivos',
              style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 24,
                  color: AppTheme.foreground)),
          const SizedBox(height: 16),
          ...goalLabels.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value,
                  style: const TextStyle(color: AppTheme.foreground)),
              value: entry.key,
              groupValue: provider.editingFitnessGoal,
              onChanged: provider.isEditing
                  ? (val) {
                      if (val != null) provider.updateField('fitnessGoal', val);
                    }
                  : null,
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQrSection(BuildContext context, ProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Tu Código de Acceso',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.foreground)),
          const SizedBox(height: 16),
          if (provider.qrBase64 != null) ...[
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(8)),
              child: Image.memory(base64Decode(provider.qrBase64!),
                  width: 200, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (provider.urlToShare != null) {
                  Clipboard.setData(ClipboardData(text: provider.urlToShare!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Enlace copiado al portapapeles')));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white),
              child: const Text('Compartir enlace'),
            ),
          ] else ...[
            const SizedBox(
                height: 200,
                width: 200,
                child: Center(
                    child: Text("Generando QR...",
                        style: TextStyle(color: Colors.grey)))),
          ],
          const SizedBox(height: 8),
          const Text('Muéstraselo a tus futuros clientes',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileProvider provider) {
    if (!provider.isEditing) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed:
                provider.isSaving ? null : () => provider.setEditing(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    final success = await provider.saveProfile();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cambios guardados')));
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Error guardando la data')));
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white),
            child: provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }
}
