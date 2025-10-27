// lib/data/models/parada_model.dart

class ParadaModel {
  final int id;
  final String nombre;
  final double latitud;
  final double longitud;
  final String? direccion;
  final bool esPrincipal;

  ParadaModel({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.esPrincipal = false,
  });

  factory ParadaModel.fromJson(Map<String, dynamic> json) {
    return ParadaModel(
      id: json['id'],
      nombre: json['nombre'],
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      direccion: json['direccion'],
      esPrincipal: json['es_parada_principal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'es_parada_principal': esPrincipal,
    };
  }
}
