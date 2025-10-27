// lib/data/models/bus_model.dart

class BusModel {
  final int busId;
  final String? placa;
  final int? rutaId;
  final String? rutaNombre;
  final dynamic latitud;
  final dynamic longitud;
  final dynamic velocidad;
  final dynamic direccion;
  final String? estado;
  final DateTime? ultimaActualizacion;

  BusModel({
    required this.busId,
    this.placa,
    this.rutaId,
    this.rutaNombre,
    this.latitud,
    this.longitud,
    this.velocidad,
    this.direccion,
    this.estado,
    this.ultimaActualizacion,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busId: json['bus_id'] ?? 0,
      placa: json['placa'],
      rutaId: json['ruta_id'],
      rutaNombre: json['ruta_nombre'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      velocidad: json['velocidad'],
      direccion: json['direccion'],
      estado: json['estado'],
      ultimaActualizacion: json['ultima_actualizacion'] != null
          ? DateTime.parse(json['ultima_actualizacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_id': busId,
      'placa': placa,
      'ruta_id': rutaId,
      'ruta_nombre': rutaNombre,
      'latitud': latitud,
      'longitud': longitud,
      'velocidad': velocidad,
      'direccion': direccion,
      'estado': estado,
    };
  }

  BusModel copyWith({
    int? busId,
    String? placa,
    int? rutaId,
    String? rutaNombre,
    dynamic latitud,
    dynamic longitud,
    dynamic velocidad,
    dynamic direccion,
    String? estado,
    DateTime? ultimaActualizacion,
  }) {
    return BusModel(
      busId: busId ?? this.busId,
      placa: placa ?? this.placa,
      rutaId: rutaId ?? this.rutaId,
      rutaNombre: rutaNombre ?? this.rutaNombre,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      velocidad: velocidad ?? this.velocidad,
      direccion: direccion ?? this.direccion,
      estado: estado ?? this.estado,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}
