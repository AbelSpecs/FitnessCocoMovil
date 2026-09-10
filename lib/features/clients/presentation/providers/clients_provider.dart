import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/globals.dart';
import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/core/services/coach_service.dart';
import 'package:pyrosfitmovil/core/services/student_service.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';

class ClientsProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  
  List<StudentInfo> _clients = [];
  bool _isLoading = false;
  String _searchQuery = '';

  ClientsProvider(this.authProvider) {
    _loadClients();
  }

  List<StudentInfo> get clients => _clients;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<StudentInfo> get filteredClients {
    if (_searchQuery.trim().isEmpty) return _clients;
    final query = _searchQuery.trim().toLowerCase();
    return _clients.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.fitnessGoal.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadClients() async {
    final coachId = authProvider.user?.coachId;
    if (coachId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        CoachService.getCoachStudents(coachId),
        StudentService.getAllStudents(),
      ]);

      final rawCoachStudents = results[0];
      final rawAllStudents = results[1];

      final Map<int, int> studentToUserMap = {};
      if (rawAllStudents != null) {
        for (final item in rawAllStudents) {
          if (item is Map) {
            final sId = item['id'] as int? ?? item['studentId'] as int?;
            final uId = item['userId'] as int? ?? (item['user'] is Map ? item['user']['id'] as int? : null);
            if (sId != null && uId != null) {
              studentToUserMap[sId] = uId;
            }
          }
        }
      }

      if (rawCoachStudents != null) {
        _clients = rawCoachStudents.map((e) {
          final student = StudentInfo.fromJson(e as Map<String, dynamic>);
          final resolvedUserId = student.userId ?? studentToUserMap[student.studentId];
          if (resolvedUserId != null && (student.profilePictureUrl == null || student.profilePictureUrl!.isEmpty)) {
            return student.copyWith(
              userId: resolvedUserId,
              profilePictureUrl: StorageService.getUserProfileUrl(resolvedUserId),
            );
          }
          return student.copyWith(userId: resolvedUserId);
        }).toList();
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al cargar la lista de clientes.'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error loading clients: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  Future<void> refresh() async {
    await _loadClients();
  }
}
