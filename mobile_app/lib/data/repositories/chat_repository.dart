// lib/data/repositories/chat_repository.dart

import '../models/mensaje_model.dart';
import '../../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService = ChatService();

  Future<void> conectar() async {
    await _chatService.conectar();
  }

  void desconectar() {
    _chatService.desconectar();
  }

  Future<List<MensajeModel>> obtenerMensajes({
    String tipo = 'general',
    int limite = 50,
  }) async {
    return await _chatService.obtenerMensajes(tipo: tipo, limite: limite);
  }

  Future<bool> enviarMensaje(MensajeModel mensaje) async {
    return await _chatService.enviarMensaje(mensaje);
  }

  void escucharNuevosMensajes(Function(MensajeModel) callback) {
    _chatService.agregarListener(callback);
  }

  void dejarDeEscuchar(Function(MensajeModel) callback) {
    _chatService.removerListener(callback);
  }

  bool get conectado => _chatService.conectado;
}
