// controllers/auth_controller.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projeto_padrao/app/app_widget.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/models/security_event.dart';
import 'package:projeto_padrao/services/session/device_service.dart';
import 'package:projeto_padrao/services/session/session_expiry_service.dart';
import 'package:projeto_padrao/services/session/session_tracker_service.dart';
import 'package:projeto_padrao/widgets/session_confirmation_dialog.dart';
import '../../models/usuario.dart';
import '../../services/auth/auth_service.dart';
import '../../services/session/security_monitor_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  Usuario? _usuarioLogado;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _activityTimer;

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  // 👇 CORREÇÃO: Controlar inicialização da sessão
  bool _sessionInitialized = false;
  String? _currentDeviceId;
  // Login
  // Login - CORRIGIDO
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 [CONTROLLER] Iniciando login para: $email');

      _usuarioLogado = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (_usuarioLogado != null) {
        print('✅ [CONTROLLER] Login bem-sucedido: ${_usuarioLogado!.nome}');

        // 👇 OBTER DEVICE ID PERSISTENTE
        _currentDeviceId = await DeviceService.getDeviceId();
        print('📱 [CONTROLLER] DeviceId: $_currentDeviceId');

        // 👇 VERIFICAR SE EXISTEM OUTRAS SESSÕES
        final hasOtherSessions = await _checkAndHandleOtherSessions();

        if (hasOtherSessions) {
          // Usuário cancelou o login devido a outras sessões
          _setLoading(false);
          return false;
        }

        // 👇 REGISTRAR NOVA SESSÃO COM DEVICE ID REAL
        await SessionTrackerService.registerNewSession(
          _usuarioLogado!,
          _currentDeviceId!,
        );
        // 👇 CORREÇÃO CRÍTICA: FORÇAR PERSISTÊNCIA
        await _forcarPersistenciaFirebase();

        // MONITORAMENTO: Login bem-sucedido
        SecurityMonitorService.monitorUserActivity(
          usuario: _usuarioLogado!,
          action: 'login_success',
          resource: 'auth_system',
          details: 'Login realizado com sucesso',
          ipAddress: 'mobile_app',
          userAgent: 'flutter_app',
        );

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        print('❌ [CONTROLLER] Login falhou - usuário null');
        _setLoading(false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [CONTROLLER] FirebaseAuthException: ${e.code}');
      _setError(_traduzirErroFirebase(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ [CONTROLLER] Erro inesperado: $e');
      _setError('Erro inesperado: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> _checkAndHandleOtherSessions() async {
    if (_usuarioLogado == null || _currentDeviceId == null) return false;

    try {
      print('🔍 [CONTROLLER] Verificando outras sessões...');

      // Verificar se existem outras sessões ativas
      final hasOtherSessions =
          await SessionTrackerService.hasOtherActiveSessions(
            _usuarioLogado!.id,
            _currentDeviceId!,
          );

      print('📊 [CONTROLLER] Tem outras sessões: $hasOtherSessions');

      if (hasOtherSessions) {
        // Obter contagem exata de sessões
        final otherSessions =
            await SessionTrackerService.getOtherActiveSessions(
              _usuarioLogado!.id,
              _currentDeviceId!,
            );

        print(
          '👥 [CONTROLLER] ${otherSessions.length} outras sessões encontradas',
        );

        // 👇 MOSTRAR DIALOG DE CONFIRMAÇÃO
        final bool shouldContinue = await _showSessionConfirmationDialog(
          otherSessions.length,
        );

        if (!shouldContinue) {
          print('🚫 [CONTROLLER] Login cancelado pelo usuário');
          await _authService.signOut(); // Fazer logout já que cancelou
          _usuarioLogado = null;
          _currentDeviceId = null;
          return true; // Indica que houve outras sessões e usuário cancelou
        }

        // 👇 USUÁRIO CONFIRMOU - DESCONECTAR OUTRAS SESSÕES
        print('🔒 [CONTROLLER] Desconectando outras sessões...');
        await SessionTrackerService.terminateOtherSessions(
          _usuarioLogado!.id,
          _currentDeviceId!,
        );
        print('✅ [CONTROLLER] Outras sessões desconectadas');
      }

      return false; // Não houve problema com outras sessões
    } catch (e) {
      print('❌ [CONTROLLER] Erro ao verificar sessões: $e');
      return false;
    }
  }

  // 👇 MÉTODO CORRIGIDO PARA MOSTRAR DIALOG
  Future<bool> _showSessionConfirmationDialog(int otherSessionsCount) async {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      print('❌ [CONTROLLER] Context não disponível para mostrar dialog');
      return true; // Continuar por padrão
    }

    print('💬 [CONTROLLER] Mostrando dialog de confirmação...');

    // Usar Future.delayed para garantir que o contexto esteja pronto
    await Future.delayed(Duration(milliseconds: 100));

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionConfirmationDialog(
        userId: _usuarioLogado!.id,
        currentDeviceId: _currentDeviceId!,
        otherSessionsCount: otherSessionsCount,
        onConfirm: () {
          print('✅ [DIALOG] Usuário confirmou - desconectando outras sessões');
          Navigator.of(context).pop(true);
        },
        onCancel: () {
          print('❌ [DIALOG] Usuário cancelou - mantendo sessões ativas');
          Navigator.of(context).pop(false);
        },
      ),
    );

    print('🎯 [CONTROLLER] Resultado do dialog: ${result ?? false}');
    return result ?? false;
  }

  // 👇 ADICIONE ESTE MÉTODO NOVO
  Future<void> _forcarPersistenciaFirebase() async {
    try {
      // Forçar o Firebase a manter a sessão
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('💾 [CONTROLLER] Forçando persistência Firebase:');
        print('   👤 UID: ${user.uid}');
        print('   📧 Email: ${user.email}');
        print('   ✅ Verificado: ${user.emailVerified}');

        // Recarregar usuário para garantir persistência
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        print('   🔄 Usuário recarregado: ${refreshedUser?.email}');
      }
    } catch (e) {
      print('❌ [CONTROLLER] Erro ao forçar persistência: $e');
    }
  }

  // Cadastro
  Future<bool> cadastrar(String nome, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('👤 [CONTROLLER] Iniciando cadastro para: $email');

      _usuarioLogado = await _authService.signUpWithEmailAndPassword(
        email,
        password,
        nome,
      );

      if (_usuarioLogado != null) {
        print('✅ [CONTROLLER] Cadastro bem-sucedido: ${_usuarioLogado!.nome}');

        // MONITORAMENTO: Novo usuário cadastrado
        SecurityMonitorService.monitorUserActivity(
          usuario: _usuarioLogado!,
          action: 'user_created',
          resource: 'auth_system',
          details: 'Novo usuário cadastrado no sistema',
          ipAddress: 'mobile_app',
          userAgent: 'flutter_app',
        );

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        print('❌ [CONTROLLER] Cadastro falhou - usuário null');
        _setError('Falha ao criar usuário');
        _setLoading(false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [CONTROLLER] FirebaseAuthException no cadastro: ${e.code}');

      // MONITORAMENTO: Erro no cadastro
      SecurityMonitorService.monitorUserActivity(
        usuario: _createTempUser(email),
        action: 'signup_failed',
        resource: 'auth_system',
        details: 'FirebaseAuthException: ${e.code}',
        ipAddress: 'mobile_app',
      );

      _setError(_traduzirErroFirebase(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ [CONTROLLER] Erro inesperado no cadastro: $e');

      // MONITORAMENTO: Erro inesperado no cadastro
      SecurityMonitorService.monitorUserActivity(
        usuario: _createTempUser(email),
        action: 'signup_error',
        resource: 'auth_system',
        details: 'Erro inesperado: $e',
        ipAddress: 'mobile_app',
      );

      _setError('Erro ao cadastrar: $e');
      _setLoading(false);
      return false;
    }
  }

  // Recuperar Senha
  Future<bool> recuperarSenha(String email) async {
    _setLoading(true);
    _clearError();

    try {
      print('📧 [CONTROLLER] Solicitando recuperação de senha para: $email');

      await _authService.sendPasswordResetEmail(email);

      print('✅ [CONTROLLER] Email de recuperação enviado');

      // MONITORAMENTO: Recuperação de senha solicitada
      SecurityMonitorService.monitorUserActivity(
        usuario: _createTempUser(email),
        action: 'password_reset_requested',
        resource: 'auth_system',
        details: 'Solicitação de recuperação de senha',
        ipAddress: 'mobile_app',
      );

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ [CONTROLLER] Erro ao recuperar senha: ${e.code}');

      // MONITORAMENTO: Falha na recuperação de senha
      SecurityMonitorService.monitorUserActivity(
        usuario: _createTempUser(email),
        action: 'password_reset_failed',
        resource: 'auth_system',
        details: 'FirebaseAuthException: ${e.code}',
        ipAddress: 'mobile_app',
      );

      _setError(_traduzirErroFirebase(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ [CONTROLLER] Erro inesperado ao recuperar senha: $e');

      _setError('Erro ao enviar email de recuperação: $e');
      _setLoading(false);
      return false;
    }
  }

  // Alterar Senha
  Future<bool> alterarSenha(String novaSenha) async {
    if (_usuarioLogado == null) {
      _setError('Usuário não está logado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      print(
        '🔐 [CONTROLLER] Alterando senha do usuário: ${_usuarioLogado!.email}',
      );

      // Aqui você implementaria a lógica de alteração de senha
      // Por exemplo, usando Firebase Auth API
      // await _authService.changePassword(novaSenha);

      await Future.delayed(Duration(seconds: 1)); // Simulação

      print('✅ [CONTROLLER] Senha alterada com sucesso');

      // MONITORAMENTO CRÍTICO: Alteração de senha
      SecurityMonitorService.monitorUserActivity(
        usuario: _usuarioLogado!,
        action: 'password_change',
        resource: 'user_profile',
        details: 'Senha alterada com sucesso',
        ipAddress: 'mobile_app',
        severity: SecuritySeverity.high,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ [CONTROLLER] Erro ao alterar senha: $e');

      // MONITORAMENTO: Falha na alteração de senha
      SecurityMonitorService.monitorUserActivity(
        usuario: _usuarioLogado!,
        action: 'password_change_failed',
        resource: 'user_profile',
        details: 'Erro ao alterar senha: $e',
        ipAddress: 'mobile_app',
      );

      _setError('Erro ao alterar senha: $e');
      _setLoading(false);
      return false;
    }
  }

  // 👇 ATUALIZAR MÉTODO DE LOGOUT
  // 👇 ATUALIZAR MÉTODO DE LOGOUT
  Future<void> logout() async {
    // Parar timer de atividade
    _activityTimer?.cancel();

    if (_usuarioLogado != null && _currentDeviceId != null) {
      await SessionTrackerService.terminateCurrentSession(
        _usuarioLogado!.id,
        _currentDeviceId!,
      );
    }

    _sessionInitialized = false;
    _currentDeviceId = null;
    _usuarioLogado = null;

    await _authService.signOut();
    notifyListeners();

    print('🚪 [CONTROLLER] Logout completo');
  }

  // Verificar se usuário está logado (MÉTODO CORRIGIDO)
  Future<bool> verificarUsuarioLogado() async {
    try {
      // Verifica se há um usuário autenticado no Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Busca os dados completos do usuário no Firestore
        _usuarioLogado = await _authService.getUserById(currentUser.uid);

        if (_usuarioLogado != null) {
          notifyListeners();

          // MONITORAMENTO: Sessão recuperada
          SecurityMonitorService.monitorUserActivity(
            usuario: _usuarioLogado!,
            action: 'session_restored',
            resource: 'auth_system',
            details: 'Sessão de usuário recuperada',
            ipAddress: 'mobile_app',
          );

          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ [CONTROLLER] Erro ao verificar usuário logado: $e');
      return false;
    }
  }

  // Criar usuário temporário para monitoramento quando não há usuário real
  Usuario _createTempUser(String email) {
    return Usuario(
      id: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Usuário Desconhecido',
      email: email,
      perfil: PerfilUsuario(
        id: 'temp_profile',
        nome: 'Temporário',
        descricao: 'Perfil temporário para monitoramento',
        permissoes: [],
        dataCriacao: DateTime.now(),
        ativo: true,
      ),
      dataCriacao: DateTime.now(),
      ativo: true,
      emailVerificado: false,
      isAdmin: false,
    );
  }

  // Traduz códigos de erro do Firebase
  String _traduzirErroFirebase(String codigo) {
    switch (codigo) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'configuration-not-found':
        return 'Configuração do Firebase não encontrada.';
      default:
        return 'Erro: $codigo';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // INICIALIZAR SESSÃO - CORRIGIDO
  // controllers/auth_controller.dart - ATUALIZE o inicializarSessao
  Future<void> inicializarSessao() async {
    if (_sessionInitialized) return;
    _sessionInitialized = true;

    if (_sessionInitialized) {
      print('⏭️ [CONTROLLER] Sessão já inicializada, ignorando...');
      return;
    }

    _sessionInitialized = true;

    try {
      print('🔄 [CONTROLLER] Inicializando sessão...');
      _setLoading(true);

      // 👇 INICIAR SERVIÇO DE EXPIRAÇÃO AUTOMÁTICA
      SessionExpiryService.startAutoCleanup();

      // 👇 DEBUG DETALHADO DO FIREBASE
      print('🔥 [CONTROLLER] Estado do Firebase Auth:');
      final currentUser = FirebaseAuth.instance.currentUser;
      print('   👤 CurrentUser: ${currentUser != null}');

      if (currentUser != null) {
        print('   🆔 UID: ${currentUser.uid}');
        print('   📧 Email: ${currentUser.email}');
        print('   ✅ Email verificado: ${currentUser.emailVerified}');
        print('   🕒 Criado: ${currentUser.metadata.creationTime}');
        print('   🔐 Último login: ${currentUser.metadata.lastSignInTime}');

        // Busca dados completos no Firestore
        _usuarioLogado = await _authService.getUserById(currentUser.uid);

        if (_usuarioLogado != null) {
          _currentDeviceId = await DeviceService.getDeviceId();

          // 👇 VERIFICAR SE A SESSÃO ESTÁ EXPIRADA
          final isExpired = await SessionTrackerService.isSessionExpired(
            _usuarioLogado!.id,
            _currentDeviceId!,
          );

          if (isExpired) {
            print('⏰ [CONTROLLER] Sessão expirada, fazendo logout...');
            await logout();
          } else {
            print('✅ [CONTROLLER] Sessão restaurada: ${_usuarioLogado!.nome}');

            // MONITORAMENTO: Sessão restaurada
            SecurityMonitorService.monitorUserActivity(
              usuario: _usuarioLogado!,
              action: 'session_restored',
              resource: 'auth_system',
              details: 'Sessão persistente restaurada',
              ipAddress: 'mobile_app',
            );
          }
        } else {
          print('❌ [CONTROLLER] Usuário não encontrado no Firestore');
        }
      } else {
        print('ℹ️ [CONTROLLER] Nenhuma sessão ativa no Firebase');
        print('   💡 Possíveis causas:');
        print('   • Persistência não habilitada');
        print('   • App reinstalado');
        print('   • Dados limpos');
        print('   • Problema de configuração Firebase');
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ [CONTROLLER] Erro ao inicializar sessão: $e');
      _setLoading(false);
      _sessionInitialized = false;
    }
  }

  // 👇 RASTREAR ATIVIDADE DO USUÁRIO
  void _startActivityTracking() {
    // Atualizar atividade a cada 5 minutos
    _activityTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_usuarioLogado != null && _currentDeviceId != null) {
        await SessionTrackerService.updateLastActivity(
          _usuarioLogado!.id,
          _currentDeviceId!,
        );
        print('🕒 [ACTIVITY] Atividade atualizada');
      }
    });
  }

  // 👇 MÉTODO PARA ATUALIZAR ATIVIDADE MANUALMENTE (chamar em interações)
  void recordUserActivity() async {
    if (_usuarioLogado != null && _currentDeviceId != null) {
      await SessionTrackerService.updateLastActivity(
        _usuarioLogado!.id,
        _currentDeviceId!,
      );
    }
  }
}
