// lib/config/constants.dart

class AppConstants {
  // ════════════════════════════════════════════════════════
  // 🚀 PRODUCCIÓN - API EN VERCEL
  // ════════════════════════════════════════════════════════
  //static const String baseUrl = 'https://trasporte-inteligente.vercel.app';
  //static const String wsUrl = 'wss://trasporte-inteligente.vercel.app';

  // ════════════════════════════════════════════════════════
  // 🧪 DESARROLLO - API LOCAL (comentado)
  // ════════════════════════════════════════════════════════
  static const String baseUrl = 'http://192.168.0.105:3000';
  static const String wsUrl = 'ws://192.168.0.105:3000';

  // ════════════════════════════════════════════════════════
  // ENDPOINTS
  // ════════════════════════════════════════════════════════
  static const String busesEndpoint = '/api/buses';
  static const String rutasEndpoint = '/api/rutas';
  static const String chatEndpoint = '/api/chat';
  static const String busesCercanosEndpoint = '/api/buses/cercanos';

  // ════════════════════════════════════════════════════════
  // ✅ MAPA CENTRADO EN JULIACA (Línea 18)
  // ════════════════════════════════════════════════════════
  static const double defaultZoom = 13.5;
  static const double defaultLat = -15.4800; // JULIACA
  static const double defaultLng = -70.1450; // JULIACA

  // ════════════════════════════════════════════════════════
  // CHAT
  // ════════════════════════════════════════════════════════
  static const int maxMensajes = 50;
  static const int maxCaracteresMensaje = 500;

  // ════════════════════════════════════════════════════════
  // INTERVALOS DE ACTUALIZACIÓN
  // ════════════════════════════════════════════════════════
  static const int updateIntervalBuses = 3;
  static const int updateIntervalLocation = 5;

  // ════════════════════════════════════════════════════════
  // BÚSQUEDA
  // ════════════════════════════════════════════════════════
  static const double radioBusqueda = 5.0;
}
