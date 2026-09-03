import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/core/models/muscle_group_model.dart';
import 'package:pyrosfitmovil/core/services/routine_service.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/core/utils/logger.dart';

class ExercisesProvider extends ChangeNotifier {
  List<ExerciseModel> _exercises = [];
  List<MuscleGroup> _muscleGroups = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedMuscleGroup = 'Todos';
  bool _onlyVideo = false;

  // Video Upload Progress
  bool _isUploadingVideo = false;
  double _uploadProgress = 0.0;
  String? _uploadStatusText;

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploadingVideo => _isUploadingVideo;
  double get uploadProgress => _uploadProgress;
  String? get uploadStatusText => _uploadStatusText;
  String get searchQuery => _searchQuery;
  String get selectedMuscleGroup => _selectedMuscleGroup;
  bool get onlyVideo => _onlyVideo;
  List<MuscleGroup> get muscleGroups => _muscleGroups;

  int get totalCount => _exercises.length;
  int get withVideoCount => _exercises.where((e) => e.hasVideo).length;
  int get withoutVideoCount => totalCount - withVideoCount;

  List<ExerciseModel> get filteredExercises {
    final query = _searchQuery.trim().toLowerCase();
    return _exercises.filter((e) {
      final matchesGroup = _selectedMuscleGroup == 'Todos' ||
          e.muscleGroup.toLowerCase() == _selectedMuscleGroup.toLowerCase();
      final matchesVideo = !_onlyVideo || e.hasVideo;
      final matchesQuery = query.isEmpty ||
          e.name.toLowerCase().contains(query) ||
          e.muscleGroup.toLowerCase().contains(query) ||
          (e.description != null && e.description!.toLowerCase().contains(query));

      return matchesGroup && matchesVideo && matchesQuery;
    }).toList();
  }

  // Load Data
  Future<void> loadData(int coachId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        RoutineService.getExerciseByCoachId(coachId),
        RoutineService.getMuscleGroups(),
      ]);

      final exercisesRaw = results[0];
      final muscleGroupsRaw = results[1];

      if (muscleGroupsRaw != null) {
        _muscleGroups = muscleGroupsRaw
            .map((item) => MuscleGroup.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (exercisesRaw != null) {
        _exercises = exercisesRaw.map((item) {
          final map = item as Map<String, dynamic>;
          // Resolver nombre del grupo muscular si no viene
          if (!map.containsKey('muscleGroup') || map['muscleGroup'] == null || map['muscleGroup'] == '') {
            final mgId = map['muscleGroupId'] as int?;
            final mg = _muscleGroups.firstWhere(
              (m) => m.id == mgId,
              orElse: () => MuscleGroup(id: mgId ?? 1, name: 'General'),
            );
            map['muscleGroup'] = mg.name;
          }
          return ExerciseModel.fromJson(map);
        }).toList();
      }
    } catch (e) {
      logError('Error cargando ejercicios en ExercisesProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search & Filter Setters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedMuscleGroup(String group) {
    _selectedMuscleGroup = group;
    notifyListeners();
  }

  void toggleOnlyVideo() {
    _onlyVideo = !_onlyVideo;
    notifyListeners();
  }

  // Video Upload
  Future<String?> uploadVideo({
    required int coachId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    int? exerciseId,
  }) async {
    _isUploadingVideo = true;
    _uploadProgress = 0.0;
    _uploadStatusText = 'Solicitando acceso a Cloudflare R2...';
    notifyListeners();

    try {
      final tempId = exerciseId ?? (DateTime.now().millisecondsSinceEpoch % 100000000);
      final presign = await StorageService.getPresignedVideoUrl(
        trainerId: coachId,
        exerciseId: tempId,
        fileName: fileName,
        contentType: contentType,
        expiresInSeconds: 600,
      );

      final uploadUrl = presign['uploadUrl'] as String;
      final videoKey = presign['key'] as String;

      _uploadStatusText = 'Subiendo video a Cloudflare R2...';
      notifyListeners();

      await StorageService.uploadVideoBytes(
        uploadUrl: uploadUrl,
        bytes: bytes,
        contentType: contentType,
        onProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      _uploadStatusText = '¡Video subido con éxito!';
      _uploadProgress = 1.0;
      notifyListeners();

      return videoKey;
    } catch (e) {
      logError('Error subiendo video de ejercicio: $e');
      _uploadStatusText = 'Error al subir video';
      return null;
    } finally {
      _isUploadingVideo = false;
      notifyListeners();
    }
  }

  // Create Exercise
  Future<bool> createExercise({
    required int coachId,
    required String name,
    required int muscleGroupId,
    String? description,
    String? videoKey,
    String? videoUrl,
    bool isCustom = true,
  }) async {
    try {
      final mgName = _muscleGroups.firstWhere(
        (m) => m.id == muscleGroupId,
        orElse: () => MuscleGroup(id: muscleGroupId, name: 'General'),
      ).name;

      final payload = {
        'exercise': {
          'coachId': coachId,
          'name': name.trim(),
          'description': description?.trim(),
          'muscleGroupId': muscleGroupId,
          'videoKey': videoKey?.trim().isNotEmpty == true ? videoKey!.trim() : null,
          'videoUrl': videoUrl?.trim().isNotEmpty == true ? videoUrl!.trim() : null,
          'isCustom': isCustom,
        }
      };

      final response = await RoutineService.postExercise(payload);
      if (response != null) {
        final newId = response['id'] ?? response['exercise']?['id'] ?? DateTime.now().millisecondsSinceEpoch;
        final newExercise = ExerciseModel(
          id: newId as int,
          coachId: coachId,
          name: name.trim(),
          description: description?.trim(),
          muscleGroupId: muscleGroupId,
          muscleGroup: mgName,
          videoKey: videoKey,
          videoUrl: videoUrl,
          isCustom: isCustom,
        );

        _exercises.insert(0, newExercise);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      logError('Error creando ejercicio: $e');
      return false;
    }
  }

  // Update Exercise
  Future<bool> updateExercise({
    required int id,
    required int coachId,
    required String name,
    required int muscleGroupId,
    String? description,
    String? videoKey,
    String? videoUrl,
    bool isCustom = true,
  }) async {
    try {
      final mgName = _muscleGroups.firstWhere(
        (m) => m.id == muscleGroupId,
        orElse: () => MuscleGroup(id: muscleGroupId, name: 'General'),
      ).name;

      final payload = {
        'exercise': {
          'coachId': coachId,
          'name': name.trim(),
          'description': description?.trim(),
          'muscleGroupId': muscleGroupId,
          'videoKey': videoKey?.trim().isNotEmpty == true ? videoKey!.trim() : null,
          'videoUrl': videoUrl?.trim().isNotEmpty == true ? videoUrl!.trim() : null,
          'isCustom': isCustom,
        }
      };

      final response = await RoutineService.updateExercise(id, payload);
      if (response != null) {
        final index = _exercises.indexWhere((e) => e.id == id);
        if (index != -1) {
          _exercises[index] = ExerciseModel(
            id: id,
            coachId: coachId,
            name: name.trim(),
            description: description?.trim(),
            muscleGroupId: muscleGroupId,
            muscleGroup: mgName,
            videoKey: videoKey,
            videoUrl: videoUrl,
            isCustom: isCustom,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      logError('Error actualizando ejercicio: $e');
      return false;
    }
  }

  // Delete Exercise
  Future<bool> deleteExercise(int id) async {
    try {
      final success = await RoutineService.deleteExercise(id);
      if (success) {
        _exercises.removeWhere((e) => e.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      logError('Error eliminando ejercicio: $e');
      return false;
    }
  }
}

extension _FilterExtension on List<ExerciseModel> {
  Iterable<ExerciseModel> filter(bool Function(ExerciseModel) test) {
    return where(test);
  }
}
