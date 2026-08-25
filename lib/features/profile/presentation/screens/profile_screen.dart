import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/profile/presentation/controllers/profile_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isCopied = false;

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
              fontSize: 26,
              letterSpacing: 2,
              color: AppTheme.foreground,
            ),
          ),
          actions: [
            if (isCoach)
              IconButton(
                icon: const Icon(Icons.people_alt_outlined, color: AppTheme.primaryGlow),
                tooltip: 'Mis Alumnos',
                onPressed: () => context.go('/clientes'),
              ),
          ],
        ),
        body: SafeArea(
          child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              return context.pyrosStyles.buildMeshBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isCoach) ...[
                        _buildCoachProfile(context, provider, authUser.firstName),
                      ] else ...[
                        _buildStudentProfile(context, provider, authUser.firstName),
                      ],
                      const SizedBox(height: 24),
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

  // =========================================================================
  // COACH PROFILE VIEW
  // =========================================================================

  Widget _buildCoachProfile(BuildContext context, ProfileProvider provider, String? firstName) {
    final coachData = provider.coachData;
    final isVerified = coachData?['isVerified'] == true;
    final bannerUrl = provider.isEditing
        ? (provider.editingBannerUrl ?? coachData?['bannerUrl'])
        : (coachData?['bannerUrl'] ?? provider.editingBannerUrl);

    final String fullName =
        '${firstName ?? "Entrenador"} ${provider.userData?['lastName'] ?? ''}'.trim();
    final String initial = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'C';

    final String bio = (provider.isEditing ? provider.editingBio : coachData?['bio']) ??
        'Entrena con propósito. Progresa sin excusas.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. BANNER CARD CON SUPERPOSICIÓN DE AVATAR
        _buildCoachHeaderCard(
          context,
          provider,
          bannerUrl: bannerUrl,
          fullName: fullName,
          initial: initial,
          bio: bio,
          isVerified: isVerified,
        ),
        const SizedBox(height: 16),

        // 2. TARJETA: SOBRE MI MARCA (BIO & CERTIFICACIONES)
        _buildCoachBrandCard(context, provider, bio),
        const SizedBox(height: 16),

        // 3. TARJETA: CÓDIGO QR Y ENLACE DE REGISTRO
        _buildCoachQrCard(context, provider),
        const SizedBox(height: 16),

        // 4. BARRA DE GUARDAR / CANCELAR EN MODO EDICIÓN
        if (provider.isEditing) _buildActionButtons(context, provider),
      ],
    );
  }

  Widget _buildCoachHeaderCard(
    BuildContext context,
    ProfileProvider provider, {
    required String? bannerUrl,
    required String fullName,
    required String initial,
    required String bio,
    required bool isVerified,
  }) {
    final hasBanner = bannerUrl != null && bannerUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image Area
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.25),
                      const Color(0xFF18181B),
                      AppTheme.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: hasBanner
                    ? _renderBannerImage(bannerUrl)
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: AppTheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sin imagen de banner'.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Gradient Overlay at bottom for smooth contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF18181B).withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons Top Right
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    if (hasBanner) ...[
                      Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            provider.removeBanner();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Banner eliminado. Guarda los cambios para confirmar.'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text('Quitar', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _pickBannerImage(context, provider),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.primaryGlow),
                              const SizedBox(width: 5),
                              Text(
                                hasBanner ? 'Cambiar' : 'Subir banner',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Header Content (Overlapping Avatar & Coach Info)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppTheme.fireGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF18181B), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Action Buttons
                      if (provider.isEditing)
                        OutlinedButton.icon(
                          onPressed: () => provider.setEditing(false),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => provider.setEditing(true),
                          icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryGlow),
                          label: const Text('Editar marca'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/clientes'),
                        icon: const Icon(Icons.people_alt_rounded, size: 16),
                        label: const Text('Alumnos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tags & Name
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ENTRENADOR CERTIFICADO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5,
                              color: AppTheme.primaryGlow,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 11, color: Color(0xFF34D399)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Verificado',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '“$bio”',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Stats Row (4 stats)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCoachStatItem('Alumnos', '24'),
                      _buildStatDivider(),
                      _buildCoachStatItem('Rutinas', '86'),
                      _buildStatDivider(),
                      _buildCoachStatItem('Valoración', '4.9 ⭐'),
                      _buildStatDivider(),
                      _buildCoachStatItem('Experiencia', '6 años'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildCoachBrandCard(BuildContext context, ProfileProvider provider, String bio) {
    final certsRaw = provider.isEditing
        ? (provider.editingCertifications ?? '')
        : (provider.coachData?['certifications']?.toString() ?? 'Personal Trainer, Nutrición deportiva');

    final certList = certsRaw
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: AppTheme.primaryGlow, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Sobre mi marca',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (provider.isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Editando información',
                    style: TextStyle(color: AppTheme.primaryGlow, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!provider.isEditing) ...[
            // View Mode
            const Text(
              'ESLOGAN / BIOGRAFÍA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bio,
              style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
            ),
            const SizedBox(height: 16),

            const Text(
              'CERTIFICACIONES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (certList.isNotEmpty ? certList : ['Personal Trainer', 'Nutrición deportiva'])
                  .map((cert) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          cert,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 18),

            // Performance sub-stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubStat('Sesiones/sem', '32'),
                  _buildStatDivider(),
                  _buildSubStat('Retención', '92%'),
                  _buildStatDivider(),
                  _buildSubStat('Racha media', '11d'),
                ],
              ),
            ),
          ] else ...[
            // Edit Mode
            const Text(
              'ESLOGAN / BIOGRAFÍA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: provider.editingBio ?? '',
              onChanged: (v) => provider.updateCoachField('bio', v),
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ej: Entrena con propósito. Progresa sin excusas.',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF27272A).withValues(alpha: 0.6),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'CERTIFICACIONES (SEPARADAS POR COMA)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: provider.editingCertifications ?? '',
              onChanged: (v) => provider.updateCoachField('certifications', v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Personal Trainer, Nutrición deportiva, Crossfit L1',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF27272A).withValues(alpha: 0.6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),

            // Live tag preview
            if (certList.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'VISTA PREVIA DE ETIQUETAS:',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: certList
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: AppTheme.primaryGlow, fontSize: 11),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildCoachQrCard(BuildContext context, ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGlow, size: 24),
              SizedBox(width: 8),
              Text(
                'Código de acceso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (provider.qrBase64 != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Image.memory(
                base64Decode(provider.qrBase64!),
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ] else ...[
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Center(
                child: Text('Generando QR...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 12),

          const Text(
            'Muéstrale el QR a tus alumnos o comparte el enlace directo para que se unan a tu equipo.',
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final targetUrl = provider.urlToShare ?? '';
                if (targetUrl.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: targetUrl));
                  setState(() => _isCopied = true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enlace copiado al portapapeles'),
                        backgroundColor: Color(0xFF10B981),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  Future.delayed(const Duration(milliseconds: 2500), () {
                    if (mounted) setState(() => _isCopied = false);
                  });
                }
              },
              icon: Icon(
                _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                size: 18,
                color: _isCopied ? Colors.white : AppTheme.primaryGlow,
              ),
              label: Text(
                _isCopied ? '¡Enlace copiado!' : 'Copiar enlace de registro',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCopied
                    ? const Color(0xFF10B981)
                    : const Color(0xFF27272A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                  color: _isCopied
                      ? const Color(0xFF34D399)
                      : AppTheme.border,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderBannerImage(String? banner) {
    if (banner == null || banner.isEmpty) {
      return const SizedBox.shrink();
    }
    if (banner.startsWith('data:image') || !banner.startsWith('http')) {
      try {
        final cleanBase64 = banner.contains(',') ? banner.split(',')[1] : banner;
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      }
    } else {
      return Image.network(
        banner,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
  }

  Future<void> _pickBannerImage(BuildContext context, ProfileProvider provider) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        provider.setBanner(base64String);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner cargado. Guarda los cambios para conservarlo.'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================================
  // STUDENT PROFILE VIEW
  // =========================================================================

  Widget _buildStudentProfile(BuildContext context, ProfileProvider provider, String? firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(context, provider, firstName),
        const SizedBox(height: 16),
        _buildBasicDataForm(context, provider),
        const SizedBox(height: 16),
        _buildGoalsSection(context, provider),
        const SizedBox(height: 24),
        _buildActionButtons(context, provider),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, ProfileProvider provider, String? firstName) {
    final initial = (firstName != null && firstName.isNotEmpty)
        ? firstName.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.fireGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 42,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            firstName ?? 'Usuario',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                'Edad',
                _calculateAge(provider.studentData?['birthdate']?.toString() ??
                    provider.userData?['birthdate']?.toString()),
              ),
              _buildStatDivider(),
              _buildStat('Peso', '${provider.studentData?['weight'] ?? '-'} kg'),
            ],
          ),
          if (!provider.isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16, color: AppTheme.primaryGlow),
                  label: const Text('Editar'),
                  onPressed: () => provider.setEditing(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos básicos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary)),
          filled: true,
          fillColor:
              enabled ? const Color(0xFF27272A).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.04),
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
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Objetivos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...goalLabels.entries.map((entry) {
            final isSelected = provider.editingFitnessGoal == entry.key;
            return GestureDetector(
              onTap: provider.isEditing ? () => provider.updateField('fitnessGoal', entry.key) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppTheme.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                provider.isSaving ? null : () => provider.setEditing(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    final success = await provider.saveProfile();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cambios guardados con éxito'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al guardar los datos'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Guardar cambios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
