// lib/presentation/screens/mapa_tiempo_real_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/bus_provider.dart';
import '../../widgets/tiempo_llegada_widget.dart';
import '../../config/constants.dart';

class MapaTiempoRealScreen extends StatefulWidget {
  const MapaTiempoRealScreen({Key? key}) : super(key: key);

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
    await busProvider.cargarBuses();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa principal
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

            // 🛣️ LÍNEA AZUL DE LA RUTA (AGREGAR ESTO)
            Consumer<BusProvider>(
              builder: (context, busProvider, child) {
                if (busProvider.buses.isEmpty) return const SizedBox.shrink();

                // Crear lista de puntos ordenados por la ruta
                List<LatLng> puntosRuta = busProvider.buses.map((bus) {
                  return LatLng(
                    double.parse(bus.latitud.toString()),
                    double.parse(bus.longitud.toString()),
                  );
                }).toList();

                // Ordenar por latitud para formar una línea coherente
                puntosRuta.sort((a, b) => a.latitude.compareTo(b.latitude));

                return PolylineLayer(
                  polylines: [
                    Polyline(
                      points: puntosRuta,
                      color: Colors.blue.shade700,
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                );
              },
            ),

            // Marcadores de buses
            Consumer<BusProvider>(
              builder: (context, busProvider, child) {
                return MarkerLayer(
                  markers: busProvider.buses.map((bus) {
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
                            color: Colors.indigo.shade700,
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

            // Marcador del usuario
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Widget de tiempo de llegada
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Consumer<BusProvider>(
            builder: (context, busProvider, child) {
              if (busProvider.buses.isEmpty || _userLocation == null) {
                return const SizedBox.shrink();
              }

              // Encontrar el bus más cercano
              var busMasCercano = busProvider.buses.first;
              double menorDistancia = double.infinity;

              for (var bus in busProvider.buses) {
                final distancia = Geolocator.distanceBetween(
                  _userLocation!.latitude,
                  _userLocation!.longitude,
                  double.parse(bus.latitud.toString()),
                  double.parse(bus.longitud.toString()),
                );

                if (distancia < menorDistancia) {
                  menorDistancia = distancia;
                  busMasCercano = bus;
                }
              }

              // Calcular tiempo aproximado (distancia / velocidad promedio)
              final velocidadPromedio = 25.0; // km/h
              final distanciaKm = menorDistancia / 1000;
              final tiempoHoras = distanciaKm / velocidadPromedio;
              final tiempoMinutos = (tiempoHoras * 60).round();

              return TiempoLlegadaWidget(
                rutaNombre: busMasCercano.rutaNombre ?? 'Ruta desconocida',
                minutos: tiempoMinutos,
                placa: busMasCercano.placa,
              );
            },
          ),
        ),

        // Loading de ubicación
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

        // Botón para centrar en mi ubicación
        if (_userLocation != null)
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(_userLocation!, 16.0);
              },
              child: Icon(Icons.my_location, color: Colors.indigo.shade700),
            ),
          ),
      ],
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
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.indigo.shade700,
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
                        bus.rutaNombre ?? 'Ruta desconocida',
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
