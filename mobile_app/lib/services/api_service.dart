// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // GET request genérico
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en GET $endpoint: $e');
      rethrow;
    }
  }

  // POST request genérico
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en POST $endpoint: $e');
      rethrow;
    }
  }

  // Obtener todos los buses
  Future<List<dynamic>> getBuses() async {
    try {
      final result = await get(AppConstants.busesEndpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('Error al obtener buses: $e');
      return [];
    }
  }

  // Obtener buses cercanos
  Future<List<dynamic>> getBusesCercanos(double lat, double lng,
      {double radio = 5.0}) async {
    try {
      final endpoint =
          '${AppConstants.busesCercanosEndpoint}?lat=$lat&lng=$lng&radio=$radio';
      final result = await get(endpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('Error al obtener buses cercanos: $e');
      return [];
    }
  }

  // Obtener un bus por ID
  Future<Map<String, dynamic>?> getBusPorId(int busId) async {
    try {
      final result = await get('${AppConstants.busesEndpoint}/$busId');
      return result['data'];
    } catch (e) {
      print('Error al obtener bus $busId: $e');
      return null;
    }
  }

  // Obtener todas las rutas
  Future<List<dynamic>> getRutas() async {
    try {
      final result = await get(AppConstants.rutasEndpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('Error al obtener rutas: $e');
      return [];
    }
  }

  // Obtener una ruta específica con paradas
  Future<Map<String, dynamic>?> getRutaConParadas(int rutaId) async {
    try {
      final result = await get('${AppConstants.rutasEndpoint}/$rutaId');
      return result['data'];
    } catch (e) {
      print('Error al obtener ruta $rutaId: $e');
      return null;
    }
  }

  // Obtener paradas cercanas a una ubicación
  Future<List<dynamic>> getParadasCercanas(
      double lat, double lng, double radio) async {
    try {
      final endpoint = '/paradas/cercanas?lat=$lat&lng=$lng&radio=$radio';
      final result = await get(endpoint);
      return result['data'] ?? [];
    } catch (e) {
      print('Error al obtener paradas cercanas: $e');
      return [];
    }
  }

  // Obtener historial de un bus
  Future<List<dynamic>> getHistorialBus(int busId) async {
    try {
      final result =
          await get('${AppConstants.busesEndpoint}/$busId/historial');
      return result['data'] ?? [];
    } catch (e) {
      print('Error al obtener historial del bus $busId: $e');
      return [];
    }
  }
}
