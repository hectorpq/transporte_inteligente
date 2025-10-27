// lib/presentation/providers/chat_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/mensaje_model.dart';
import '../../data/repositories/chat_repository.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  List<MensajeModel> _mensajes = [];
  bool _cargando = false;
  String? _error;
  int _mensajesNoLeidos = 0;
  bool _chatAbierto = false;

  List<MensajeModel> get mensajes => _mensajes;
  bool get cargando => _cargando;
  String? get error => _error;
  int get mensajesNoLeidos => _mensajesNoLeidos;
  bool get chatAbierto => _chatAbierto;
  bool get conectado => _repository.conectado;

  ChatProvider() {
    _inicializar();
  }

  Future<void> _inicializar() async {
    await conectar();
    await cargarMensajes();
    _escucharNuevosMensajes();
  }

  Future<void> conectar() async {
    try {
      await _repository.conectar();
      notifyListeners();
    } catch (e) {
      _error = 'Error al conectar al chat: $e';
      notifyListeners();
    }
  }

  void desconectar() {
    _repository.desconectar();
    notifyListeners();
  }

  Future<void> cargarMensajes() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _mensajes = await _repository.obtenerMensajes();
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar mensajes: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> enviarMensaje(String username, String texto) async {
    if (texto.trim().isEmpty) return false;

    try {
      final mensaje = MensajeModel(
        username: username,
        mensaje: texto.trim(),
        tipo: 'general',
      );

      final enviado = await _repository.enviarMensaje(mensaje);

      if (!enviado) {
        _error = 'No se pudo enviar el mensaje';
        notifyListeners();
      }

      return enviado;
    } catch (e) {
      _error = 'Error al enviar mensaje: $e';
      notifyListeners();
      return false;
    }
  }

  void _escucharNuevosMensajes() {
    _repository.escucharNuevosMensajes((nuevoMensaje) {
      final existe = _mensajes.any((m) => m.id == nuevoMensaje.id);
      if (!existe) {
        _mensajes.add(nuevoMensaje);

        if (!_chatAbierto) {
          _mensajesNoLeidos++;
        }

        notifyListeners();
      }
    });
  }

  void abrirChat() {
    _chatAbierto = true;
    _mensajesNoLeidos = 0;
    notifyListeners();
  }

  void cerrarChat() {
    _chatAbierto = false;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    desconectar();
    super.dispose();
  }
}
