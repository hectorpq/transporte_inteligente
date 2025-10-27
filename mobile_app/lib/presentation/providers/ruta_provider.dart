// lib/presentation/providers/ruta_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/ruta_model.dart';
import '../../data/models/parada_model.dart';
import '../../data/repositories/ruta_repository.dart';

class RutaProvider with ChangeNotifier {
  final RutaRepository _repository = RutaRepository();

  List<RutaModel> _rutas = [];
  List<ParadaModel> _paradas = [];
  bool _cargando = false;
  String? _error;

  List<RutaModel> get rutas => _rutas;
  List<ParadaModel> get paradas => _paradas;
  bool get cargando => _cargando;
  String? get error => _error;

  // Cargar todas las rutas
  Future<void> cargarRutas() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _rutas = await _repository.getRutas();
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar rutas: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // Cargar ruta con paradas
  Future<Map<String, dynamic>?> cargarRutaConParadas(int rutaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getRutaConParadas(rutaId);
      _cargando = false;
      notifyListeners();
      return data;
    } catch (e) {
      _error = 'Error al cargar ruta: $e';
      _cargando = false;
      notifyListeners();
      return null;
    }
  }

  // Cargar paradas cercanas
  Future<void> cargarParadasCercanas(double lat, double lng) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _paradas = await _repository.getParadasCercanas(lat, lng);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar paradas: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
