// lib/widgets/chat_floating_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/chat_provider.dart';
import '../presentation/screens/chat_screen.dart';

class ChatFloatingButton extends StatelessWidget {
  final String username;

  const ChatFloatingButton({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final noLeidos = chatProvider.mensajesNoLeidos;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Botón principal
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(username: username),
                  ),
                );
              },
              backgroundColor: Colors.indigo.shade700,
              child: const Icon(
                Icons.chat_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            // Badge de notificaciones
            if (noLeidos > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Center(
                    child: Text(
                      noLeidos > 99 ? '99+' : noLeidos.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
