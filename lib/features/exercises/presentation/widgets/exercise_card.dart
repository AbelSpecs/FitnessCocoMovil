import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/video_thumbnail_badge.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isOwner;
  final VoidCallback? onPlayVideo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isOwner = true,
    this.onPlayVideo,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Miniatura de Video (Aspect Ratio 16:9 Táctil)
          VideoThumbnailBadge(
            videoKey: exercise.videoKey,
            videoUrl: exercise.videoUrl,
            height: 140,
            onTap: onPlayVideo,
          ),

          // 2. Información del Ejercicio
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grupo Muscular Chip + Custom / Base Library Chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        exercise.muscleGroup.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppTheme.primaryGlow,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'Personalizado',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 10, color: Colors.white54),
                            SizedBox(width: 4),
                            Text(
                              'Biblioteca base',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Título del Ejercicio
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Descripción o Técnica
                Text(
                  exercise.description?.trim().isNotEmpty == true
                      ? exercise.description!
                      : 'Sin descripción técnica registrada.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),

                // Acciones Rápidas Móviles
                Row(
                  children: [
                    if (exercise.hasVideo) ...[
                      InkWell(
                        onTap: onPlayVideo,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_fill_rounded, size: 16, color: AppTheme.primaryGlow),
                              SizedBox(width: 4),
                              Text('Ver video', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isOwner) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                        onPressed: onEdit,
                        tooltip: 'Editar ejercicio',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        onPressed: onDelete,
                        tooltip: 'Eliminar ejercicio',
                        visualDensity: VisualDensity.compact,
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white38),
                            SizedBox(width: 4),
                            Text(
                              'Solo lectura',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
