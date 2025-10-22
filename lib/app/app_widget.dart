// app/app_widget.dart - CORRIGIDO
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/firebase_options.dart';
import 'package:projeto_padrao/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../controllers/auth/auth_controller.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget>
    with SingleTickerProviderStateMixin {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  bool _sessionInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthController()),
              ChangeNotifierProvider(create: (context) => UsuarioController()),
              ChangeNotifierProvider(create: (context) => PerfilController()),
            ],
            child: Builder(
              builder: (context) {
                if (!_sessionInitialized) {
                  _sessionInitialized = true;
                  final authController = Provider.of<AuthController>(
                    context,
                    listen: false,
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (kDebugMode) {
                      print('🚀 [APP] Inicializando sessão...');
                    }
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

        // 🔥 TELA DE INICIALIZAÇÃO PREMIUM DO FIREBASE
        return _buildFirebaseLoadingScreen();
      },
    );
  }

  // 🎭 TELA DE LOADING DO FIREBASE PREMIUM - CORRIGIDA
  Widget _buildFirebaseLoadingScreen() {
    return Material(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr, // 🔥 CORREÇÃO CRÍTICA
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // 🔹 Background animado
                _buildAnimatedBackground(),

                // 🔹 Conteúdo principal
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🔹 Logo Firebase animada
                          _buildFirebaseLogo(),

                          const SizedBox(height: 32),

                          // 🔹 Título com animação
                          _buildLoadingTitle(),

                          const SizedBox(height: 24),

                          // 🔹 Status com animação
                          _buildStatusIndicator(),

                          const SizedBox(height: 32),

                          // 🔹 Progresso animado
                          _buildFirebaseProgress(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 Informações técnicas
                _buildTechInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 BACKGROUND ANIMADO
  Widget _buildAnimatedBackground() {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 2000),
      tween: ColorTween(
        begin: AppColors.primary.withOpacity(0.03),
        end: AppColors.primaryLight.withOpacity(0.06),
      ),
      builder: (context, color, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color ?? AppColors.primary.withOpacity(0.03),
                AppColors.background,
                AppColors.background,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // 🔥 LOGO FIREBASE ANIMADA
  Widget _buildFirebaseLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFCB2B), // Amarelo Firebase
            Color(0xFFFFA000), // Laranja Firebase
            Color(0xFFF57C00), // Laranja escuro
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 🔹 Ícone Firebase central
          const Center(
            child: Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),

          // 🔹 Animações de partículas
          ..._buildFireParticles(),
        ],
      ),
    );
  }

  // 🔥 PARTÍCULAS DE FOGO ANIMADAS
  List<Widget> _buildFireParticles() {
    return List.generate(8, (index) {
      return Positioned(
        left: 20 + (index % 3) * 20,
        top: 15 + (index % 2) * 25,
        child: _FireParticle(delay: Duration(milliseconds: index * 200)),
      );
    });
  }

  // 📝 TÍTULO COM ANIMAÇÃO
  Widget _buildLoadingTitle() {
    return Column(
      children: [
        Text(
          'Inicializando Firebase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conectando com os serviços em nuvem',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 🔄 INDICADOR DE STATUS ANIMADO
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 Dot animado
          _PulsatingDot(color: AppColors.warning),

          const SizedBox(width: 12),

          // 🔹 Texto de status
          Text(
            'Conectando...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 📊 BARRA DE PROGRESSO FIREBASE
  Widget _buildFirebaseProgress() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          // 🔹 Barra de progresso
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                // 🔹 Progresso animado
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 200 * _animationController.value,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFCB2B),
                            Color(0xFFFFA000),
                            Color(0xFFF57C00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Texto de progresso
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = (_animationController.value * 100).toInt();
              return Text(
                '$progress% concluído',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ℹ️ INFORMAÇÕES TÉCNICAS
  Widget _buildTechInfo() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'Google Firebase Services',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Authentication • Firestore • Storage',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: AppColors.textDisabled.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ❌ TELA DE ERRO ESTILIZADA - CORRIGIDA
  Widget _buildErrorScreen(String error) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Erro na Inicialização',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível conectar com o Firebase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔥 PARTÍCULA DE FOGO ANIMADA
class _FireParticle extends StatefulWidget {
  final Duration delay;

  const _FireParticle({required this.delay});

  @override
  State<_FireParticle> createState() => _FireParticleState();
}

class _FireParticleState extends State<_FireParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, -8 * _animation.value),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFFFA000),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// 💫 DOT PULSANTE
class _PulsatingDot extends StatefulWidget {
  final Color color;

  const _PulsatingDot({required this.color});

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 8 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
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
