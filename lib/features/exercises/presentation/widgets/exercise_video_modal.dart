import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/video_thumbnail_badge.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ExerciseVideoModal extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseVideoModal({super.key, required this.exercise});

  static void show(BuildContext context, ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExerciseVideoModal(exercise: exercise),
    );
  }

  @override
  State<ExerciseVideoModal> createState() => _ExerciseVideoModalState();
}

class _ExerciseVideoModalState extends State<ExerciseVideoModal> {
  String? _resolvedUrl;
  String? _youtubeId;
  bool _isLoading = true;
  String? _errorMessage;

  // VideoPlayer Controller (para videos de R2 / MP4)
  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _isMuted = false;

  // WebViewController (para YouTube)
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initVideoSource();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoSource() async {
    final raw = widget.exercise.videoUrl?.trim() ?? widget.exercise.videoKey?.trim() ?? '';
    if (raw.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No hay enlace ni archivo de video disponible para este ejercicio.';
      });
      return;
    }

    final ytId = VideoThumbnailBadge.extractYoutubeId(raw);
    if (ytId != null) {
      _youtubeId = ytId;
      _initYouTubeWebView(ytId);
      return;
    }

    // Direct URL o Storage Key de Cloudflare R2
    String playableUrl = raw;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      try {
        final downloadUrl = await StorageService.getServeDownloadUrl(raw);
        playableUrl = downloadUrl.isNotEmpty ? downloadUrl : StorageService.getServeUrl(raw);
      } catch (_) {
        playableUrl = StorageService.getServeUrl(raw);
      }
    }

    _resolvedUrl = playableUrl;
    await _initNativeVideoPlayer(playableUrl);
  }

  void _initYouTubeWebView(String ytId) {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) => NavigationDecision.navigate,
            onWebResourceError: (error) {
              debugPrint('YouTube WebView Error: ${error.description}');
            },
          ),
        );

      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      // Cargar directamente la URL de embed oficial de YouTube en lugar de anidar iframes locales
      // Esto evita el Error 152-4 (origen no permitido / bloqueo de sandbox)
      final directEmbedUri = Uri.parse(
        'https://www.youtube.com/embed/$ytId?autoplay=1&playsinline=1&rel=0&modestbranding=1&fs=1',
      );

      controller.loadRequest(
        directEmbedUri,
        headers: {
          'Referer': 'https://www.youtube.com/',
        },
      );

      if (mounted) {
        setState(() {
          _webViewController = controller;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar el reproductor de YouTube: $e';
        });
      }
    }
  }

  Future<void> _initNativeVideoPlayer(String url) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      controller.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = controller.value.isPlaying;
          });
        }
      });

      if (mounted) {
        setState(() {
          _videoPlayerController = controller;
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo reproducir el video. Verifica tu conexión a internet o el formato del archivo.';
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;
    if (_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    } else {
      _videoPlayerController!.play();
    }
  }

  void _toggleMute() {
    if (_videoPlayerController == null) return;
    final newVolume = _isMuted ? 1.0 : 0.0;
    _videoPlayerController!.setVolume(newVolume);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _openExternalYouTube() async {
    if (_youtubeId == null) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$_youtubeId');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header con Nombre del Ejercicio y Botón de Cerrar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              widget.exercise.muscleGroup.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppTheme.primaryGlow,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _youtubeId != null ? Icons.smart_display_rounded : Icons.cloud_done_rounded,
                            size: 14,
                            color: _youtubeId != null ? Colors.redAccent : AppTheme.primaryGlow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _youtubeId != null ? 'YouTube' : 'Cloudflare R2 HD',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Contenedor del Reproductor de Video (Aspect Ratio 16:9)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black,
                height: 220,
                width: double.infinity,
                child: _buildPlayerContent(),
              ),
            ),
            const SizedBox(height: 12),

            // Controles de Reproducción para videos nativos (R2 / MP4)
            if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) ...[
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: AppTheme.primaryGlow,
                      size: 32,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _videoPlayerController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppTheme.primary,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ],

            // Botón directo para YouTube
            if (_youtubeId != null) ...[
              ElevatedButton.icon(
                onPressed: _openExternalYouTube,
                icon: const Icon(Icons.smart_display_rounded, color: Colors.white, size: 18),
                label: const Text('Ver directamente en YouTube', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC0000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Descripción técnica / Consejos del ejercicio
            if (widget.exercise.description?.trim().isNotEmpty == true) ...[
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryGlow),
                        SizedBox(width: 6),
                        Text(
                          'Técnica y ejecución',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.exercise.description!,
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Botón Copiar Enlace
            if (_resolvedUrl != null || _youtubeId != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.white70),
                label: const Text('Copiar enlace del video', style: TextStyle(color: Colors.white70, fontSize: 12)),
                onPressed: () async {
                  final link = _resolvedUrl ?? 'https://www.youtube.com/watch?v=$_youtubeId';
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enlace copiado al portapapeles'),
                        backgroundColor: Color(0xFF10B981),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 12),
            Text(
              'Cargando reproductor de video...',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 36, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (_youtubeId != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _openExternalYouTube,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Abrir en YouTube'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Reproductor YouTube (WebView embebido con baseUrl)
    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    // Reproductor Nativo de Video (Cloudflare R2 / MP4)
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
            if (!_isPlaying)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'Video no disponible',
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}
