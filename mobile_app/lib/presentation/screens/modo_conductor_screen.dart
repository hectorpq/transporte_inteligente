import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conductor_provider.dart';
import '../providers/ruta_provider.dart';
import 'mapa_tiempo_real_screen.dart';

class ModoConductorScreen extends StatelessWidget {
  const ModoConductorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conductorProvider = context.watch<ConductorProvider>();
    final conductor = conductorProvider.conductor!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Conductor'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarLogout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info conductor
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: Text(
                    conductor.usuario[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conductor.usuario,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Línea: ${conductor.linea} • ${conductor.placaVehiculo}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // 🆕 MOSTRAR SENTIDO ACTUAL
                      Consumer<ConductorProvider>(
                        builder: (context, conductorProvider, child) {
                          return Text(
                            'Sentido: ${conductorProvider.sentidoActual.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ],
            ),
          ),

          // Mapa con la ruta del conductor
          Expanded(
            child: MapaTiempoRealScreen(
              modoConductor: true,
              lineaConductor: conductor.linea,
            ),
          ),

          // Panel de control conductor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ruta: ${conductor.linea}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'GPS Activado',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                      Consumer<ConductorProvider>(
                        builder: (context, conductorProvider, child) {
                          return Text(
                            'Estado: ${conductorProvider.estaLogeado ? "Conectado" : "Desconectado"}',
                            style: TextStyle(
                              color: conductorProvider.estaLogeado
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                      // 🆕 INFO DE LA RUTA CARGADA
                      Consumer<RutaProvider>(
                        builder: (context, rutaProvider, child) {
                          final ruta = rutaProvider.rutaSeleccionada;
                          if (ruta != null) {
                            return Text(
                              'Puntos de ruta: ${ruta.coordinadasIda.length + ruta.coordinadasVuelta.length}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            );
                          }
                          return Text(
                            'Cargando ruta...',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _cambiarSentido(context);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Cambiar Sentido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CONFIRMAR LOGOUT
  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
            '¿Estás seguro de que quieres salir del modo conductor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final conductorProvider = context.read<ConductorProvider>();
      await conductorProvider.logout();

      if (context.mounted) {
        Navigator.pop(context); // Regresar al home normal
      }
    }
  }

  // ✅ CAMBIAR SENTIDO
  void _cambiarSentido(BuildContext context) {
    final conductorProvider = context.read<ConductorProvider>();
    final sentidoActual = conductorProvider.sentidoActual;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Sentido'),
        content: Text('Sentido actual: ${sentidoActual.toUpperCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              conductorProvider.cambiarSentido('ida');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sentido cambiado a IDA'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('IDA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              conductorProvider.cambiarSentido('vuelta');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sentido cambiado a VUELTA'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('VUELTA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
