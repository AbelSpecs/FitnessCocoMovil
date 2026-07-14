import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart'; // Importamos el modelo de arriba

class AuthProvider extends ChangeNotifier {
  // Instancia del almacenamiento seguro del teléfono (Keychain/Keystore)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Variables de Estado (Equivalente a las propiedades de Zustand)
  UserAuth? _user;
  String? _token;
  bool _isInitialized = false;

  // Getters públicos para leer el estado desde las pantallas
  UserAuth? get user => _user;
  String? get token => _token;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null;

  // Constructor: Al instanciarse, lee automáticamente el disco (Equivalente a tu inicialización nativa)
  AuthProvider() {
    initAuth();
  }

  /// Inicializa y recupera la sesión asíncronamente (Equivalente al getAuth/lectura inicial)
  Future<void> initAuth() async {
    try {
      final tokenData = await _storage.read(key: "pyrosfit_token");
      final userData = await _storage.read(key: "pyrosfit_user");

      if (tokenData != null && userData != null) {
        _token = tokenData;
        _user = UserAuth.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      debugPrint("Error inicializando autenticación: $e");
    } finally {
      _isInitialized = true;
      notifyListeners(); // ⬅️ Le avisa a Flutter que redibuje si cambió algo
    }
  }

  /// Guarda la sesión en disco y actualiza el estado (Equivalente a setAuth)
  Future<void> setAuth(UserAuth user, String token) async {
    _user = user;
    _token = token;

    // Guardado seguro encriptado en el móvil (setItem)
    await _storage.write(key: "pyrosfit_token", value: token);
    await _storage.write(
        key: "pyrosfit_user", value: jsonEncode(user.toJson()));

    notifyListeners(); // Equivalente al 'set({ user, token })' de Zustand
  }

  /// Cierra la sesión borrando los datos (Equivalente a logout)
  Future<void> logout() async {
    _user = null;
    _token = null;

    // Remueve las llaves del almacenamiento seguro (removeItem)
    await _storage.delete(key: "pyrosfit_token");
    await _storage.delete(key: "pyrosfit_user");

    notifyListeners();
  }
}
