// lib/data/models/mensaje_model.dart

class MensajeModel {
  final int? id;
  final String username;
  final String mensaje;
  final int? paradaId;
  final int? rutaId;
  final String tipo;
  final DateTime fechaEnvio;

  MensajeModel({
    this.id,
    required this.username,
    required this.mensaje,
    this.paradaId,
    this.rutaId,
    this.tipo = 'general',
    DateTime? fechaEnvio,
  }) : fechaEnvio = fechaEnvio ?? DateTime.now();

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'],
      username: json['username'],
      mensaje: json['mensaje'],
      paradaId: json['parada_id'],
      rutaId: json['ruta_id'],
      tipo: json['tipo'] ?? 'general',
      fechaEnvio: DateTime.parse(json['fecha_envio']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'mensaje': mensaje,
      'parada_id': paradaId,
      'ruta_id': rutaId,
      'tipo': tipo,
    };
  }

  MensajeModel copyWith({
    int? id,
    String? username,
    String? mensaje,
    int? paradaId,
    int? rutaId,
    String? tipo,
    DateTime? fechaEnvio,
  }) {
    return MensajeModel(
      id: id ?? this.id,
      username: username ?? this.username,
      mensaje: mensaje ?? this.mensaje,
      paradaId: paradaId ?? this.paradaId,
      rutaId: rutaId ?? this.rutaId,
      tipo: tipo ?? this.tipo,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
    );
  }
}
