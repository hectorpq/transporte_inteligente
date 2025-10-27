// lib/data/repositories/bus_repository.dart

import '../models/bus_model.dart';
import '../../services/api_service.dart';

class BusRepository {
  final ApiService _apiService = ApiService();

  // Obtener todos los buses
  Future<List<BusModel>> getBuses() async {
    try {
      final data = await _apiService.getBuses();
      return data.map((json) => BusModel.fromJson(json)).toList();
    } catch (e) {
      print('Error en BusRepository.getBuses: $e');
      return [];
    }
  }

  // Obtener buses cercanos
  Future<List<BusModel>> getBusesCercanos(
    double lat,
    double lng, {
    double radio = 5.0,
  }) async {
    try {
      final data = await _apiService.getBusesCercanos(lat, lng, radio: radio);
      return data.map((json) => BusModel.fromJson(json)).toList();
    } catch (e) {
      print('Error en BusRepository.getBusesCercanos: $e');
      return [];
    }
  }

  // Obtener un bus por ID
  Future<BusModel?> getBusPorId(int busId) async {
    try {
      final data = await _apiService.getBusPorId(busId);
      if (data != null) {
        return BusModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error en BusRepository.getBusPorId: $e');
      return null;
    }
  }

  // Obtener historial de un bus
  Future<List<dynamic>> getHistorialBus(int busId) async {
    try {
      return await _apiService.getHistorialBus(busId);
    } catch (e) {
      print('Error en BusRepository.getHistorialBus: $e');
      return [];
    }
  }
}
