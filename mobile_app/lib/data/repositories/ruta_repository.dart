// lib/data/repositories/ruta_repository.dart

import 'package:latlong2/latlong.dart';
import '../models/ruta_model.dart';
import '../models/parada_model.dart';
import '../../services/api_service.dart';
import '../dummy_data.dart'; // 🧪 Solo como fallback

class RutaRepository {
  final ApiService _apiService = ApiService();

  // 🔧 Flag para modo de desarrollo (cambia a false cuando tengas API)
  final bool _usarDatosPrueba = true; // ← Cambia a false cuando tengas API

  // ════════════════════════════════════════════════════════
  // OBTENER TODAS LAS RUTAS
  // ════════════════════════════════════════════════════════
  Future<List<RutaModel>> getRutas() async {
    if (_usarDatosPrueba) {
      print('🧪 Usando datos de prueba (dummy_data)');
      await Future.delayed(Duration(milliseconds: 500)); // Simular latencia
      return DummyData.rutasPrueba;
    }

    try {
      print('🌐 Obteniendo rutas desde API...');
      final data = await _apiService.getRutas();
      return data.map((json) => RutaModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en getRutas: $e');
      print('🔄 Fallback a datos de prueba');
      return DummyData.rutasPrueba; // Fallback
    }
  }

  // ════════════════════════════════════════════════════════
  // OBTENER RUTA CON COORDENADAS IDA/VUELTA
  // ════════════════════════════════════════════════════════
  Future<RutaModel?> getRutaCompleta(int rutaId) async {
    if (_usarDatosPrueba) {
      print('🧪 Obteniendo ruta $rutaId desde datos de prueba');
      await Future.delayed(Duration(milliseconds: 300));
      return DummyData.rutasPrueba.firstWhere(
        (r) => r.id == rutaId,
        orElse: () => DummyData.rutasPrueba.first,
      );
    }

    try {
      print('🌐 Obteniendo ruta completa $rutaId desde API...');

      // Tu API debería devolver algo como:
      // {
      //   "ruta_id": 1,
      //   "nombre": "Línea 18",
      //   "color": "#FF9800",
      //   "coordenadas_ida": [
      //     {"latitud": -15.484, "longitud": -70.142, "orden": 1},
      //     ...
      //   ],
      //   "coordenadas_vuelta": [
      //     {"latitud": -15.474, "longitud": -70.138, "orden": 1},
      //     ...
      //   ]
      // }

      final data = await _apiService.getRutaConParadas(rutaId);
      if (data == null) return null;

      return RutaModel.fromJson(data);
    } catch (e) {
      print('❌ Error en getRutaCompleta: $e');
      return DummyData.rutasPrueba.firstWhere(
        (r) => r.id == rutaId,
        orElse: () => DummyData.rutasPrueba.first,
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // 🆕 OBTENER RUTAS CERCANAS A UNA UBICACIÓN
  // ════════════════════════════════════════════════════════
  Future<List<RutaModel>> getRutasCercanas(
    double lat,
    double lng, {
    double radioKm = 3.0,
  }) async {
    if (_usarDatosPrueba) {
      print(
          '🧪 Buscando rutas cercanas (dummy) a ($lat, $lng) - Radio: ${radioKm}km');
      await Future.delayed(Duration(milliseconds: 400));
      return DummyData.obtenerRutasCercanas(lat, lng, radioKm);
    }

    try {
      print('🌐 Obteniendo rutas cercanas desde API...');

      // Tu API debería tener un endpoint como:
      // GET /api/rutas/cercanas?lat=-15.48&lng=-70.14&radio=3

      final endpoint =
          '/rutas/cercanas?lat=$lat&lng=$lng&radio=${radioKm * 1000}'; // metros
      final result = await _apiService.get(endpoint);
      final data = result['data'] ?? [];

      return data.map<RutaModel>((json) => RutaModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en getRutasCercanas: $e');
      print('🔄 Fallback a datos de prueba');
      return DummyData.obtenerRutasCercanas(lat, lng, radioKm);
    }
  }

  // ════════════════════════════════════════════════════════
  // 🆕 BUSCAR RUTAS POR DESTINO
  // ════════════════════════════════════════════════════════
  Future<List<RutaModel>> buscarRutasPorDestino(
    String destino,
    double miLat,
    double miLng, {
    double radioKm = 5.0,
  }) async {
    if (_usarDatosPrueba) {
      print('🧪 Buscando rutas para destino "$destino" (dummy)');
      await Future.delayed(Duration(milliseconds: 500));
      return DummyData.buscarRutasPorDestino(destino, miLat, miLng, radioKm);
    }

    try {
      print('🌐 Buscando rutas por destino desde API...');

      // Tu API debería tener un endpoint como:
      // GET /api/rutas/buscar?destino=Plaza%20de%20Armas&lat=-15.48&lng=-70.14&radio=5000

      final endpoint =
          '/rutas/buscar?destino=$destino&lat=$miLat&lng=$miLng&radio=${radioKm * 1000}';
      final result = await _apiService.get(endpoint);
      final data = result['data'] ?? [];

      return data.map<RutaModel>((json) => RutaModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en buscarRutasPorDestino: $e');
      print('🔄 Fallback a datos de prueba');
      return DummyData.buscarRutasPorDestino(destino, miLat, miLng, radioKm);
    }
  }

  // ════════════════════════════════════════════════════════
  // OBTENER PARADAS CERCANAS (ORIGINAL - sin cambios)
  // ════════════════════════════════════════════════════════
  Future<List<ParadaModel>> getParadasCercanas(
    double lat,
    double lng, {
    double radio = 500,
  }) async {
    if (_usarDatosPrueba) {
      return []; // No hay paradas en dummy data aún
    }

    try {
      final data = await _apiService.getParadasCercanas(lat, lng, radio);
      return data.map((json) => ParadaModel.fromJson(json)).toList();
    } catch (e) {
      print('Error en RutaRepository.getParadasCercanas: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  // OBTENER RUTA CON PARADAS (ORIGINAL - sin cambios)
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getRutaConParadas(int rutaId) async {
    try {
      return await _apiService.getRutaConParadas(rutaId);
    } catch (e) {
      print('Error en RutaRepository.getRutaConParadas: $e');
      return null;
    }
  }
}
