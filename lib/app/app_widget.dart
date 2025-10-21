// app/app_widget.dart - SOLUÇÃO DEFINITIVA
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/firebase_options.dart';
import 'package:projeto_padrao/routes/app_routes.dart';
import 'package:projeto_padrao/services/notification/notification_service.dart';
import 'package:projeto_padrao/services/notification/web_notification_service.dart';
import 'package:projeto_padrao/views/notifications/notifications_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as html;

import '../controllers/auth/auth_controller.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  @override
  void initState() {
    super.initState();
    _setupServiceWorkerListener(); // ✅ Configura listener para receber eventos do Service Worker
  }

  bool _sessionInitialized = false;
  // ✅ REMOVIDO: Não instanciar serviços aqui

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
              ChangeNotifierProvider(create: (context) => UsuarioController()),
              ChangeNotifierProvider(create: (context) => PerfilController()),
              // ✅ REMOVIDO: Não adicionar NotificationService no provider inicial
            ],
            builder: (context, child) {
              if (!_sessionInitialized) {
                _sessionInitialized = true;
                final authController = Provider.of<AuthController>(
                  context,
                  listen: false,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  print('🚀 [APP] Inicializando sessão...');
                  authController.inicializarSessao();

                  // ✅ INICIALIZAR NOTIFICAÇÕES APÓS TUDO ESTAR PRONTO
                  _initializeNotifications(context);
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

  // ✅ MÉTODO SEPARADO PARA INICIALIZAR NOTIFICAÇÕES
  Future<void> _initializeNotifications(BuildContext context) async {
    if (kIsWeb) {
      await WebNotificationService().initialize();
    } else {
      await NotificationService().initialize();
    }
  }
}

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

void _setupServiceWorkerListener() {
  if (kIsWeb) {
    try {
      html.window.addEventListener(
        'message',
        (event) {
              final dynamic data = js_util.getProperty(event, 'data');
              if (data != null &&
                  data is Map &&
                  data['type'] == 'NAVIGATE_TO_NOTIFICATIONS') {
                print(
                  '🌐 [APP] Recebido NAVIGATE_TO_NOTIFICATIONS do Service Worker',
                );

                final context = NavigationService.context;
                if (context != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsPage()),
                    );
                  });
                } else {
                  print('⚠️ Contexto de navegação não disponível');
                }
              }
            }
            as html.EventListener?,
      );

      print('✅ Listener do Service Worker configurado');
    } catch (e) {
      print('❌ Erro ao configurar listener do Service Worker: $e');
    }
  }
}

/*void _setupServiceWorkerListener() {
  if (kIsWeb) {
    try {
      // Ouvinte para mensagens do Service Worker
      html.window.addEventListener(
        'message',
        (event) {
              final data = event.data;
              if (data is Map && data['type'] == 'NOTIFICATION_CLICK') {
                print(
                  '🌐 [APP] Mensagem do Service Worker recebida: ${data['data']}',
                );

                // Navegar para a página de notificações
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (NavigationService.context != null) {
                    Navigator.push(
                      NavigationService.context!,
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  }
                });
              }
            }
            as html.EventListener?,
      );

      print('✅ Listener do Service Worker configurado');
    } catch (e) {
      print('❌ Erro ao configurar listener: $e');
    }
  }
}*/
