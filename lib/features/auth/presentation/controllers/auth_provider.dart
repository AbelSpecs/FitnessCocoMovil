import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/core/services/user_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pyrosfitmovil/features/auth/data/models/user_auth_model.dart'; // Importamos el modelo de arriba

class AuthProvider extends ChangeNotifier {
  // Configuración de opciones para iOS y Android
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  );

  static const AndroidOptions _androidOptions = AndroidOptions(
    resetOnError: true,
  );

  // Instancia del almacenamiento seguro del teléfono (Keychain/Keystore)
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  /// Escritura segura con borrado previo o sobreescritura para evitar colisiones en iOS Keychain (-25299)
  static Future<void> _safeWrite(String key, String value) async {
    try {
      // 1. Borrado previo explícito para asegurar que el ítem no exista duplicado en iOS Keychain
      await _storage.delete(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (_) {}

    try {
      // 2. Escritura con las opciones de iOS configuradas
      await _storage.write(
        key: key,
        value: value,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      debugPrint("Aviso en secure storage ($key): $e. Reintentando tras borrado.");
      try {
        await _storage.delete(
          key: key,
          iOptions: _iosOptions,
          aOptions: _androidOptions,
        );
        await _storage.write(
          key: key,
          value: value,
          iOptions: _iosOptions,
          aOptions: _androidOptions,
        );
      } catch (retryError) {
        debugPrint("Fallo crítico en secure storage ($key): $retryError");
        rethrow;
      }
    }
  }

  /// Lectura segura con opciones de iOS
  static Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      debugPrint("Error leyendo secure storage ($key): $e");
      return null;
    }
  }

  /// Borrado seguro con opciones de iOS
  static Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      debugPrint("Error borrando en secure storage ($key): $e");
    }
  }

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
    if (_isInitialized && _token != null) return;
    try {
      final tokenData = await _safeRead("pyrosfit_token");
      final userData = await _safeRead("pyrosfit_user");

      if (tokenData != null && userData != null) {
        _token = tokenData;
        _user = UserAuth.fromJson(jsonDecode(userData));
        // Sincronizar en segundo plano fotos y detalles actualizados
        refreshUserProfile();
      }
    } catch (e) {
      debugPrint("Error inicializando autenticación: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Guarda la sesión en disco y actualiza el estado (Equivalente a setAuth)
  Future<void> setAuth(UserAuth user, String token) async {
    _user = user;
    _token = token;

    // Guardado seguro encriptado en el móvil (setItem)
    await _safeWrite("pyrosfit_token", token);
    await _safeWrite("pyrosfit_user", jsonEncode(user.toJson()));

    notifyListeners(); // Equivalente al 'set({ user, token })' de Zustand
  }

  /// Cierra la sesión borrando los datos (Equivalente a logout)
  Future<void> logout() async {
    _user = null;
    _token = null;

    // Remueve las llaves del almacenamiento seguro (removeItem)
    await _safeDelete("pyrosfit_token");
    await _safeDelete("pyrosfit_user");

    notifyListeners();
  }

  /// Actualiza la foto de perfil del usuario en memoria y en disco
  Future<void> updateProfilePicture(String key, String? url) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      profilePictureKey: key,
      profilePictureUrl: url,
    );
    await _safeWrite("pyrosfit_user", jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  /// Actualiza la foto de banner del usuario en memoria y en disco
  Future<void> updateBannerPicture(String key, String? url) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      bannerPictureKey: key,
      bannerPictureUrl: url,
    );
    await _safeWrite("pyrosfit_user", jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  /// Sincroniza los datos más recientes del usuario desde el servidor
  Future<void> refreshUserProfile() async {
    if (_user == null) return;
    try {
      Map<String, dynamic>? data;
      try {
        final details = await UserService.getUserDetails(_user!.id.toString());
        data = details['data'] as Map<String, dynamic>?;
      } catch (_) {}

      if (data == null) {
        try {
          final base = await UserService.getUser(_user!.id.toString());
          data = base['data'] as Map<String, dynamic>?;
        } catch (_) {}
      }
      if (data != null) {
        final coach = data['coach'] as Map<String, dynamic>?;
        final student = data['student'] as Map<String, dynamic>?;

        final profileKey = (data['profilePictureKey'] ??
            data['profilePicture'] ??
            coach?['profilePictureKey'] ??
            coach?['profilePicture'] ??
            student?['profilePictureKey'] ??
            student?['profilePicture']) as String?;

        final bannerKey = (coach?['bannerPictureKey'] ??
            coach?['bannerPicture'] ??
            coach?['bannerUrl'] ??
            data['bannerPictureKey'] ??
            data['bannerPicture']) as String?;

        final profileUrl = profileKey != null && profileKey.isNotEmpty
            ? StorageService.getServeUrl(profileKey)
            : null;
        final bannerUrl = bannerKey != null && bannerKey.isNotEmpty
            ? StorageService.getServeUrl(bannerKey)
            : null;

        _user = _user!.copyWith(
          profilePictureKey: profileKey,
          profilePictureUrl: profileUrl,
          bannerPictureKey: bannerKey,
          bannerPictureUrl: bannerUrl,
        );

        await _safeWrite("pyrosfit_user", jsonEncode(_user!.toJson()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refrescando perfil en AuthProvider: $e");
    }
  }

}
