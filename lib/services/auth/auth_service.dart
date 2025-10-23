import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/core/utils/logger_service.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import '../../models/usuario.dart';
import '../../models/perfil_usuario.dart';
import '../firestore_service.dart';

class AuthService {
  static final Map<String, int> _loginAttempts = {};
  static const int MAX_LOGIN_ATTEMPTS = 5;
  static const Duration LOCKOUT_DURATION = Duration(minutes: 15);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    _auth.setPersistence(Persistence.LOCAL);
    print('💾 [AUTH] Persistência local habilitada');
  }

  // ✅ VERIFICAR SE É ADMIN
  Future<bool> _verificarSeEhAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        return userData?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      print('❌ [SERVICE] Erro ao verificar admin: $e');
      return false;
    }
  }

  // ✅ MÉTODO: Obter token e fazer requisição HTTP
  Future<Map<String, dynamic>> _fazerRequisicaoHTTP({
    required String url,
    required Map<String, dynamic> dados,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final idToken = await user.getIdToken(true);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(dados),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erro na requisição');
    }
  }

  // ✅ CRIAR USUÁRIO
  Future<Map<String, dynamic>> criarUsuarioCompleto({
    required String email,
    required String senha,
    required String nome,
    required PerfilUsuario perfil,
    String? telefone,
    bool isAdmin = false,
  }) async {
    try {
      print('👤 [SERVICE] Criando usuário via HTTP: $email');

      final ehAdmin = await _verificarSeEhAdmin();
      if (!ehAdmin)
        throw Exception('Apenas administradores podem criar usuários');

      final perfilMap = {
        'id': perfil.id,
        'nome': perfil.nome,
        'descricao': perfil.descricao,
        'permissoes': perfil.permissoes.map((p) => p.codigo).toList(),
        'ativo': perfil.ativo,
        'dataCriacao': perfil.dataCriacao.millisecondsSinceEpoch,
        'dataAtualizacao': perfil.dataAtualizacao?.millisecondsSinceEpoch,
      };

      final resultado = await _fazerRequisicaoHTTP(
        url:
            'https://us-central1-padrao-210e0.cloudfunctions.net/criarUsuarioCompleto',
        dados: {
          'email': email,
          'senha': senha,
          'nome': nome,
          'telefone': telefone,
          'perfil': perfilMap,
          'isAdmin': isAdmin,
        },
      );

      print('✅ [SERVICE] Usuário criado: ${resultado['userId']}');
      return resultado;
    } catch (e) {
      print('❌ [SERVICE] Erro ao criar usuário: $e');
      rethrow;
    }
  }

  // ✅ ALTERAR SENHA
  Future<void> alterarSenhaUsuario({
    required String userId,
    required String novaSenha,
  }) async {
    try {
      print('🔐 [SERVICE] Alterando senha: $userId');

      final ehAdmin = await _verificarSeEhAdmin();
      if (!ehAdmin)
        throw Exception('Apenas administradores podem alterar senhas');

      await _fazerRequisicaoHTTP(
        url:
            'https://us-central1-padrao-210e0.cloudfunctions.net/alterarSenhaUsuario',
        dados: {'userId': userId, 'novaSenha': novaSenha},
      );

      print('✅ [SERVICE] Senha alterada com sucesso');
    } catch (e) {
      print('❌ [SERVICE] Erro ao alterar senha: $e');
      rethrow;
    }
  }

  // ✅ ATUALIZAR STATUS (Ativar/Inativar)
  Future<void> atualizarStatusUsuario({
    required String userId,
    required bool ativo,
  }) async {
    try {
      print('🔄 [SERVICE] Atualizando status: $userId -> $ativo');

      final ehAdmin = await _verificarSeEhAdmin();
      if (!ehAdmin)
        throw Exception('Apenas administradores podem alterar status');

      await _fazerRequisicaoHTTP(
        url:
            'https://us-central1-padrao-210e0.cloudfunctions.net/atualizarStatusUsuario',
        dados: {'userId': userId, 'ativo': ativo},
      );

      print('✅ [SERVICE] Status atualizado: $ativo');
    } catch (e) {
      print('❌ [SERVICE] Erro ao atualizar status: $e');
      rethrow;
    }
  }

  // ✅ INATIVAR USUÁRIO
  Future<void> inativarUsuario(String userId) async {
    await atualizarStatusUsuario(userId: userId, ativo: false);
  }

  // ✅ REATIVAR USUÁRIO
  Future<void> reativarUsuario(String userId) async {
    await atualizarStatusUsuario(userId: userId, ativo: true);
  }

  // ✅ TESTAR CONEXÃO
  Future<void> testarConexaoCloudFunctions() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://us-central1-padrao-210e0.cloudfunctions.net/testeConexao',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [SERVICE] Conexão OK: $data');
      } else {
        throw Exception('Erro na conexão');
      }
    } catch (e) {
      print('❌ [SERVICE] Erro ao testar conexão: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO PARA CRIAR USUÁRIO SIMPLES (mantido para compatibilidade)
  Future<String> criarUsuarioComSenhaCloudFunction({
    required String email,
    required String senha,
    required String nome,
    required PerfilUsuario perfil,
    String? telefone,
    bool isAdmin = false,
  }) async {
    final result = await criarUsuarioCompleto(
      email: email,
      senha: senha,
      nome: nome,
      perfil: perfil,
      telefone: telefone,
      isAdmin: isAdmin,
    );

    return result['userId'] as String;
  }

  // MÉTODO LEGADO - Criar usuário diretamente (sem Cloud Function)
  Future<Usuario?> criarUsuarioComSenha({
    required String email,
    required String senha,
    required String nome,
    required PerfilUsuario perfil,
    String? telefone,
    bool isAdmin = false,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email.trim(), password: senha);

      final User user = userCredential.user!;

      final Usuario novoUsuario = Usuario(
        id: user.uid,
        nome: nome,
        email: email.trim(),
        telefone: telefone,
        perfil: perfil,
        dataCriacao: DateTime.now(),
        ativo: true,
        emailVerificado: false,
        isAdmin: isAdmin,
        temSenhaDefinida: true,
        uidFirebase: user.uid,
      );

      await _firestoreService.saveUser(novoUsuario);
      return novoUsuario;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ MÉTODO NOVO: Buscar usuário por email
  Future<Usuario?> getUserByEmail(String email) async {
    try {
      print('🔍 [SERVICE] Buscando usuário por email: $email');

      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final usuario = Usuario.fromMap(doc.data()..['id'] = doc.id);
        print('✅ [SERVICE] Usuário encontrado: ${usuario.nome}');
        return usuario;
      }

      print('❌ [SERVICE] Usuário não encontrado para email: $email');
      return null;
    } catch (e) {
      print('❌ [SERVICE] Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  // Login com email e senha
  Future<Usuario?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _executeWithRetry(() async {
      if (_isAccountLocked(email)) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Muitas tentativas. Tente novamente em 15 minutos.',
        );
      }

      try {
        print('🔐 [SERVICE] Tentando login com: $email');

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        print(
          '✅ [SERVICE] Firebase Auth OK - User ID: ${userCredential.user!.uid}',
        );

        if (userCredential.user != null) {
          Usuario? usuario = await _firestoreService.getUserById(
            userCredential.user!.uid,
          );

          if (usuario == null) {
            print(
              '⚠️ [SERVICE] Usuário não encontrado no Firestore, criando perfil padrão...',
            );
            usuario = await _criarUsuarioPadrao(userCredential.user!);
          } else {
            print(
              '✅ [SERVICE] Usuário encontrado no Firestore: ${usuario.nome}',
            );
          }

          return usuario;
        }

        return null;
      } on FirebaseAuthException catch (e) {
        _recordFailedAttempt(email);
        print('❌ [SERVICE] FirebaseAuthException: ${e.code} - ${e.message}');
        rethrow;
      } catch (e) {
        print('❌ [SERVICE] Erro inesperado: $e');
        rethrow;
      }
    });
  }

  // ... (MANTENHA OS OUTROS MÉTODOS EXISTENTES - login, logout, etc.)

  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) rethrow;
        await Future.delayed(delay * attempt);
      }
    }
    throw Exception('Todas as tentativas falharam');
  }

  bool _isAccountLocked(String email) {
    final attempts = _loginAttempts[email] ?? 0;
    return attempts >= MAX_LOGIN_ATTEMPTS;
  }

  void _recordFailedAttempt(String email) {
    _loginAttempts[email] = (_loginAttempts[email] ?? 0) + 1;
    Future.delayed(LOCKOUT_DURATION, () {
      _loginAttempts.remove(email);
    });
  }

  Usuario _criarUsuarioBasico(User user) {
    final perfilId = FirebaseFirestore.instance.collection('perfis').doc().id;

    return Usuario(
      id: user.uid,
      nome: user.email?.split('@').first ?? 'Usuário',
      email: user.email!,
      perfil: PerfilUsuario(
        id: perfilId,
        nome: "Usuário",
        descricao: "Perfil básico",
        permissoes: [PermissaoUsuario.visualizarCadastro],
        dataCriacao: DateTime.now(),
        ativo: true,
      ),
      dataCriacao: DateTime.now(),
      ativo: true,
      emailVerificado: user.emailVerified,
      isAdmin: false,
    );
  }

  Future<Usuario> _criarUsuarioPadrao(User user) async {
    try {
      final perfilId = FirebaseFirestore.instance.collection('perfis').doc().id;

      PerfilUsuario perfilPadrao = PerfilUsuario(
        id: perfilId,
        nome: "Usuário",
        descricao: "Perfil de usuário padrão",
        permissoes: [
          PermissaoUsuario.visualizarCadastro,
          PermissaoUsuario.cadastrarPedidos,
        ],
        dataCriacao: DateTime.now(),
        ativo: true,
      );

      Usuario novoUsuario = Usuario(
        id: user.uid,
        nome: user.email?.split('@').first ?? 'Usuário',
        email: user.email!,
        perfil: perfilPadrao,
        dataCriacao: DateTime.now(),
        ativo: true,
        emailVerificado: user.emailVerified,
        isAdmin: false,
      );

      await _firestoreService.saveUser(novoUsuario);
      await _salvarPerfilNaColecao(perfilPadrao);

      return novoUsuario;
    } catch (e) {
      return _criarUsuarioBasico(user);
    }
  }

  Future<void> _salvarPerfilNaColecao(PerfilUsuario perfil) async {
    try {
      await _firestore
          .collection(AppConstants.profilesCollection)
          .doc(perfil.id)
          .set(perfil.toMap());
    } catch (e) {
      throw e;
    }
  }

  // Cadastro de novo usuário
  Future<Usuario?> signUpWithEmailAndPassword(
    String email,
    String password,
    String nome,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      if (userCredential.user != null) {
        final perfilId = FirebaseFirestore.instance
            .collection('perfis')
            .doc()
            .id;

        PerfilUsuario perfilPadrao = PerfilUsuario(
          id: perfilId,
          nome: "Usuário",
          descricao: "Perfil de usuário padrão",
          permissoes: [
            PermissaoUsuario.visualizarCadastro,
            PermissaoUsuario.cadastrarPedidos,
          ],
          dataCriacao: DateTime.now(),
          ativo: true,
        );

        Usuario novoUsuario = Usuario(
          id: userCredential.user!.uid,
          nome: nome,
          email: email.trim(),
          perfil: perfilPadrao,
          dataCriacao: DateTime.now(),
          ativo: true,
          isAdmin: false,
          emailVerificado: false,
        );

        await _firestoreService.saveUser(novoUsuario);
        await _salvarPerfilNaColecao(perfilPadrao);

        return novoUsuario;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Buscar usuário por ID
  Future<Usuario?> getUserById(String userId) async {
    try {
      return await _firestoreService.getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  // Obter usuário atual
  Future<Usuario?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await getUserById(user.uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Alterar senha do usuário atual
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('Usuário não está autenticado');
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // Verificar se email está verificado
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Enviar email de verificação
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw Exception('Usuário não está autenticado');
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // Atualizar perfil do usuário
  Future<void> updateUserProfile(Usuario usuario) async {
    try {
      await _firestoreService.saveUser(usuario);
    } catch (e) {
      rethrow;
    }
  }

  // Stream para monitorar estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream para monitorar mudanças no usuário atual
  Stream<Usuario?> get userChanges {
    return _auth.userChanges().asyncMap((User? user) async {
      if (user != null) {
        return await getUserById(user.uid);
      }
      return null;
    });
  }

  // Resetar senha de usuário (envia email de reset)
  Future<void> resetarSenhaUsuario(String email) async {
    try {
      print('🔄 [SERVICE] Resetando senha para: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ [SERVICE] Email de reset enviado para: $email');
    } on FirebaseAuthException catch (e) {
      print('❌ [SERVICE] Erro ao resetar senha: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Verificar se usuário tem senha definida
  Future<bool> usuarioTemSenhaDefinida(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['temSenhaDefinida'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ [SERVICE] Erro ao verificar senha: $e');
      return false;
    }
  }

  // Enviar email de convite para definir senha (para novos usuários)
  Future<void> enviarConviteSenha(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://seudominio.com/definir-senha',
        handleCodeInApp: true,
        iOSBundleId: 'com.seuapp.ios',
        androidPackageName: 'com.seuapp.android',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      print('✅ [SERVICE] Convite de senha enviado para: $email');
    } on FirebaseAuthException catch (e) {
      print('❌ [SERVICE] Erro ao enviar convite: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
