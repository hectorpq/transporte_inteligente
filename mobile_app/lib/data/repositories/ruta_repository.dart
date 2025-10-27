// lib/data/repositories/ruta_repository.dart

import '../models/ruta_model.dart';
import '../models/parada_model.dart';
import '../../services/api_service.dart';

class RutaRepository {
  final ApiService _apiService = ApiService();

  // Obtener todas las rutas
  Future<List<RutaModel>> getRutas() async {
    try {
      final data = await _apiService.getRutas();
      return data.map((json) => RutaModel.fromJson(json)).toList();
    } catch (e) {
      print('Error en RutaRepository.getRutas: $e');
      return [];
    }
  }

  // Obtener una ruta con sus paradas
  Future<Map<String, dynamic>?> getRutaConParadas(int rutaId) async {
    try {
      return await _apiService.getRutaConParadas(rutaId);
    } catch (e) {
      print('Error en RutaRepository.getRutaConParadas: $e');
      return null;
    }
  }

  // Obtener paradas cercanas a una ubicación
  Future<List<ParadaModel>> getParadasCercanas(double lat, double lng,
      {double radio = 500}) async {
    try {
      final data = await _apiService.getParadasCercanas(lat, lng, radio);
      return data.map((json) => ParadaModel.fromJson(json)).toList();
    } catch (e) {
      print('Error en RutaRepository.getParadasCercanas: $e');
      return [];
    }
  }
}
