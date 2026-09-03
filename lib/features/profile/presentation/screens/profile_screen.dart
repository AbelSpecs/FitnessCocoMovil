import 'package:pyrosfitmovil/core/services/user_service.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/core/widgets/user_avatar.dart';
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
  int _coachSelectedTab = 0;
  int _studentSelectedTab = 0;

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
      create: (_) => ProfileProvider()..fetchProfile(authUser.id, isCoach, authProvider: context.read<AuthProvider>()),
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
    final authUser = context.read<AuthProvider>().user;
    final bannerUrl = provider.isEditing
        ? (provider.editingBannerUrl != null && provider.editingBannerUrl!.trim().isNotEmpty
            ? provider.editingBannerUrl
            : null)
        : (provider.bannerPictureUrl ??
            provider.bannerPictureKey ??
            provider.editingBannerUrl ??
            authUser?.bannerPictureUrl ??
            authUser?.bannerPictureKey);

    final String fullName =
        '${firstName ?? "Entrenador"} ${provider.userData?['lastName'] ?? ''}'.trim();
    final String initial = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'C';

    final String bio = (provider.isEditing ? provider.editingBio : coachData?['bio']) ??
        'Entrena con propósito. Progresa sin excusas.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. HERO HEADER MÓVIL (Banner + Avatar Centrado + Identidad + Acciones Rápidas)
        _buildCoachHeroHeader(
          context,
          provider,
          bannerUrl: bannerUrl,
          fullName: fullName,
          initial: initial,
          bio: bio,
          isVerified: isVerified,
        ),
        const SizedBox(height: 16),

        // 2. FILA DE MÉTRICAS RÁPIDAS (KPIs)
        _buildCoachKpisRow(),
        const SizedBox(height: 20),

        // 3. SELECTOR DE PESTAÑAS NATIVO O MODO EDICIÓN
        if (!provider.isEditing) ...[
          _buildMobileSegmentedTabs(
            tabs: const ['Mi Marca', 'Enlace & QR', 'Cuenta'],
            selectedIndex: _coachSelectedTab,
            onTabSelected: (index) => setState(() => _coachSelectedTab = index),
          ),
          const SizedBox(height: 16),

          // Contenido de la pestaña activa
          if (_coachSelectedTab == 0)
            _buildCoachBrandCard(context, provider, bio)
          else if (_coachSelectedTab == 1)
            _buildCoachQrCard(context, provider)
          else
            _buildCoachAccountCard(context, provider, authUser),
        ] else ...[
          // Modo edición de perfil enfocado
          _buildCoachBrandCard(context, provider, bio),
          const SizedBox(height: 16),
          _buildActionButtons(context, provider),
        ],
      ],
    );
  }

  Widget _buildCoachHeroHeader(
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. ÁREA DE PORTADA / BANNER
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 165,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.3),
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
                              Icons.photo_library_outlined,
                              size: 38,
                              color: AppTheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'PORTADA DE ENTRENADOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Gradient Overlay sutil
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        const Color(0xFF18181B).withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Botones flotantes de portada
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
                          onTap: () => _removeBanner(context, provider),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _showBannerOptions(context, provider),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_rounded, size: 15, color: AppTheme.primaryGlow),
                              const SizedBox(width: 5),
                              Text(
                                hasBanner ? 'Cambiar portada' : 'Subir portada',
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

              // Avatar Centrado con Halo de Fuego y Badge de Cámara
              Positioned(
                bottom: -40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: UserAvatar(
                        size: 84,
                        shape: BoxShape.circle,
                        showBorder: true,
                        borderColor: const Color(0xFF18181B),
                        storageKey: provider.profilePictureKey,
                        imageUrl: provider.profilePictureUrl,
                        initial: initial,
                        onTap: () => _showAvatarOptions(context, provider),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showAvatarOptions(context, provider),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF18181B), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // 2. IDENTIDAD CENTRAL DEL ENTRENADOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF34D399)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'COACH CERTIFICADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppTheme.primaryGlow,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '“$bio”',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Botones de acción móviles estilizados
                Row(
                  children: [
                    Expanded(
                      child: provider.isEditing
                          ? OutlinedButton.icon(
                              onPressed: () => provider.setEditing(false),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Cancelar edición'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => provider.setEditing(true),
                              icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryGlow),
                              label: const Text('Editar Perfil'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/clientes'),
                        icon: const Icon(Icons.people_alt_rounded, size: 16),
                        label: const Text('Mis Alumnos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
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
    if (banner == null || banner.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final trimmed = banner.trim();

    if (trimmed.startsWith('data:image')) {
      try {
        final cleanBase64 = trimmed.contains(',') ? trimmed.split(',')[1] : trimmed;
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
    }

    final effectiveUrl = StorageService.getServeUrl(trimmed);
    if (effectiveUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Image.network(
      effectiveUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF18181B),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF18181B),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
        ),
      ),
    );
  }



  // =========================================================================
  // STUDENT PROFILE VIEW
  // =========================================================================

  Widget _buildStudentProfile(BuildContext context, ProfileProvider provider, String? firstName) {
    final authUser = context.read<AuthProvider>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(context, provider, firstName),
        const SizedBox(height: 16),

        if (!provider.isEditing) ...[
          _buildMobileSegmentedTabs(
            tabs: const ['Métricas', 'Objetivos', 'Cuenta'],
            selectedIndex: _studentSelectedTab,
            onTabSelected: (index) => setState(() => _studentSelectedTab = index),
          ),
          const SizedBox(height: 16),

          if (_studentSelectedTab == 0)
            _buildBasicDataForm(context, provider)
          else if (_studentSelectedTab == 1)
            _buildGoalsSection(context, provider)
          else
            _buildCoachAccountCard(context, provider, authUser),
        ] else ...[
          _buildBasicDataForm(context, provider),
          const SizedBox(height: 16),
          _buildGoalsSection(context, provider),
          const SizedBox(height: 24),
          _buildActionButtons(context, provider),
        ],
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                size: 80,
                shape: BoxShape.circle,
                storageKey: provider.profilePictureKey,
                imageUrl: provider.profilePictureUrl,
                initial: initial,
                onTap: () => _showAvatarOptions(context, provider),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: () => _showAvatarOptions(context, provider),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF18181B), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
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


  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildCoachKpisRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCoachKpiItem(Icons.group_outlined, 'Alumnos', '24'),
          _buildStatDivider(),
          _buildCoachKpiItem(Icons.fitness_center_outlined, 'Rutinas', '86'),
          _buildStatDivider(),
          _buildCoachKpiItem(Icons.star_rounded, 'Rating', '4.9'),
          _buildStatDivider(),
          _buildCoachKpiItem(Icons.workspace_premium_outlined, 'Exp.', '6 años'),
        ],
      ),
    );
  }

  Widget _buildCoachKpiItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGlow),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
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

  Widget _buildMobileSegmentedTabs({
    required List<String> tabs,
    required int selectedIndex,
    required ValueChanged<int> onTabSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCoachAccountCard(BuildContext context, ProfileProvider provider, dynamic authUser) {
    final email = authUser?.email ?? provider.userData?['email']?.toString() ?? 'No disponible';
    final id = authUser?.id?.toString() ?? provider.userData?['id']?.toString() ?? '1';

    String roleDisplay = provider.isCoach ? 'Entrenador (Coach)' : 'Alumno';
    final r = authUser?.role?.toString().toLowerCase();
    if (r != null) {
      if (r.contains('coach')) {
        roleDisplay = 'Entrenador (Coach)';
      } else if (r.contains('student') || r.contains('alumno')) {
        roleDisplay = 'Alumno';
      }
    }

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
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primaryGlow, size: 20),
              SizedBox(width: 8),
              Text(
                'Cuenta y Seguridad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAccountInfoRow('Correo electrónico', email),
          const Divider(color: Colors.white12, height: 24),
          _buildAccountInfoRow('Rol de usuario', roleDisplay),
          const Divider(color: Colors.white12, height: 24),
          _buildAccountInfoRow('ID de Usuario', '#$id'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset_rounded, size: 18, color: AppTheme.primaryGlow),
              label: const Text('Restablecer contraseña'),
              onPressed: () => context.push('/forgot-password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
              label: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  void _showAvatarOptions(BuildContext context, ProfileProvider provider) {
    final hasAvatar = provider.profilePictureKey != null && provider.profilePictureKey!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Foto de Perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryGlow),
                  ),
                  title: const Text('Elegir de la galería', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadProfileImage(context, provider, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGlow),
                  ),
                  title: const Text('Tomar foto con la cámara', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadProfileImage(context, provider, ImageSource.camera);
                  },
                ),
                if (hasAvatar) ...[
                  const Divider(color: Colors.white12, height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    ),
                    title: const Text('Eliminar foto actual', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _removeProfileImage(context, provider);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadProfileImage(
    BuildContext context,
    ProfileProvider provider,
    ImageSource source,
  ) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    final prevKey = provider.profilePictureKey;
    final prevUrl = provider.profilePictureUrl;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final localBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // ⚡ ACTUALIZACIÓN VISUAL INSTANTÁNEA (0 ms)
      provider.updateProfilePicture(localBase64, localBase64);
      auth.updateProfilePicture(localBase64, localBase64);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Guardando foto en la nube...'),
              ],
            ),
            backgroundColor: Color(0xFF27272A),
            duration: Duration(seconds: 15),
          ),
        );
      }

      final fileName = picked.name.isNotEmpty ? picked.name : 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Obtener URL presignada de Cloudflare R2
      final presign = await StorageService.getPresignedProfileUrl(
        userId: userId,
        fileName: fileName,
        contentType: 'image/jpeg',
      );

      final uploadUrl = presign['uploadUrl'] as String;
      final key = presign['key'] as String;

      // 2. Subida binaria a Cloudflare R2
      await StorageService.uploadBytesToPresignedUrl(
        uploadUrl: uploadUrl,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      // 3. Persistir key en base de datos
      await UserService.updateProfilePictures(
        userId,
        profilePicture: key,
        bannerPicture: provider.bannerPictureKey,
      );

      // 4. Limpiar caché de imagen e inyectar cache-buster para actualización definitiva
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final serveUrl = StorageService.getServeUrl(key);
      final cacheBusterUrl = '$serveUrl&t=${DateTime.now().millisecondsSinceEpoch}';

      await auth.updateProfilePicture(key, cacheBusterUrl);
      provider.updateProfilePicture(key, cacheBusterUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Foto de perfil actualizada con éxito!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Revertir si falló la subida
      provider.updateProfilePicture(prevKey, prevUrl);
      auth.updateProfilePicture(prevKey ?? '', prevUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo subir la foto de perfil. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage(
    BuildContext context,
    ProfileProvider provider,
  ) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    try {
      await UserService.updateProfilePictures(
        userId,
        profilePicture: null,
        bannerPicture: provider.bannerPictureKey,
      );

      await auth.updateProfilePicture('', null);
      provider.updateProfilePicture(null, null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil eliminada'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la foto de perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBannerOptions(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Imagen de Portada / Banner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryGlow),
                  ),
                  title: const Text('Elegir de la galería', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadBannerImage(context, provider, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGlow),
                  ),
                  title: const Text('Tomar foto con la cámara', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadBannerImage(context, provider, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadBannerImage(
    BuildContext context,
    ProfileProvider provider,
    ImageSource source,
  ) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    final trainerId = auth.user?.coachId ?? auth.user?.id ?? 1;
    if (userId == null) return;

    final prevKey = provider.bannerPictureKey;
    final prevUrl = provider.bannerPictureUrl;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final localBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // ⚡ ACTUALIZACIÓN VISUAL INSTANTÁNEA (0 ms)
      provider.updateBannerPicture(localBase64, localBase64);
      auth.updateBannerPicture(localBase64, localBase64);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Guardando banner en la nube...'),
              ],
            ),
            backgroundColor: Color(0xFF27272A),
            duration: Duration(seconds: 15),
          ),
        );
      }

      final fileName = picked.name.isNotEmpty ? picked.name : 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Obtener URL presignada para banner
      final presign = await StorageService.getPresignedBannerUrl(
        trainerId: trainerId,
        fileName: fileName,
        contentType: 'image/jpeg',
      );

      final uploadUrl = presign['uploadUrl'] as String;
      final key = presign['key'] as String;

      // 2. Subida binaria directa a Cloudflare R2
      await StorageService.uploadBytesToPresignedUrl(
        uploadUrl: uploadUrl,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      // 3. Persistir key en base de datos inmediatamente
      await UserService.updateProfilePictures(
        userId,
        profilePicture: provider.profilePictureKey,
        bannerPicture: key,
      );

      // 4. Limpiar caché de imagen e inyectar cache-buster para actualización definitiva
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final serveUrl = StorageService.getServeUrl(key);
      final cacheBusterUrl = '$serveUrl&t=${DateTime.now().millisecondsSinceEpoch}';

      await auth.updateBannerPicture(key, cacheBusterUrl);
      provider.updateBannerPicture(key, cacheBusterUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Banner actualizado con éxito!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Revertir si falló la subida
      provider.updateBannerPicture(prevKey, prevUrl);
      auth.updateBannerPicture(prevKey ?? '', prevUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeBanner(
    BuildContext context,
    ProfileProvider provider,
  ) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Eliminando banner...'),
              ],
            ),
            backgroundColor: Color(0xFF27272A),
            duration: Duration(seconds: 5),
          ),
        );
      }

      await UserService.updateProfilePictures(
        userId,
        profilePicture: provider.profilePictureKey,
        bannerPicture: null,
      );

      await auth.updateBannerPicture('', null);
      provider.removeBanner();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner eliminado correctamente'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el banner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
