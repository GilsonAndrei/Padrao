// main.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/services/session/session_expiry_service.dart';
import 'app/app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 👇 INICIAR SERVIÇO DE EXPIRAÇÃO AUTOMÁTICA
  SessionExpiryService.startAutoCleanup();

  // Configurações adicionais podem ser adicionadas aqui
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Ocorreu um erro inesperado',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const AppWidget());
}
