// lib/services/socket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final Map<String, List<Function>> _listeners = {};

  // Conectar al WebSocket
  Future<void> conectar() async {
    if (_socket?.connected ?? false) {
      print('✅ Socket ya está conectado');
      return;
    }

    _socket = IO.io(
      AppConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ WebSocket conectado');
    });

    _socket!.onDisconnect((_) {
      print('❌ WebSocket desconectado');
    });

    _socket!.onError((error) {
      print('❌ Error en WebSocket: $error');
    });

    // Configurar listeners de eventos
    _configurarEventos();
  }

  void _configurarEventos() {
    // Evento: buses-init (buses iniciales al conectar)
    _socket!.on('buses-init', (data) {
      _notificarListeners('buses-init', data);
    });

    // Evento: bus-update (actualización de un bus)
    _socket!.on('bus-update', (data) {
      _notificarListeners('bus-update', data);
    });

    // Evento: bus-ruta-update (actualización de bus en ruta)
    _socket!.on('bus-ruta-update', (data) {
      _notificarListeners('bus-ruta-update', data);
    });
  }

  // Agregar listener para un evento
  void on(String evento, Function callback) {
    if (!_listeners.containsKey(evento)) {
      _listeners[evento] = [];
    }
    _listeners[evento]!.add(callback);
  }

  // Remover listener
  void off(String evento, Function callback) {
    _listeners[evento]?.remove(callback);
  }

  // Notificar a todos los listeners de un evento
  void _notificarListeners(String evento, dynamic data) {
    if (_listeners.containsKey(evento)) {
      for (var listener in _listeners[evento]!) {
        listener(data);
      }
    }
  }

  // Suscribirse a una ruta específica
  void suscribirseARuta(int rutaId) {
    _socket?.emit('suscribir-ruta', rutaId);
    print('📍 Suscrito a ruta $rutaId');
  }

  // Desuscribirse de una ruta
  void desuscribirseDeRuta(int rutaId) {
    _socket?.emit('desuscribir-ruta', rutaId);
    print('🔌 Desuscrito de ruta $rutaId');
  }

  // Desconectar
  void desconectar() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listeners.clear();
    print('🔌 Socket desconectado y limpiado');
  }

  bool get conectado => _socket?.connected ?? false;
}
