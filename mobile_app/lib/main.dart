// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/bus_provider.dart';
import 'presentation/providers/ruta_provider.dart';
import 'presentation/providers/ubicacion_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/conductor_provider.dart';
import 'presentation/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => RutaProvider()),
        ChangeNotifierProvider(create: (_) => UbicacionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
      ],
      child: MaterialApp(
        title: 'Transporte Inteligente',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
