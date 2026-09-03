import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class VideoThumbnailBadge extends StatelessWidget {
  final String? videoKey;
  final String? videoUrl;
  final VoidCallback? onTap;
  final double height;
  final double width;

  const VideoThumbnailBadge({
    super.key,
    this.videoKey,
    this.videoUrl,
    this.onTap,
    this.height = 110,
    this.width = double.infinity,
  });

  static String? extractYoutubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final regExp = RegExp(
      r'(?:youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=|shorts\/)([^#&?]*)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    if (match != null && match.group(1) != null && match.group(1)!.length == 11) {
      return match.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final raw = videoUrl?.trim() ?? videoKey?.trim() ?? '';
    final ytId = extractYoutubeId(raw);
    final hasVideo = raw.isNotEmpty;

    return GestureDetector(
      onTap: hasVideo ? onTap : null,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background / Thumbnail
            if (ytId != null) ...[
              Image.network(
                'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(hasVideo),
              ),
            ] else if (hasVideo) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.25),
                      const Color(0xFF18181B),
                      Colors.black87,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.movie_filter_outlined,
                    size: 38,
                    color: Colors.white24,
                  ),
                ),
              ),
            ] else ...[
              _buildPlaceholder(false),
            ],

            // Dark vignette overlay if has video
            if (hasVideo)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Center Play Badge or No-video Icon
            if (hasVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),

            // Top Badge (YouTube vs Cloudflare R2)
            if (hasVideo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ytId != null ? Icons.smart_display_rounded : Icons.cloud_done_rounded,
                        size: 11,
                        color: ytId != null ? Colors.redAccent : AppTheme.primaryGlow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ytId != null ? 'YouTube' : 'Video HD',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool hasVideo) {
    return Container(
      color: const Color(0xFF141416),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 28,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 4),
            Text(
              'Sin video',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
