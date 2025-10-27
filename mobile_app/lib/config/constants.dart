// lib/config/constants.dart

class AppConstants {
  // Configuración para dispositivo físico
  static const String baseUrl = 'http://192.168.0.105:3000';
  static const String wsUrl = 'ws://192.168.0.105:3000';

  // Endpoints
  static const String busesEndpoint = '/api/buses';
  static const String rutasEndpoint = '/api/rutas';
  static const String chatEndpoint = '/api/chat';
  static const String busesCercanosEndpoint = '/api/buses/cercanos';

  // ✅ Mapa centrado en JULIACA (Línea 18)
  static const double defaultZoom = 13.5;
  static const double defaultLat = -15.4800; // ← JULIACA
  static const double defaultLng = -70.1450; // ← JULIACA

  // Chat
  static const int maxMensajes = 50;
  static const int maxCaracteresMensaje = 500;

  // Intervalos
  static const int updateIntervalBuses = 3;
  static const int updateIntervalLocation = 5;

  // Búsqueda
  static const double radioBusqueda = 5.0;
}
