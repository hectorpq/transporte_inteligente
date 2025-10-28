import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conductor_provider.dart';
import 'modo_conductor_screen.dart';

class LoginConductorScreen extends StatefulWidget {
  const LoginConductorScreen({Key? key}) : super(key: key);

  @override
  State<LoginConductorScreen> createState() => _LoginConductorScreenState();
}

class _LoginConductorScreenState extends State<LoginConductorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _placaController = TextEditingController();
  final _lineaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión - Conductor'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Icono conductor
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 60,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Acceso Conductor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tus credenciales de conductor',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo Correo
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Contraseña
              TextFormField(
                controller: _contrasenaController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Placa
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa del vehículo',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la placa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Línea
              TextFormField(
                controller: _lineaController,
                decoration: const InputDecoration(
                  labelText: 'Línea de transporte',
                  prefixIcon: Icon(Icons.alt_route),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la línea';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botón Login
              Consumer<ConductorProvider>(
                builder: (context, conductorProvider, child) {
                  if (conductorProvider.cargando) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (conductorProvider.error != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(conductorProvider.error!),
                          backgroundColor: Colors.red,
                        ),
                      );
                      conductorProvider.clearError();
                    });
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'INICIAR SESIÓN COMO CONDUCTOR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final conductorProvider = context.read<ConductorProvider>();

      final success = await conductorProvider.loginConductor(
        correo: _correoController.text.trim(),
        contrasena: _contrasenaController.text.trim(),
        placa: _placaController.text.trim().toUpperCase(),
        linea: _lineaController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ModoConductorScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _placaController.dispose();
    _lineaController.dispose();
    super.dispose();
  }
}
