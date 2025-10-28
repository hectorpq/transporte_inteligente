// lib/presentation/providers/ruta_provider.dart

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/ruta_model.dart';
import '../../data/models/parada_model.dart';
import '../../data/repositories/ruta_repository.dart';

class RutaProvider with ChangeNotifier {
  final RutaRepository _repository = RutaRepository();

  // Estado actual
  List<RutaModel> _rutas = [];
  List<RutaModel> _rutasCercanas = []; // 🆕
  List<RutaModel> _resultadosBusqueda = []; // 🆕
  RutaModel? _rutaSeleccionada; // 🆕
  List<ParadaModel> _paradas = [];
  bool _cargando = false;
  String? _error;

  // Getters
  List<RutaModel> get rutas => _rutas;
  List<RutaModel> get rutasCercanas => _rutasCercanas; // 🆕
  List<RutaModel> get resultadosBusqueda => _resultadosBusqueda; // 🆕
  RutaModel? get rutaSeleccionada => _rutaSeleccionada; // 🆕
  List<ParadaModel> get paradas => _paradas;
  bool get cargando => _cargando;
  String? get error => _error;

  // ════════════════════════════════════════════════════════
  // CARGAR TODAS LAS RUTAS
  // ════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════
  // 🆕 CARGAR RUTAS CERCANAS A UNA UBICACIÓN
  // ════════════════════════════════════════════════════════
  Future<void> cargarRutasCercanas(
    double lat,
    double lng, {
    double radioKm = 3.0,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('📍 Cargando rutas cercanas a ($lat, $lng)...');
      _rutasCercanas =
          await _repository.getRutasCercanas(lat, lng, radioKm: radioKm);
      print('✅ Rutas cercanas encontradas: ${_rutasCercanas.length}');
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar rutas cercanas: $e';
      _cargando = false;
      _rutasCercanas = [];
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════
  // 🆕 BUSCAR RUTAS POR DESTINO
  // ════════════════════════════════════════════════════════
  Future<void> buscarPorDestino(
    String destino,
    double miLat,
    double miLng, {
    double radioKm = 5.0,
  }) async {
    if (destino.trim().isEmpty) {
      _resultadosBusqueda = [];
      notifyListeners();
      return;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Buscando rutas para: "$destino"');
      _resultadosBusqueda = await _repository.buscarRutasPorDestino(
        destino,
        miLat,
        miLng,
        radioKm: radioKm,
      );
      print('✅ Resultados encontrados: ${_resultadosBusqueda.length}');
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al buscar rutas: $e';
      _cargando = false;
      _resultadosBusqueda = [];
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════
  // 🆕 SELECCIONAR UNA RUTA (para mostrar en el mapa)
  // ════════════════════════════════════════════════════════
  Future<void> seleccionarRuta(int rutaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('🎯 Cargando ruta completa: $rutaId');
      _rutaSeleccionada = await _repository.getRutaCompleta(rutaId);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al seleccionar ruta: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // 🆕 Deseleccionar ruta
  void deseleccionarRuta() {
    _rutaSeleccionada = null;
    notifyListeners();
  }

  // 🆕 Limpiar resultados de búsqueda
  void limpiarBusqueda() {
    _resultadosBusqueda = [];
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // CARGAR RUTA CON PARADAS (ORIGINAL)
  // ════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════
  // CARGAR PARADAS CERCANAS (ORIGINAL)
  // ════════════════════════════════════════════════════════
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
