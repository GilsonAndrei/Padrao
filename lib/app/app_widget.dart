// app/app_widget.dart - CORRIGIDO
import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/firebase_options.dart';
import 'package:projeto_padrao/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../controllers/auth_controller.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 CORREÇÃO: Controlar inicialização da sessão
  bool _sessionInitialized = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Erro ao inicializar Firebase: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthController()),
            ],
            child: Builder(
              // 👈 CORREÇÃO: Trocar Consumer por Builder
              builder: (context) {
                // 👇 CORREÇÃO: Inicializar apenas uma vez
                if (!_sessionInitialized) {
                  _sessionInitialized = true;
                  final authController = Provider.of<AuthController>(
                    context,
                    listen: false,
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    print('🚀 [APP] Inicializando sessão...');
                    authController.inicializarSessao();
                  });
                }

                return MaterialApp(
                  title: 'Sistema Padrão',
                  theme: AppTheme.lightTheme,
                  debugShowCheckedModeBanner: false,
                  initialRoute: AppRoutes.splash,
                  onGenerateRoute: AppPages.generateRoute,
                  navigatorKey: NavigationService.navigatorKey,
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: child,
                    );
                  },
                );
              },
            ),
          );
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlutterLogo(size: 80),
                  const SizedBox(height: 20),
                  const Text('Inicializando Firebase...'),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Serviço de Navegação Global
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static Future<dynamic> navigateReplacement(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void goBack() {
    return navigatorKey.currentState!.pop();
  }
}
