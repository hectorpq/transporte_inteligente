import 'package:flutter/foundation.dart';
import '../../data/models/bus_model.dart';
import '../../data/repositories/bus_repository.dart';
import '../../services/socket_service.dart';

class BusProvider with ChangeNotifier {
  final BusRepository _repository = BusRepository();
  final SocketService _socketService = SocketService();

  List<BusModel> _buses = [];
  bool _cargando = false;
  String? _error;

  List<BusModel> get buses => _buses;
  bool get cargando => _cargando;
  String? get error => _error;

  // Conectar al WebSocket
  Future<void> conectarWebSocket() async {
    try {
      await _socketService.conectar();

      // Escuchar actualizaciones de buses
      _socketService.on('bus-update', (data) {
        _actualizarBus(data);
      });

      // Escuchar buses iniciales
      _socketService.on('buses-init', (data) {
        if (data is List) {
          _buses = data.map((json) => BusModel.fromJson(json)).toList();
          notifyListeners();
        }
      });
    } catch (e) {
      _error = 'Error al conectar WebSocket: $e';
      notifyListeners();
    }
  }

  // Actualizar un bus específico
  void _actualizarBus(dynamic data) {
    try {
      final busActualizado = BusModel.fromJson(data);

      final index = _buses.indexWhere((b) => b.busId == busActualizado.busId);

      if (index != -1) {
        _buses[index] = busActualizado;
      } else {
        _buses.add(busActualizado);
      }

      notifyListeners();
    } catch (e) {
      print('Error al actualizar bus: $e');
    }
  }

  // Cargar buses iniciales
  Future<void> cargarBuses() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _buses = await _repository.getBuses();
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar buses: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // Cargar buses cercanos
  Future<void> cargarBusesCercanos(double lat, double lng) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _buses = await _repository.getBusesCercanos(lat, lng);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar buses cercanos: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // 🆕 NUEVO MÉTODO: Cargar buses por línea específica (para modo conductor)
  Future<void> cargarBusesPorLinea(String linea) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      // Primero cargamos todos los buses
      final todosLosBuses = await _repository.getBuses();

      // Luego filtramos por línea
      _buses = todosLosBuses.where((bus) => bus.rutaNombre == linea).toList();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar buses de la línea $linea: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  // Obtener bus por ID
  Future<BusModel?> obtenerBusPorId(int busId) async {
    try {
      return await _repository.getBusPorId(busId);
    } catch (e) {
      print('Error al obtener bus: $e');
      return null;
    }
  }

  // Suscribirse a actualizaciones de una ruta
  void suscribirseARuta(int rutaId) {
    _socketService.suscribirseARuta(rutaId);
  }

  // Desuscribirse de una ruta
  void desuscribirseDeRuta(int rutaId) {
    _socketService.desuscribirseDeRuta(rutaId);
  }

  // Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.desconectar();
    super.dispose();
  }
}
