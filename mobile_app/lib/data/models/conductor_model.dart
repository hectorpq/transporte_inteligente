class Conductor {
  final String id;
  final String usuario;
  final String correo;
  final String placaVehiculo;
  final String linea;
  final bool estaActivo;
  final DateTime? fechaRegistro;

  Conductor({
    required this.id,
    required this.usuario,
    required this.correo,
    required this.placaVehiculo,
    required this.linea,
    this.estaActivo = false,
    this.fechaRegistro,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'] ?? '',
      usuario: json['usuario'] ?? '',
      correo: json['correo'] ?? '',
      placaVehiculo: json['placa_vehiculo'] ?? '',
      linea: json['linea'] ?? '',
      estaActivo: json['esta_activo'] ?? false,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': usuario,
      'correo': correo,
      'placa_vehiculo': placaVehiculo,
      'linea': linea,
      'esta_activo': estaActivo,
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }
}
