import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/bus_provider.dart';
import '../providers/ruta_provider.dart';
import '../providers/ubicacion_provider.dart';
import '../providers/conductor_provider.dart';
import '../../widgets/tiempo_llegada_widget.dart';
import '../../config/constants.dart';

class MapaTiempoRealScreen extends StatefulWidget {
  final bool modoConductor;
  final String? lineaConductor;

  const MapaTiempoRealScreen({
    Key? key,
    this.modoConductor = false,
    this.lineaConductor,
  }) : super(key: key);

  @override
  State<MapaTiempoRealScreen> createState() => _MapaTiempoRealScreenState();
}

class _MapaTiempoRealScreenState extends State<MapaTiempoRealScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionUsuario();
    _conectarWebSocket();
    _cargarRutaInicial();
  }

  // 🆕 NUEVO MÉTODO: Cargar ruta inicial según modo
  Future<void> _cargarRutaInicial() async {
    final rutaProvider = context.read<RutaProvider>();

    if (widget.modoConductor && widget.lineaConductor != null) {
      // MODO CONDUCTOR: Cargar solo su ruta
      await rutaProvider.cargarRutaConductor(widget.lineaConductor!);
    }
    // MODO USUARIO: No cargar ruta inicial (el usuario seleccionará una)
  }

  Future<void> _obtenerUbicacionUsuario() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Obtener posición actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centrar mapa en la ubicación del usuario
      _mapController.move(_userLocation!, 15.0);
    } catch (e) {
      print('Error al obtener ubicación: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _conectarWebSocket() async {
    final busProvider = context.read<BusProvider>();
    await busProvider.conectarWebSocket();

    // 🆕 EN MODO CONDUCTOR: Cargar solo buses de la misma línea
    if (widget.modoConductor && widget.lineaConductor != null) {
      await busProvider.cargarBusesPorLinea(widget.lineaConductor!);
    } else {
      // MODO USUARIO: Cargar todos los buses
      await busProvider.cargarBuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ════════════════════════════════════════════════════════
        // MAPA PRINCIPAL
        // ════════════════════════════════════════════════════════
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              AppConstants.defaultLat,
              AppConstants.defaultLng,
            ),
            initialZoom: AppConstants.defaultZoom,
            minZoom: 12.0,
            maxZoom: 18.0,
          ),
          children: [
            // Capa de tiles de OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile_app',
              maxZoom: 19,
            ),

            // ════════════════════════════════════════════════════════
            // RUTAS IDA (AZUL) Y VUELTA (ROJO)
            // ════════════════════════════════════════════════════════
            Consumer<RutaProvider>(
              builder: (context, rutaProvider, child) {
                final rutaSeleccionada = rutaProvider.rutaSeleccionada;

                // 🆕 MODO CONDUCTOR: Mostrar siempre su ruta
                if (widget.modoConductor && rutaSeleccionada == null) {
                  return const SizedBox.shrink();
                }

                if (rutaSeleccionada == null) {
                  return const SizedBox.shrink();
                }

                return PolylineLayer(
                  polylines: [
                    // LÍNEA AZUL - IDA
                    if (rutaSeleccionada.coordinadasIda.isNotEmpty)
                      Polyline(
                        points: rutaSeleccionada.coordinadasIda,
                        color: widget.modoConductor
                            ? Colors
                                .orange.shade700 // 🆕 Naranja para conductor
                            : Colors.blue.shade700, // Azul para usuario
                        strokeWidth: widget.modoConductor ? 6.0 : 5.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2.0,
                      ),

                    // LÍNEA ROJA - VUELTA
                    if (rutaSeleccionada.coordinadasVuelta.isNotEmpty)
                      Polyline(
                        points: rutaSeleccionada.coordinadasVuelta,
                        color: widget.modoConductor
                            ? Colors.orange
                                .shade600 // 🆕 Naranja claro para conductor
                            : Colors.red.shade700, // Rojo para usuario
                        strokeWidth: widget.modoConductor ? 6.0 : 5.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2.0,
                      ),
                  ],
                );
              },
            ),

            // ════════════════════════════════════════════════════════
            // MARCADORES DE BUSES
            // ════════════════════════════════════════════════════════
            Consumer<BusProvider>(
              builder: (context, busProvider, child) {
                // 🆕 FILTRAR BUSES: En modo conductor solo mostrar buses de la misma línea
                final buses = widget.modoConductor &&
                        widget.lineaConductor != null
                    ? busProvider.buses
                        .where((bus) => bus.rutaNombre == widget.lineaConductor)
                        .toList()
                    : busProvider.buses;

                return MarkerLayer(
                  markers: buses.map((bus) {
                    // 🆕 COLOR ESPECIAL PARA MODO CONDUCTOR
                    final Color colorBus;
                    if (widget.modoConductor) {
                      colorBus =
                          Colors.orange.shade700; // Naranja para conductor
                    } else {
                      colorBus = bus.sentido == 'ida'
                          ? Colors.blue.shade700
                          : Colors.red.shade700;
                    }

                    return Marker(
                      point: LatLng(
                        double.parse(bus.latitud.toString()),
                        double.parse(bus.longitud.toString()),
                      ),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _mostrarInfoBus(bus),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorBus,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // ════════════════════════════════════════════════════════
            // MARCADOR DEL USUARIO/CONDUCTOR
            // ════════════════════════════════════════════════════════
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.modoConductor
                            ? Colors
                                .orange.shade500 // 🆕 Naranja para conductor
                            : Colors.green.shade500, // Verde para usuario
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.modoConductor
                                    ? Colors.orange
                                    : Colors.green)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.modoConductor
                            ? Icons
                                .directions_bus // 🆕 Icono bus para conductor
                            : Icons.person, // Icono persona para usuario
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ════════════════════════════════════════════════════════
        // 🆕 BANNER MODO CONDUCTOR
        // ════════════════════════════════════════════════════════
        if (widget.modoConductor)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MODO CONDUCTOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Línea: ${widget.lineaConductor}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ════════════════════════════════════════════════════════
        // LOADING DE UBICACIÓN
        // ════════════════════════════════════════════════════════
        if (_isLoadingLocation)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Obteniendo ubicación...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        // ════════════════════════════════════════════════════════
        // BOTONES FLOTANTES
        // ════════════════════════════════════════════════════════
        if (_userLocation != null)
          Positioned(
            bottom: widget.modoConductor
                ? 120
                : 80, // 🆕 Ajustar posición en modo conductor
            right: 16,
            child: Column(
              children: [
                // Botón: Mi ubicación
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(_userLocation!, 16.0);
                  },
                  heroTag: 'mi_ubicacion',
                  child: Icon(Icons.my_location,
                      color: widget.modoConductor
                          ? Colors.orange.shade700
                          : Colors.indigo.shade700),
                ),

                const SizedBox(height: 8),

                // 🆕 Botón: Cambiar sentido (SOLO MODO CONDUCTOR)
                if (widget.modoConductor)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _cambiarSentido,
                    heroTag: 'cambiar_sentido',
                    child: Icon(Icons.swap_horiz, color: Colors.blue.shade700),
                  ),

                const SizedBox(height: 8),

                // Botón: Limpiar ruta seleccionada (SOLO MODO USUARIO)
                if (!widget.modoConductor)
                  Consumer<RutaProvider>(
                    builder: (context, rutaProvider, child) {
                      if (rutaProvider.rutaSeleccionada == null) {
                        return const SizedBox.shrink();
                      }

                      return FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          rutaProvider.deseleccionarRuta();
                        },
                        heroTag: 'limpiar_ruta',
                        child: Icon(Icons.close, color: Colors.red.shade700),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // 🆕 MÉTODO PARA CAMBIAR SENTIDO (MODO CONDUCTOR)
  void _cambiarSentido() {
    final conductorProvider = context.read<ConductorProvider>();
    final sentidoActual = conductorProvider.sentidoActual;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Sentido'),
        content: Text('Sentido actual: ${sentidoActual.toUpperCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              conductorProvider.cambiarSentido('ida');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sentido cambiado a IDA'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('IDA'),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              conductorProvider.cambiarSentido('vuelta');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sentido cambiado a VUELTA'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('VUELTA'),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoBus(dynamic bus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bus.sentido == 'ida'
                        ? Colors.blue.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: bus.sentido == 'ida'
                        ? Colors.blue.shade700
                        : Colors.red.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.placa ?? 'Sin placa',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${bus.rutaNombre ?? 'Ruta desconocida'} - ${bus.sentido == 'ida' ? 'IDA' : 'VUELTA'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(
              icon: Icons.speed,
              label: 'Velocidad',
              value: '${bus.velocidad ?? 0} km/h',
            ),
            _InfoRow(
              icon: Icons.navigation,
              label: 'Dirección',
              value: '${bus.direccion ?? 0}°',
            ),
            _InfoRow(
              icon:
                  bus.sentido == 'ida' ? Icons.arrow_forward : Icons.arrow_back,
              label: 'Sentido',
              value: bus.sentido == 'ida' ? 'IDA' : 'VUELTA',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
