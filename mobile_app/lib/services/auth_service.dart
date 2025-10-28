import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/conductor_model.dart';
import '../config/constants.dart';

class AuthService {
  // ✅ LOGIN REAL CON TU API EN VERCEL
  static Future<Conductor?> loginConductor({
    required String correo,
    required String contrasena,
    required String placa,
    required String linea,
  }) async {
    try {
      final url = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.conductorLoginEndpoint}');

      print('🔐 Intentando login conductor en: $url');
      print('📧 Correo: $correo');
      print('🚗 Línea: $linea, Placa: $placa');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'correo': correo,
          'contrasena': contrasena,
          'placa': placa,
          'linea': linea,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['conductor'] != null) {
          print('✅ Login exitoso - Conductor encontrado');
          return Conductor.fromJson(data['conductor']);
        } else {
          print('❌ Login fallido: ${data['message']}');
          throw Exception(data['message'] ?? 'Credenciales incorrectas');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Correo o contraseña incorrectos');
      } else if (response.statusCode == 404) {
        throw Exception('Conductor no encontrado en la base de datos');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en login conductor: $e');

      // Manejo específico de errores de conexión
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'No se puede conectar al servidor. Verifica tu conexión.');
      }

      throw Exception('Error: $e');
    }
  }

  // ✅ ACTUALIZAR UBICACIÓN EN TU API
  static Future<bool> actualizarUbicacionConductor({
    required String conductorId,
    required double latitud,
    required double longitud,
    double? velocidad,
    double? direccion,
    String? sentido,
  }) async {
    try {
      final url = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.conductorUbicacionEndpoint}');

      print(
          '📍 Enviando ubicación conductor $conductorId: $latitud, $longitud');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conductor_id': conductorId,
          'latitud': latitud,
          'longitud': longitud,
          'velocidad': velocidad ?? 0.0,
          'direccion': direccion ?? 0.0,
          'sentido': sentido ?? 'ida',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] == true;
        if (success) {
          print('✅ Ubicación enviada correctamente');
        } else {
          print('❌ Error al enviar ubicación: ${data['message']}');
        }
        return success;
      } else {
        print('❌ Error HTTP ${response.statusCode} al enviar ubicación');
        return false;
      }
    } catch (e) {
      print('❌ Error actualizando ubicación: $e');
      return false;
    }
  }

  // ✅ OBTENER RUTA DEL CONDUCTOR
  static Future<Map<String, dynamic>?> obtenerRutaConductor(
      String conductorId) async {
    try {
      final url = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.conductorRutaEndpoint}/$conductorId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ruta'];
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo ruta: $e');
      return null;
    }
  }

  // ✅ CAMBIAR SENTIDO DEL CONDUCTOR
  static Future<bool> cambiarSentidoConductor({
    required String conductorId,
    required String sentido,
  }) async {
    try {
      final url = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.cambiarSentidoEndpoint}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conductor_id': conductorId,
          'sentido': sentido,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('❌ Error cambiando sentido: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    print('🚪 Sesión de conductor cerrada');
  }
}
