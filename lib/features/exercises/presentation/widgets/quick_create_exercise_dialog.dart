import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/clients/presentation/providers/routines_provider.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_video_selector.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Modal para crear un ejercicio rápido con soporte de video demostrativo (Enlace o Cloudflare R2).
/// Réplica exacta del diálogo 'Crear ejercicio rápido' de la versión web (FitnessCoco).
class QuickCreateExerciseDialog extends StatefulWidget {
  final int? initialMuscleGroupId;

  const QuickCreateExerciseDialog({super.key, this.initialMuscleGroupId});

  @override
  State<QuickCreateExerciseDialog> createState() =>
      _QuickCreateExerciseDialogState();
}

class _QuickCreateExerciseDialogState extends State<QuickCreateExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  int? _selectedMuscleGroupId;
  int _videoMode = 0; // 0: Enlace Web (YouTube), 1: Subir Video a R2
  String _videoUrl = '';
  XFile? _selectedFile;
  Uint8List? _videoBytes;

  bool _isSaving = false;
  bool _isUploadingVideo = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedMuscleGroupId = widget.initialMuscleGroupId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routinesProv = context.read<RoutinesProvider>();
      if (_selectedMuscleGroupId == null && routinesProv.muscleGroups.isNotEmpty) {
        setState(() {
          _selectedMuscleGroupId = routinesProv.muscleGroups.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMuscleGroupId == null) {
      setState(() => _errorMessage = 'Selecciona un grupo muscular');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    String? finalVideoKey;
    String? finalVideoUrl;

    try {
      final auth = context.read<AuthProvider>();
      final coachId = auth.user?.coachId ?? auth.user?.id ?? 1;

      // 1. Si eligió subir un video local a Cloudflare R2
      if (_videoMode == 1 && _selectedFile != null && _videoBytes != null) {
        setState(() {
          _isUploadingVideo = true;
          _uploadProgress = 0.0;
        });

        final tempExerciseId = DateTime.now().millisecondsSinceEpoch % 100000000;
        final ext = _selectedFile!.name.split('.').last.toLowerCase();
        final contentType = ext == 'mp4'
            ? 'video/mp4'
            : (ext == 'mov' ? 'video/quicktime' : 'video/webm');

        final presign = await StorageService.getPresignedVideoUrl(
          trainerId: coachId,
          exerciseId: tempExerciseId,
          fileName: _selectedFile!.name,
          contentType: contentType,
        );

        final uploadUrl = presign['uploadUrl'] ?? presign['url'] ?? '';
        final videoKey = presign['key'] ?? presign['videoKey'] ?? '';

        await StorageService.uploadVideoBytes(
          uploadUrl: uploadUrl,
          bytes: _videoBytes!,
          contentType: contentType,
          onProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() {
                _uploadProgress = sent / total;
              });
            }
          },
        );

        finalVideoKey = videoKey;
        finalVideoUrl = videoKey;
      } else if (_videoMode == 0) {
        // Enlace Web (YouTube o URL directa)
        final url = _videoUrl.trim();
        if (url.isNotEmpty) {
          finalVideoKey = url;
          finalVideoUrl = url;
        }
      }

      // 2. Persistir ejercicio en el backend
      if (!mounted) return;
      final provider = context.read<RoutinesProvider>();
      final created = await provider.createCustomExercise(
        _nameController.text.trim(),
        _selectedMuscleGroupId!,
        videoKey: finalVideoKey,
        videoUrl: finalVideoUrl,
      );

      if (mounted) {
        if (created != null) {
          Navigator.of(context).pop(created);
        } else {
          setState(() {
            _errorMessage = 'No se pudo crear el ejercicio. Intenta de nuevo.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al crear ejercicio: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingVideo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routinesProv = context.watch<RoutinesProvider>();
    final muscleGroups = routinesProv.muscleGroups;

    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 480,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título y Descripción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Crear ejercicio rápido',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 24,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: (_isSaving || _isUploadingVideo)
                            ? null
                            : () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Crea un ejercicio nuevo para asignarlo de inmediato a este cliente.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 18),

                  // 1. Selector de Grupo Muscular
                  const Text(
                    'GRUPO MUSCULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedMuscleGroupId,
                    items: muscleGroups
                        .map((m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(
                                m.name,
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                              ),
                            ))
                        .toList(),
                    onChanged: (_isSaving || _isUploadingVideo)
                        ? null
                        : (val) {
                            setState(() {
                              _selectedMuscleGroupId = val;
                            });
                          },
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFF141416),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                    dropdownColor: const Color(0xFF222224),
                  ),
                  const SizedBox(height: 14),

                  // 2. Nombre del Ejercicio
                  const Text(
                    'NOMBRE DEL EJERCICIO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving && !_isUploadingVideo,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLength: 80,
                    decoration: InputDecoration(
                      hintText: 'Ej. Press inclinado con mancuernas',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      counterText: '',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFF141416),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Ingresa un nombre para el ejercicio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Selector de Video Demostrativo (Pestañas Enlace Web / Subir Video)
                  ExerciseVideoSelector(
                    videoMode: _videoMode,
                    onVideoModeChanged: (m) => setState(() => _videoMode = m),
                    videoUrl: _videoUrl,
                    onVideoUrlChanged: (u) => setState(() => _videoUrl = u),
                    selectedFile: _selectedFile,
                    onFileSelected: (f) => setState(() => _selectedFile = f),
                    onBytesSelected: (b) => setState(() => _videoBytes = b),
                    isUploading: _isUploadingVideo,
                    uploadProgress: _uploadProgress,
                    disabled: _isSaving,
                  ),

                  // Mensaje de Error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Botones de Acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: (_isSaving || _isUploadingVideo)
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (_isSaving || _isUploadingVideo) ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving || _isUploadingVideo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar ejercicio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
