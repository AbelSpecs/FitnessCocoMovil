import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:pyrosfitmovil/core/router/route_tree.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _logger = Logger();

/// Manejador de mensajes en segundo plano (requiere ser función de nivel superior con @pragma)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logger.i('Mensaje en segundo plano recibido: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pyrosfit_high_importance_channel',
    'Notificaciones de PyrosFit',
    description: 'Canal principal para notificaciones de rutinas y recordatorios',
    importance: Importance.max,
    playSound: true,
  );

  /// Inicializa los escuchadores de Firebase Messaging y Notificaciones Locales
  static Future<void> initialize() async {
    try {
      // 1. Manejador en segundo plano
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Solicitar permisos de notificación (Android 13+ e iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i('Estado de permisos de notificación: ${settings.authorizationStatus}');

      // 3. Inicializar Notificaciones Locales para Banners en Primer Plano (Foreground)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              _handleRouting(data);
            } catch (e) {
              _logger.e('Error al procesar payload de notificación local: $e');
            }
          }
        },
      );

      // Crear el canal en Android
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlatform?.createNotificationChannel(_channel);

      // 4. Configurar presentación en primer plano para iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Escuchar notificaciones cuando la app está abierta (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.i('Push recibido en primer plano: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 6. Escuchar cuando el usuario pulsa la notificación en segundo plano
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _logger.i('Push pulsado en segundo plano: ${message.data}');
        _handleRouting(message.data);
      });

      // 7. Si la app fue lanzada al pulsar una notificación estando cerrada (Terminated)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _logger.i('App abierta desde estado cerrado vía Push: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleRouting(initialMessage.data);
        });
      }

      // 8. Escuchar renovación automática del token FCM
      _fcm.onTokenRefresh.listen((newToken) {
        _logger.i('FCM Token renovado');
        syncTokenWithBackend(tokenOverride: newToken);
      });
    } catch (e) {
      _logger.e('Error inicializando NotificationService: $e');
    }
  }

  /// Muestra banner emergente local cuando llega un mensaje con la app en primer plano
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Redirección inteligente al pulsar la notificación según el caso de uso
  static void _handleRouting(Map<String, dynamic> data) {
    final type = data['type'];
    _logger.i('Procesando Deep Link para type: $type');

    if (type == 'new_routine' || type == 'new_daily_exercise') {
      final studentId = data['studentId'];
      final dayId = data['dayId'];
      if (studentId != null && dayId != null) {
        AppRouter.router.push('/rutina/$studentId/$dayId');
      } else if (studentId != null) {
        AppRouter.router.push('/rutina/$studentId');
      }
    } else if (type == 'coach_pending_routines') {
      AppRouter.router.go('/clientes');
    }
  }

  /// Sincroniza el FCM Token del teléfono con el Backend
  static Future<void> syncTokenWithBackend({int? userId, String? tokenOverride}) async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        int attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await _fcm.getAPNSToken();
          attempts++;
        }
        _logger.i('Estado APNs Token iOS: ${apnsToken != null ? "obtenido ($attempts intentos)" : "no disponible aún"}');
      }

      final token = tokenOverride ?? await _fcm.getToken();
      if (token == null || token.isEmpty) {
        _logger.w('No se pudo obtener el token de FCM');
        return;
      }

      int? targetUserId = userId;
      if (targetUserId == null) {
        try {
          const storage = FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: true),
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          );
          final userData = await storage.read(key: "pyrosfit_user");
          if (userData != null && userData.isNotEmpty) {
            final decoded = jsonDecode(userData);
            targetUserId = decoded['id'];
          }
        } catch (_) {}
      }

      if (targetUserId == null) {
        _logger.w('No hay userId disponible para asociar el token FCM');
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      _logger.i('Enviando token al backend (userId: $targetUserId, $platform): $token');

      await ApiClient.instance.post(
        '/Notifications/register-token',
        data: {
          'userId': targetUserId,
          'fcmToken': token,
          'platform': platform,
          'deviceModel': Platform.isAndroid ? 'Android' : 'iOS',
        },
      );
      _logger.i('Token FCM registrado exitosamente en el servidor');
    } on DioException catch (e) {
      _logger.w('Aviso al registrar token en el backend: ${e.response?.data ?? e.message}');
    } catch (e) {
      _logger.e('Error inesperado al sincronizar token FCM: $e');
    }
  }

  /// Desvincula el token al cerrar sesión (Logout)
  static Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      _logger.i('Desregistrando token FCM en el servidor...');
      await ApiClient.instance.delete(
        '/Notifications/remove-token',
        data: {
          'fcmToken': token,
        },
      );
      _logger.i('Token FCM desregistrado exitosamente');
    } catch (e) {
      _logger.w('Aviso al desregistrar token: $e');
    }
  }
}
