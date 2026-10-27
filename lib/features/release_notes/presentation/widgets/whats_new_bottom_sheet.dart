import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/release_notes/data/models/release_note_model.dart';
import 'package:pyrosfitmovil/features/release_notes/data/release_notes_catalog.dart';
import 'package:pyrosfitmovil/features/release_notes/services/release_notes_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class WhatsNewBottomSheet extends StatelessWidget {
  final ReleaseNote releaseNote;
  final VoidCallback? onDismiss;

  const WhatsNewBottomSheet({
    super.key,
    required this.releaseNote,
    this.onDismiss,
  });

  /// Muestra el modal si hay una nueva versión que el usuario no ha visto aún.
  /// Retorna `true` si se mostró el modal.
  static Future<bool> checkAndShow(BuildContext context) async {
    final service = ReleaseNotesService.instance;
    final shouldShow = await service.shouldShowWhatsNew();

    if (!shouldShow || !context.mounted) {
      return false;
    }

    final latestRelease = await service.getCurrentOrLatestRelease();
    if (!context.mounted) return false;

    await show(
      context,
      releaseNote: latestRelease,
      onDismiss: () async {
        await service.markCurrentVersionAsSeen();
      },
    );

    return true;
  }

  /// Muestra el modal manualmente para una versión específica (o la última por defecto)
  static Future<void> show(
    BuildContext context, {
    ReleaseNote? releaseNote,
    VoidCallback? onDismiss,
  }) {
    final note = releaseNote ?? ReleaseNotesCatalog.latestRelease;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsNewBottomSheet(
        releaseNote: note,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('d MMMM yyyy', 'es_US').format(releaseNote.releaseDate);

    // Obtener el rol actual para filtrar novedades relevantes
    final auth = context.watch<AuthProvider>();
    final userRole = auth.user?.role;
    final visibleItems = releaseNote.filteredItemsFor(userRole);
    final itemsToDisplay = visibleItems.isNotEmpty ? visibleItems : releaseNote.items;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1.5),
          left: BorderSide(color: AppTheme.border, width: 1),
          right: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar superior
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.fireGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'NOVEDADES',
                              style: TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 24,
                                letterSpacing: 1.5,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'v${releaseNote.version}${releaseNote.buildNumber != null ? '+${releaseNote.buildNumber}' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGlow,
                                ),
                              ),
                            ),
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.mutedForeground),
                    onPressed: () {
                      onDismiss?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            if (releaseNote.subtitle != null && releaseNote.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  releaseNote.subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                    height: 1.3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1),

            // Lista deslizable de añadidos
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                itemCount: itemsToDisplay.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = itemsToDisplay[index];
                  final iconData = item.icon ?? item.type.defaultIcon;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: item.type.badgeBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconData,
                            size: 20,
                            color: item.type.badgeTextColor,
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.type.badgeBgColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.type.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: item.type.badgeTextColor,
                                      ),
                                    ),
                                  ),
                                  if (item.audience != TargetAudience.all)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.audience.badgeBgColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.audience.label,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: item.audience.badgeTextColor,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.foreground,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedForeground,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botón de confirmación / Cierre
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.fireGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    onDismiss?.call();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '¡ENTENDIDO, A ENTRENAR!',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 20,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
