// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mapa_tiempo_real_screen.dart';
import '../../widgets/chat_floating_button.dart';
import '../../widgets/lineas_cercanas_widget.dart';
import '../../widgets/buscador_destino_widget.dart';
import '../../widgets/resultado_busqueda_widget.dart';
import '../providers/ruta_provider.dart';
import '../providers/ubicacion_provider.dart';
import 'welcome_screen.dart';
import 'login_conductor_screen.dart'; // 🆕 AGREGAR ESTA LÍNEA
import '../providers/conductor_provider.dart'; // 🆕 NUEVO IMPORT

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _mostrandoResultados = false;
  String _textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    final ubicacionProvider = context.read<UbicacionProvider>();
    final rutaProvider = context.read<RutaProvider>();

    // Obtener ubicación del usuario
    await ubicacionProvider.obtenerUbicacionActual();

    // Cargar rutas cercanas
    final posicion = ubicacionProvider.posicionActual;
    if (posicion != null) {
      await rutaProvider.cargarRutasCercanas(
        posicion.latitude,
        posicion.longitude,
        radioKm: 3.0,
      );
    }
  }

  Future<void> _buscarRutas(String destino) async {
    setState(() {
      _textoBusqueda = destino;
      _mostrandoResultados = true;
    });

    final ubicacionProvider = context.read<UbicacionProvider>();
    final rutaProvider = context.read<RutaProvider>();

    final posicion = ubicacionProvider.posicionActual;
    if (posicion != null) {
      await rutaProvider.buscarPorDestino(
        destino,
        posicion.latitude,
        posicion.longitude,
        radioKm: 5.0,
      );
    }
  }

  void _limpiarBusqueda() {
    setState(() {
      _mostrandoResultados = false;
      _textoBusqueda = '';
    });
    context.read<RutaProvider>().limpiarBusqueda();
  }

  void _verRuta(ruta) async {
    final rutaProvider = context.read<RutaProvider>();

    // Seleccionar la ruta (esto carga las coordenadas completas)
    await rutaProvider.seleccionarRuta(ruta.id);

    // Limpiar búsqueda si estaba activa
    if (_mostrandoResultados) {
      _limpiarBusqueda();
    }

    // El mapa ya se actualizará automáticamente gracias al Provider
  }

  // ... (código anterior igual hasta _mostrarMenuPerfil)

  void _mostrarMenuPerfil() async {
    final conductorProvider = context.read<ConductorProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: conductorProvider.estaLogeado
                  ? Colors.orange.shade700 // 🆕 Naranja si es conductor
                  : Colors.indigo.shade700, // Azul si es usuario normal
              child: Text(
                widget.username[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 🆕 MOSTRAR INFO EXTRA SI ES CONDUCTOR
            if (conductorProvider.estaLogeado) ...[
              const SizedBox(height: 8),
              Text(
                'Conductor - ${conductorProvider.conductor?.linea ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 32),

            // 🆕 OPCIONES SEGÚN MODO
            if (conductorProvider.estaLogeado) ...[
              // MODO CONDUCTOR ACTIVO
              ListTile(
                leading:
                    Icon(Icons.directions_bus, color: Colors.orange.shade700),
                title: Text('Modo Conductor Activo'),
                subtitle: Text('Línea ${conductorProvider.conductor?.linea}'),
                trailing:
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                onTap: () {
                  Navigator.pop(context);
                  // Ya está en modo conductor, no hacer nada
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange.shade700),
                title: Text('Salir del Modo Conductor'),
                onTap: () {
                  Navigator.pop(context);
                  _salirModoConductor();
                },
              ),
              const Divider(),
            ] else ...[
              // MODO USUARIO NORMAL
              ListTile(
                leading:
                    Icon(Icons.directions_bus, color: Colors.orange.shade700),
                title: Text('Modo Conductor'),
                subtitle: Text('Iniciar sesión como conductor'),
                onTap: () {
                  Navigator.pop(context);
                  _irALoginConductor();
                },
              ),
              const Divider(),
            ],

            // OPCIONES COMUNES
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Cambiar nombre'),
              onTap: () {
                Navigator.pop(context);
                _cambiarNombre();
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion();
              },
            ),
          ],
        ),
      ),
    );
  }

// 🆕 NUEVO MÉTODO: Salir del modo conductor
  Future<void> _salirModoConductor() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Salir del Modo Conductor'),
        content: Text('¿Estás seguro de que quieres salir del modo conductor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700),
            child: Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final conductorProvider = context.read<ConductorProvider>();
      await conductorProvider.logout();

      // Recargar la página para volver al modo usuario
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: widget.username),
          ),
        );
      }
    }
  }

// 🆕 NUEVO MÉTODO: Navegar al login de conductor
  void _irALoginConductor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginConductorScreen(),
      ),
    );
  }

  Future<void> _cambiarNombre() async {
    final controller = TextEditingController(text: widget.username);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null &&
        nuevoNombre.isNotEmpty &&
        nuevoNombre != widget.username) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', nuevoNombre);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: nuevoNombre),
          ),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Hola, '),
            Text(
              widget.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(' 👋'),
          ],
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _mostrarMenuPerfil,
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ════════════════════════════════════════════════════════
          // MAPA PRINCIPAL
          // ════════════════════════════════════════════════════════
          Consumer<ConductorProvider>(
            builder: (context, conductorProvider, child) {
              return MapaTiempoRealScreen(
                modoConductor: conductorProvider.estaLogeado,
                lineaConductor: conductorProvider.conductor?.linea,
              );
            },
          ),

          // ════════════════════════════════════════════════════════
          // WIDGETS SOBRE EL MAPA
          // ════════════════════════════════════════════════════════
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // 🔍 BUSCADOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<RutaProvider>(
                    builder: (context, rutaProvider, child) {
                      return BuscadorDestinoWidget(
                        onBuscar: _buscarRutas,
                        onLimpiar: _limpiarBusqueda,
                        cargando: rutaProvider.cargando,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 🚌 LÍNEAS CERCANAS o RESULTADOS DE BÚSQUEDA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer2<RutaProvider, UbicacionProvider>(
                    builder: (context, rutaProvider, ubicacionProvider, child) {
                      // Mostrar resultados de búsqueda
                      if (_mostrandoResultados) {
                        return ResultadoBusquedaWidget(
                          resultados: rutaProvider.resultadosBusqueda,
                          textoBusqueda: _textoBusqueda,
                          onVerRuta: _verRuta,
                        );
                      }

                      // Mostrar líneas cercanas
                      final posicion = ubicacionProvider.posicionActual;
                      return LineasCercanasWidget(
                        rutasCercanas: rutaProvider.rutasCercanas,
                        cargando: rutaProvider.cargando,
                        onVerRuta: _verRuta,
                        miLatitud: posicion?.latitude,
                        miLongitud: posicion?.longitude,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ════════════════════════════════════════════════════════
          // BOTÓN FLOTANTE DE CHAT
          // ════════════════════════════════════════════════════════
          Positioned(
            right: 16,
            bottom: 16,
            child: ChatFloatingButton(username: widget.username),
          ),
        ],
      ),
    );
  }
}
