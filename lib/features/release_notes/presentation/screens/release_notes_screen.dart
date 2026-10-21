import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pyrosfitmovil/features/release_notes/data/models/release_note_model.dart';
import 'package:pyrosfitmovil/features/release_notes/data/release_notes_catalog.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Pantalla completa de historial y feed de versiones de PyrosFit.
class ReleaseNotesScreen extends StatelessWidget {
  const ReleaseNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final releases = ReleaseNotesCatalog.allReleases;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'HISTORIAL DE NOVEDADES',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            letterSpacing: 2,
            color: AppTheme.foreground,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          itemCount: releases.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final release = releases[index];
            final isLatest = index == 0;
            return _buildReleaseCard(context, release, isLatest);
          },
        ),
      ),
    );
  }

  Widget _buildReleaseCard(
      BuildContext context, ReleaseNote release, bool isLatest) {
    final formattedDate =
        DateFormat('d MMMM yyyy', 'es_US').format(release.releaseDate);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? AppTheme.primary.withValues(alpha: 0.5)
              : AppTheme.border,
          width: isLatest ? 1.5 : 1,
        ),
        boxShadow: isLatest
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la versión
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isLatest ? AppTheme.fireGradient : null,
                      color: isLatest ? null : AppTheme.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v${release.version}${release.buildNumber != null ? '+${release.buildNumber}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLatest ? Colors.white : AppTheme.foreground,
                      ),
                    ),
                  ),
                  if (isLatest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGlow,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Título de la versión
          Text(
            release.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),

          if (release.subtitle != null && release.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              release.subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.mutedForeground,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),

          // Lista de añadidos
          ...release.items.map((item) {
            final icon = item.icon ?? item.type.defaultIcon;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.type.badgeBgColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: item.type.badgeTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: item.type.badgeBgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.type.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: item.type.badgeTextColor,
                                ),
                              ),
                            ),
                            if (item.audience != TargetAudience.all)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: item.audience.badgeBgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.audience.label,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: item.audience.badgeTextColor,
                                  ),
                                ),
                              ),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
