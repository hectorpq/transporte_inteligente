import 'package:flutter/foundation.dart';
import '../../data/models/conductor_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class ConductorProvider with ChangeNotifier {
  Conductor? _conductor;
  bool _estaLogeado = false;
  bool _cargando = false;
  String? _error;
  String _sentidoActual = 'ida'; // 🆕 Control de sentido

  // Getters
  Conductor? get conductor => _conductor;
  bool get estaLogeado => _estaLogeado;
  bool get cargando => _cargando;
  String? get error => _error;
  String get sentidoActual => _sentidoActual; // 🆕

  // Login del conductor
  Future<bool> loginConductor({
    required String correo,
    required String contrasena,
    required String placa,
    required String linea,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final conductor = await AuthService.loginConductor(
        correo: correo,
        contrasena: contrasena,
        placa: placa,
        linea: linea,
      );

      if (conductor != null) {
        _conductor = conductor;
        _estaLogeado = true;
        _sentidoActual = 'ida'; // 🆕 Sentido por defecto

        // Activar GPS para el conductor
        await _iniciarSeguimientoGPS();

        _cargando = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales incorrectas';
        _cargando = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  // Iniciar seguimiento GPS
  Future<void> _iniciarSeguimientoGPS() async {
    try {
      final locationService = LocationService();

      // Verificar permisos primero
      final permisosOk = await locationService.requestLocationPermission();

      if (permisosOk) {
        // Obtener ubicación actual para activar el GPS
        final position = await locationService.getCurrentLocation();

        if (position != null) {
          print(
              '📍 GPS Conductor activado: ${position.latitude}, ${position.longitude}');

          // Enviar ubicación inicial
          _enviarUbicacionConductor(position.latitude, position.longitude);

          // Escuchar actualizaciones de ubicación
          locationService.getLocationStream().listen((position) {
            _enviarUbicacionConductor(position.latitude, position.longitude);
          });
        }
      } else {
        print('❌ Permisos de ubicación no otorgados');
        _error = 'Se necesitan permisos de ubicación para el modo conductor';
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error iniciando GPS conductor: $e');
      _error = 'Error al activar GPS: $e';
      notifyListeners();
    }
  }

  // 🆕 ENVÍO REAL DE UBICACIÓN A LA API
  void _enviarUbicacionConductor(double lat, double lng) {
    if (_conductor != null && _estaLogeado) {
      print(
          '📍 Conductor ${_conductor!.usuario} - Ubicación: $lat, $lng - Sentido: $_sentidoActual');

      // ✅ ENVÍO REAL A LA API
      AuthService.actualizarUbicacionConductor(
        conductorId: _conductor!.id,
        latitud: lat,
        longitud: lng,
        sentido: _sentidoActual,
      );
    }
  }

  // 🆕 CAMBIAR SENTIDO DEL CONDUCTOR
  Future<void> cambiarSentido(String nuevoSentido) async {
    if (_conductor != null && _estaLogeado) {
      _sentidoActual = nuevoSentido;
      notifyListeners();

      // Enviar cambio a la API
      final success = await AuthService.cambiarSentidoConductor(
        conductorId: _conductor!.id,
        sentido: nuevoSentido,
      );

      if (success) {
        print('✅ Sentido cambiado a: $nuevoSentido');
      } else {
        print('❌ Error al cambiar sentido en la API');
      }
    }
  }

  // Logout del conductor
  Future<void> logout() async {
    await AuthService.logout();

    _conductor = null;
    _estaLogeado = false;
    _error = null;
    _sentidoActual = 'ida';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
