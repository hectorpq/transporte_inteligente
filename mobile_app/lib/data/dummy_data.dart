// lib/data/dummy_data.dart

import 'dart:math'; // 🆕 IMPORTAR dart:math
import 'package:latlong2/latlong.dart';
import 'models/ruta_model.dart';
import 'models/bus_model.dart';

class DummyData {
  // 🚌 RUTAS DE PRUEBA (Línea 18 de Juliaca)
  static List<RutaModel> get rutasPrueba => [
        // LÍNEA 18
        RutaModel(
          id: 1,
          nombre: 'Línea 18',
          descripcion: 'Terminal Terrestre - Plaza de Armas',
          color: '#FF9800',
          tarifa: 1.50,
          activo: true,
          // IDA: Terminal → Plaza de Armas
          coordinadasIda: [
            LatLng(-15.48432470, -70.14240518), // Terminal Terrestre
            LatLng(-15.48350000, -70.14180000), // Av. Circunvalación
            LatLng(-15.48200000, -70.14100000), // Hospital Carlos Monge
            LatLng(-15.48000000, -70.14000000), // Universidad Nacional
            LatLng(-15.47800000, -70.13900000), // Mercado Central
            LatLng(-15.47475785, -70.13800000), // Plaza de Armas
          ],
          // VUELTA: Plaza de Armas → Terminal
          coordinadasVuelta: [
            LatLng(-15.47475785, -70.13800000), // Plaza de Armas
            LatLng(-15.47650000, -70.13850000), // Calle San Martín
            LatLng(-15.47900000, -70.13950000), // Parque Pino
            LatLng(-15.48100000, -70.14050000), // Estadio Torres Belón
            LatLng(-15.48300000, -70.14150000), // Mercado Tupac Amaru
            LatLng(-15.48432470, -70.14240518), // Terminal Terrestre
          ],
        ),

        // LÍNEA 5 (ejemplo adicional)
        RutaModel(
          id: 2,
          nombre: 'Línea 5',
          descripcion: 'Santa Adriana - La Rinconada',
          color: '#4CAF50',
          tarifa: 1.50,
          activo: true,
          coordinadasIda: [
            LatLng(-15.49000000, -70.14500000),
            LatLng(-15.48500000, -70.14000000),
            LatLng(-15.48000000, -70.13500000),
            LatLng(-15.47500000, -70.13000000),
          ],
          coordinadasVuelta: [
            LatLng(-15.47500000, -70.13000000),
            LatLng(-15.48000000, -70.13500000),
            LatLng(-15.48500000, -70.14000000),
            LatLng(-15.49000000, -70.14500000),
          ],
        ),

        // LÍNEA 40 (ejemplo adicional)
        RutaModel(
          id: 3,
          nombre: 'Línea 40',
          descripcion: 'Salcedo - Aeropuerto',
          color: '#2196F3',
          tarifa: 2.00,
          activo: true,
          coordinadasIda: [
            LatLng(-15.48000000, -70.15000000),
            LatLng(-15.47500000, -70.14500000),
            LatLng(-15.47000000, -70.14000000),
            LatLng(-15.46500000, -70.13500000),
          ],
          coordinadasVuelta: [
            LatLng(-15.46500000, -70.13500000),
            LatLng(-15.47000000, -70.14000000),
            LatLng(-15.47500000, -70.14500000),
            LatLng(-15.48000000, -70.15000000),
          ],
        ),
      ];

  // 🚌 BUSES DE PRUEBA
  static List<BusModel> get busesPrueba => [
        // Buses de Línea 18 - IDA
        BusModel(
          busId: 1,
          placa: 'T1A-987',
          rutaId: 1,
          rutaNombre: 'Línea 18',
          latitud: '-15.48432470',
          longitud: '-70.14240518',
          velocidad: '22.66',
          direccion: 330,
          estado: 'activo',
          sentido: 'ida',
        ),
        BusModel(
          busId: 2,
          placa: 'T2B-456',
          rutaId: 1,
          rutaNombre: 'Línea 18',
          latitud: '-15.48200000',
          longitud: '-70.14100000',
          velocidad: '23.25',
          direccion: 316,
          estado: 'activo',
          sentido: 'ida',
        ),

        // Buses de Línea 18 - VUELTA
        BusModel(
          busId: 3,
          placa: 'T3C-123',
          rutaId: 1,
          rutaNombre: 'Línea 18',
          latitud: '-15.47475785',
          longitud: '-70.13800000',
          velocidad: '28.15',
          direccion: 144,
          estado: 'activo',
          sentido: 'vuelta',
        ),
        BusModel(
          busId: 4,
          placa: 'T4D-789',
          rutaId: 1,
          rutaNombre: 'Línea 18',
          latitud: '-15.47900000',
          longitud: '-70.13950000',
          velocidad: '22.08',
          direccion: 150,
          estado: 'activo',
          sentido: 'vuelta',
        ),

        // Bus de Línea 5 - IDA
        BusModel(
          busId: 5,
          placa: 'T5E-321',
          rutaId: 2,
          rutaNombre: 'Línea 5',
          latitud: '-15.48500000',
          longitud: '-70.14000000',
          velocidad: '28.70',
          direccion: 180,
          estado: 'activo',
          sentido: 'ida',
        ),

        // Bus de Línea 40 - IDA
        BusModel(
          busId: 6,
          placa: 'T6F-654',
          rutaId: 3,
          rutaNombre: 'Línea 40',
          latitud: '-15.47500000',
          longitud: '-70.14500000',
          velocidad: '25.00',
          direccion: 200,
          estado: 'activo',
          sentido: 'ida',
        ),
      ];

  // 🆕 Método para obtener rutas cercanas a una ubicación
  static List<RutaModel> obtenerRutasCercanas(
    double lat,
    double lng,
    double radioKm,
  ) {
    return rutasPrueba.where((ruta) {
      // Verificar si algún punto de IDA o VUELTA está dentro del radio
      final dentroDeRadio = ruta.coordinadasIda.any((coord) =>
              _calcularDistanciaKm(lat, lng, coord.latitude, coord.longitude) <=
              radioKm) ||
          ruta.coordinadasVuelta.any((coord) =>
              _calcularDistanciaKm(lat, lng, coord.latitude, coord.longitude) <=
              radioKm);

      return dentroDeRadio;
    }).toList();
  }

  // 🆕 Método para buscar rutas por nombre de lugar
  static List<RutaModel> buscarRutasPorDestino(
    String destino,
    double miLat,
    double miLng,
    double radioKm,
  ) {
    // Simulación simple: busca por nombre en descripción
    final destinoLower = destino.toLowerCase();

    return rutasPrueba.where((ruta) {
      final coincideNombre = ruta.nombre.toLowerCase().contains(destinoLower) ||
          (ruta.descripcion?.toLowerCase().contains(destinoLower) ?? false);

      // Además, verifica que la ruta pase cerca del usuario
      final pasaCercaDelUsuario = ruta.coordinadasIda.any((coord) =>
              _calcularDistanciaKm(
                  miLat, miLng, coord.latitude, coord.longitude) <=
              radioKm) ||
          ruta.coordinadasVuelta.any((coord) =>
              _calcularDistanciaKm(
                  miLat, miLng, coord.latitude, coord.longitude) <=
              radioKm);

      return coincideNombre || pasaCercaDelUsuario;
    }).toList();
  }

  // ════════════════════════════════════════════════════════
  // 🔧 HELPER: Calcular distancia en km (CORREGIDO)
  // ════════════════════════════════════════════════════════
  static double _calcularDistanciaKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // Radio de la Tierra en km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
