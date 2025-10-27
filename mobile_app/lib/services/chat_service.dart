// lib/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';
import '../data/models/mensaje_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  IO.Socket? _socket;
  final List<Function(MensajeModel)> _listeners = [];

  Future<void> conectar() async {
    if (_socket?.connected ?? false) return;

    _socket = IO.io(
      AppConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Chat WebSocket conectado');
    });

    _socket!.on('nuevo-mensaje', (data) {
      try {
        final mensaje = MensajeModel.fromJson(data);
        _notificarListeners(mensaje);
      } catch (e) {
        print('❌ Error al procesar mensaje: $e');
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Chat WebSocket desconectado');
    });
  }

  void desconectar() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<List<MensajeModel>> obtenerMensajes({
    String tipo = 'general',
    int limite = 50,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.chatEndpoint}/mensajes?tipo=$tipo&limite=$limite',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> mensajesJson = data['data'];
          return mensajesJson
              .map((json) => MensajeModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error al obtener mensajes: $e');
      return [];
    }
  }

  Future<bool> enviarMensaje(MensajeModel mensaje) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.chatEndpoint}/enviar',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mensaje.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      return false;
    }
  }

  void agregarListener(Function(MensajeModel) callback) {
    _listeners.add(callback);
  }

  void removerListener(Function(MensajeModel) callback) {
    _listeners.remove(callback);
  }

  void _notificarListeners(MensajeModel mensaje) {
    for (var listener in _listeners) {
      listener(mensaje);
    }
  }

  bool get conectado => _socket?.connected ?? false;
}
