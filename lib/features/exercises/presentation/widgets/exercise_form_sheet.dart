import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/controllers/exercises_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ExerciseFormSheet extends StatefulWidget {
  final ExerciseModel? exercise; // Si es null => modo creación

  const ExerciseFormSheet({super.key, this.exercise});

  static void show(BuildContext context, {ExerciseModel? exercise}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExerciseFormSheet(exercise: exercise),
    );
  }

  @override
  State<ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<ExerciseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _youtubeController;

  int _selectedMuscleGroupId = 1;
  int _videoMode = 0; // 0: Archivo R2, 1: Enlace YouTube
  bool _isCustom = true;

  // Selected file
  XFile? _selectedVideo;
  Uint8List? _videoBytes;
  int _fileSizeBytes = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _descController = TextEditingController(text: ex?.description ?? '');

    final existingUrl = ex?.videoUrl ?? '';
    final isYt = existingUrl.contains('youtu');
    _youtubeController = TextEditingController(text: isYt ? existingUrl : '');
    _selectedMuscleGroupId = ex?.muscleGroupId ?? 1;
    _isCustom = ex?.isCustom ?? true;
    _videoMode = isYt ? 1 : 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final bytes = await video.readAsBytes();
        setState(() {
          _selectedVideo = video;
          _videoBytes = bytes;
          _fileSizeBytes = bytes.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar el video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = context.read<AuthProvider>().user;
    final coachId = authUser?.coachId ?? authUser?.id ?? 1;
    final exProvider = context.read<ExercisesProvider>();

    setState(() => _isSaving = true);

    String? finalVideoKey = widget.exercise?.videoKey;
    String? finalVideoUrl = widget.exercise?.videoUrl;

    try {
      // 1. Si eligió subir un archivo de video
      if (_videoMode == 0 && _selectedVideo != null && _videoBytes != null) {
        final ext = _selectedVideo!.name.split('.').last.toLowerCase();
        final contentType = ext == 'mp4' ? 'video/mp4' : (ext == 'mov' ? 'video/quicktime' : 'video/webm');

        final uploadedKey = await exProvider.uploadVideo(
          coachId: coachId,
          fileName: _selectedVideo!.name,
          bytes: _videoBytes!,
          contentType: contentType,
          exerciseId: widget.exercise?.id,
        );

        if (uploadedKey != null) {
          finalVideoKey = uploadedKey;
          finalVideoUrl = uploadedKey;
        }
      } else if (_videoMode == 1) {
        final ytUrl = _youtubeController.text.trim();
        if (ytUrl.isNotEmpty) {
          finalVideoKey = ytUrl;
          finalVideoUrl = ytUrl;
        }
      }

      bool success = false;
      if (widget.exercise != null) {
        // Edit mode
        success = await exProvider.updateExercise(
          id: widget.exercise!.id,
          coachId: coachId,
          name: _nameController.text.trim(),
          muscleGroupId: _selectedMuscleGroupId,
          description: _descController.text.trim(),
          videoKey: finalVideoKey,
          videoUrl: finalVideoUrl,
          isCustom: _isCustom,
        );
      } else {
        // Create mode
        success = await exProvider.createExercise(
          coachId: coachId,
          name: _nameController.text.trim(),
          muscleGroupId: _selectedMuscleGroupId,
          description: _descController.text.trim(),
          videoKey: finalVideoKey,
          videoUrl: finalVideoUrl,
          isCustom: _isCustom,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.exercise != null ? 'Ejercicio actualizado' : 'Ejercicio creado con éxito'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar el ejercicio en el servidor'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exProvider = context.watch<ExercisesProvider>();
    final muscleGroups = exProvider.muscleGroups;
    final isEditing = widget.exercise != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              const SizedBox(height: 18),

              // Title
              Text(
                isEditing ? 'Editar Ejercicio' : 'Nuevo Ejercicio',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Registra el ejercicio y añade un video demostrativo para tus alumnos.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 20),

              // Nombre del Ejercicio
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nombre del Ejercicio *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.fitness_center_rounded, color: AppTheme.primaryGlow, size: 18),
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
                validator: (val) => (val == null || val.trim().isEmpty) ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 16),

              // Selector de Grupo Muscular
              const Text('Grupo Muscular', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: muscleGroups.any((m) => m.id == _selectedMuscleGroupId)
                        ? _selectedMuscleGroupId
                        : (muscleGroups.isNotEmpty ? muscleGroups.first.id : 1),
                    dropdownColor: const Color(0xFF18181B),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGlow),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: muscleGroups.map((mg) {
                      return DropdownMenuItem<int>(
                        value: mg.id,
                        child: Text(mg.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMuscleGroupId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Tipo de Video (Segmented Switch)
              const Text('Video Demostrativo', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _videoMode = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _videoMode == 0 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 15,
                                color: _videoMode == 0 ? Colors.white : Colors.white60,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Subir Video',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _videoMode == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _videoMode == 0 ? Colors.white : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _videoMode = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _videoMode == 1 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 15,
                                color: _videoMode == 1 ? Colors.white : Colors.white60,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'YouTube',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _videoMode == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _videoMode == 1 ? Colors.white : Colors.white60,
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
              const SizedBox(height: 12),

              // Contenido según modo de video
              if (_videoMode == 0) ...[
                // Subir Archivo de Video a R2
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedVideo != null ? AppTheme.primary : AppTheme.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.video_file_outlined, color: AppTheme.primaryGlow, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedVideo != null
                                    ? _selectedVideo!.name
                                    : (widget.exercise?.hasVideo == true ? 'Conservar video actual' : 'Seleccionar video de la galería'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _fileSizeBytes > 0
                                    ? '${(_fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
                                    : 'Formatos soportados: MP4, MOV, WEBM (hasta 50MB)',
                                style: const TextStyle(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _pickVideo,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGlow,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(_selectedVideo != null ? 'Cambiar' : 'Elegir'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Barra de Progreso de Subida
                if (exProvider.isUploadingVideo) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exProvider.uploadStatusText ?? 'Subiendo a Cloudflare R2...',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryGlow),
                          ),
                          Text(
                            '${(exProvider.uploadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: exProvider.uploadProgress,
                        backgroundColor: Colors.white12,
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Input de Enlace de YouTube
                TextFormField(
                  controller: _youtubeController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Enlace de YouTube',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'https://www.youtube.com/watch?v=...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    prefixIcon: const Icon(Icons.smart_display_outlined, color: Colors.redAccent, size: 18),
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
                ),
              ],
              const SizedBox(height: 16),

              // Descripción y Técnica
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Descripción / Técnica recomendada',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Explica la postura, respiración o consejos...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
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
              ),
              const SizedBox(height: 12),

              // Switch Ejercicio Personalizado
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ejercicio personalizado', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text('Visible en tu biblioteca técnica de entrenador', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: _isCustom,
                activeTrackColor: AppTheme.primary,
                onChanged: (val) => setState(() => _isCustom = val),
              ),
              const SizedBox(height: 20),

              // Botones Guardar / Cancelar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Guardar Cambios' : 'Crear Ejercicio', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
