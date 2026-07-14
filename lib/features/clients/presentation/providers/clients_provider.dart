import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/models/student_info_model.dart';
import 'package:pyrosfitmovil/core/services/coach_service.dart';
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
      final rawData = await CoachService.getCoachStudents(coachId);
      if (rawData != null) {
        _clients = rawData.map((e) => StudentInfo.fromJson(e)).toList();
      }
    } catch (e) {
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
