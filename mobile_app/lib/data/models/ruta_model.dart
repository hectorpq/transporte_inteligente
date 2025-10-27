// lib/data/models/ruta_model.dart

class RutaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? color;
  final double? tarifa;
  final bool activo;

  RutaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.color,
    this.tarifa,
    this.activo = true,
  });

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    return RutaModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      color: json['color'],
      tarifa: json['tarifa'] != null
          ? double.parse(json['tarifa'].toString())
          : null,
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'tarifa': tarifa,
      'activo': activo,
    };
  }
}
