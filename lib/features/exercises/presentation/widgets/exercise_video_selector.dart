import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Selector modular de video demostrativo para ejercicios (Actividad T-20 / SCRUM-15).
/// Soporta pestaña 'Enlace Web' (con extracción de ID de YouTube y previsualización de miniatura)
/// y pestaña 'Subir Video' (carga nativa a Cloudflare R2 con validación <= 50MB y barra de progreso).
class ExerciseVideoSelector extends StatefulWidget {
  final int videoMode; // 0: Enlace Web, 1: Subir Video a R2
  final ValueChanged<int> onVideoModeChanged;
  final String videoUrl;
  final ValueChanged<String> onVideoUrlChanged;
  final XFile? selectedFile;
  final ValueChanged<XFile?> onFileSelected;
  final ValueChanged<Uint8List?> onBytesSelected;
  final bool isUploading;
  final double uploadProgress; // 0.0 to 1.0
  final bool disabled;

  const ExerciseVideoSelector({
    super.key,
    required this.videoMode,
    required this.onVideoModeChanged,
    required this.videoUrl,
    required this.onVideoUrlChanged,
    required this.selectedFile,
    required this.onFileSelected,
    required this.onBytesSelected,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.disabled = false,
  });

  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  static String? extractYoutubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final regExp = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    return match?.group(1);
  }

  @override
  State<ExerciseVideoSelector> createState() => _ExerciseVideoSelectorState();
}

class _ExerciseVideoSelectorState extends State<ExerciseVideoSelector> {
  late TextEditingController _urlController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.videoUrl);
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl && _urlController.text != widget.videoUrl) {
      _urlController.text = widget.videoUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (widget.disabled || widget.isUploading) return;
    setState(() => _errorMessage = null);

    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;

      final length = await video.length();
      if (length > ExerciseVideoSelector.maxFileSizeBytes) {
        setState(() {
          _errorMessage = 'El archivo supera los 50MB permitidos. Selecciona uno más liviano o usa YouTube.';
        });
        return;
      }

      final ext = video.name.split('.').last.toLowerCase();
      final allowed = ['mp4', 'mov', 'webm'];
      if (!allowed.contains(ext)) {
        setState(() {
          _errorMessage = 'Formato no admitido (solo .mp4, .mov, .webm).';
        });
        return;
      }

      final bytes = await video.readAsBytes();
      widget.onFileSelected(video);
      widget.onBytesSelected(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar video: $e';
      });
    }
  }

  void _clearSelectedFile() {
    widget.onFileSelected(null);
    widget.onBytesSelected(null);
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final ytId = ExerciseVideoSelector.extractYoutubeId(_urlController.text);
    final isDirectVideo = _urlController.text.endsWith('.mp4') ||
        _urlController.text.endsWith('.webm') ||
        _urlController.text.endsWith('.mov');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.video_library_rounded, size: 14, color: AppTheme.primaryGlow),
                SizedBox(width: 6),
                Text(
                  'VIDEO DEMOSTRATIVO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Text(
              '(opcional)',
              style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tabs switch
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.disabled || widget.isUploading
                      ? null
                      : () {
                          setState(() => _errorMessage = null);
                          widget.onVideoModeChanged(0);
                        },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.videoMode == 0
                          ? AppTheme.primary.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: widget.videoMode == 0
                          ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: widget.videoMode == 0 ? AppTheme.primaryGlow : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Enlace Web',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.videoMode == 0 ? FontWeight.bold : FontWeight.normal,
                            color: widget.videoMode == 0 ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: widget.disabled || widget.isUploading
                      ? null
                      : () {
                          setState(() => _errorMessage = null);
                          widget.onVideoModeChanged(1);
                        },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.videoMode == 1
                          ? AppTheme.primary.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: widget.videoMode == 1
                          ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 14,
                          color: widget.videoMode == 1 ? AppTheme.primaryGlow : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Subir Video',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.videoMode == 1 ? FontWeight.bold : FontWeight.normal,
                            color: widget.videoMode == 1 ? Colors.white : Colors.grey,
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
        const SizedBox(height: 10),

        // Tab Content
        if (widget.videoMode == 0) ...[
          TextField(
            controller: _urlController,
            enabled: !widget.disabled && !widget.isUploading,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://youtube.com/watch?v=... o enlace .mp4',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.35),
              prefixIcon: const Icon(Icons.video_library_outlined, color: Colors.grey, size: 18),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                      onPressed: () {
                        _urlController.clear();
                        widget.onVideoUrlChanged('');
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
            onChanged: (val) {
              widget.onVideoUrlChanged(val.trim());
              setState(() {});
            },
          ),
          if (ytId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                          width: 80,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 50,
                            color: Colors.black45,
                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.red, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'YouTube Detectado',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $ytId',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isDirectVideo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.primaryGlow, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Video directo compatible (.mp4 / .mov / .webm)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // Upload to R2 Tab
          if (widget.selectedFile == null) ...[
            InkWell(
              onTap: widget.disabled || widget.isUploading ? null : _pickVideo,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryGlow, size: 28),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toca para seleccionar video de tu dispositivo',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Formatos admitidos: MP4, MOV, WEBM (máx. 50MB)',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.movie_outlined, color: AppTheme.primaryGlow, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedFile!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Listo para subir a Cloudflare R2',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isUploading)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          onPressed: _clearSelectedFile,
                          tooltip: 'Quitar video',
                        ),
                    ],
                  ),
                  if (widget.isUploading) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.uploadProgress > 0 ? widget.uploadProgress : null,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Subiendo video: ${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],

        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 13),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
