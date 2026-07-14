import 'package:logger/logger.dart';

/// Instancia global y privada del logger configurado.
/// Usa el PrettyPrinter para que los logs sean fáciles de leer y tengan colores.
final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,           // Cantidad de llamadas a métodos que se mostrarán
    errorMethodCount: 8,      // Cantidad de llamadas si se provee un stacktrace
    lineLength: 100,          // Ancho de la salida
    colors: true,             // Mensajes de log con colores (útil en consola)
    printEmojis: true,        // Imprimir un emoji para cada mensaje
    // dateTimeFormat: DateTimeFormat.none, // Ocultar timestamp
  ),
  // DevelopmentFilter hace que los logs no se impriman en producción (Release mode)
  filter: DevelopmentFilter(),
);

/// Log de información general.
/// Útil para ver el flujo normal de la aplicación.
void logInfo(dynamic message, {Object? error, StackTrace? stackTrace}) {
  _logger.i(message, error: error, stackTrace: stackTrace);
}

/// Log de errores.
/// Útil para capturar excepciones o flujos fallidos.
void logError(dynamic message, {Object? error, StackTrace? stackTrace}) {
  _logger.e(message, error: error, stackTrace: stackTrace);
}

/// Log de advertencias.
/// Útil para estados inesperados que no detienen la aplicación.
void logWarn(dynamic message, {Object? error, StackTrace? stackTrace}) {
  _logger.w(message, error: error, stackTrace: stackTrace);
}

/// Log de depuración.
/// Útil para imprimir variables o estados específicos durante el desarrollo.
void logDebug(dynamic message, {Object? error, StackTrace? stackTrace}) {
  _logger.d(message, error: error, stackTrace: stackTrace);
}

/// Log de rastreo (Trace).
/// Útil para seguir la ejecución paso a paso con gran detalle.
void logTrace(dynamic message, {Object? error, StackTrace? stackTrace}) {
  _logger.t(message, error: error, stackTrace: stackTrace);
}

/// Log de fallos fatales (Fatal).
/// Útil para errores críticos de los que la aplicación no puede recuperarse.
void logFatal(dynamic message, {Object? error, StackTrace? stackTrace}) {
  _logger.f(message, error: error, stackTrace: stackTrace);
}
