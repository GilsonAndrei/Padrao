// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import '../models/usuario.dart';
import '../models/perfil_usuario.dart';
import 'firestore_service.dart';

class AuthService {
  // Rate limiting básico
  static final Map<String, int> _loginAttempts = {};
  static const int MAX_LOGIN_ATTEMPTS = 5;
  static const Duration LOCKOUT_DURATION = Duration(minutes: 15);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  AuthService() {
    // 👇 HABILITAR PERSISTÊNCIA
    _auth.setPersistence(Persistence.LOCAL);
    print('💾 [AUTH] Persistência local habilitada');
  }

  // Login com email e senha
  Future<Usuario?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Verifica rate limiting
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
        // Busca os dados completos do usuário no Firestore
        Usuario? usuario = await _firestoreService.getUserById(
          userCredential.user!.uid,
        );

        if (usuario == null) {
          print(
            '⚠️ [SERVICE] Usuário não encontrado no Firestore, criando perfil padrão...',
          );
          // Se não existe no Firestore, cria um usuário com perfil padrão
          usuario = await _criarUsuarioPadrao(userCredential.user!);

          if (usuario == null) {
            print(
              '❌ [SERVICE] Falha crítica: não foi possível criar usuário padrão',
            );
            // Mesmo se falhar, retorna um usuário básico
            usuario = _criarUsuarioBasico(userCredential.user!);
          }
        } else {
          print('✅ [SERVICE] Usuário encontrado no Firestore: ${usuario.nome}');
        }

        return usuario;
      }

      print('❌ [SERVICE] userCredential.user é null');
      return null;
    } on FirebaseAuthException catch (e) {
      // Incrementa tentativas falhas
      _recordFailedAttempt(email);
      print('❌ [SERVICE] FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [SERVICE] Erro inesperado: $e');
      rethrow;
    }
  }

  bool _isAccountLocked(String email) {
    final attempts = _loginAttempts[email] ?? 0;
    return attempts >= MAX_LOGIN_ATTEMPTS;
  }

  void _recordFailedAttempt(String email) {
    _loginAttempts[email] = (_loginAttempts[email] ?? 0) + 1;

    // Reseta após o tempo de lockout
    Future.delayed(LOCKOUT_DURATION, () {
      _loginAttempts.remove(email);
    });
  }

  // Método fallback para criar usuário básico
  Usuario _criarUsuarioBasico(User user) {
    return Usuario(
      id: user.uid,
      nome: user.email?.split('@').first ?? 'Usuário',
      email: user.email!,
      perfil: PerfilUsuario(
        id: "perfil_basico",
        nome: "Usuário",
        descricao: "Perfil básico",
        permissoes: [PermissaoUsuario.visualizarCadastro],
        dataCriacao: DateTime.now(),
        ativo: true,
      ),
      dataCriacao: DateTime.now(),
      ativo: true,
      emailVerificado: user.emailVerified,
    );
  }

  // Criar usuário padrão no Firestore
  Future<Usuario> _criarUsuarioPadrao(User user) async {
    try {
      print('👤 [SERVICE] Criando usuário padrão para: ${user.uid}');

      PerfilUsuario perfilPadrao = PerfilUsuario(
        id: "perfil_usuario_padrao",
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
      );

      print('💾 [SERVICE] Salvando usuário no Firestore...');
      await _firestoreService.saveUser(novoUsuario);
      print('✅ [SERVICE] Usuário salvo com sucesso: ${novoUsuario.nome}');

      return novoUsuario;
    } catch (e) {
      print('❌ [SERVICE] Erro ao criar usuário padrão: $e');
      // Retorna um usuário básico mesmo se falhar ao salvar no Firestore
      return _criarUsuarioBasico(user);
    }
  }

  // Cadastro de novo usuário
  Future<Usuario?> signUpWithEmailAndPassword(
    String email,
    String password,
    String nome,
  ) async {
    try {
      print('👤 [SERVICE] Tentando cadastrar: $email - $nome');

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      print(
        '✅ [SERVICE] Cadastro bem-sucedido para: ${userCredential.user!.uid}',
      );

      if (userCredential.user != null) {
        PerfilUsuario perfilPadrao = PerfilUsuario(
          id: "perfil_usuario_padrao",
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
          emailVerificado: false,
        );

        await _firestoreService.saveUser(novoUsuario);
        print('✅ [SERVICE] Usuário salvo no Firestore: ${novoUsuario.id}');

        return novoUsuario;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ [SERVICE] Erro no cadastro: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [SERVICE] Erro inesperado no cadastro: $e');
      rethrow;
    }
  }

  // Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ [SERVICE] Email de recuperação enviado para: $email');
    } on FirebaseAuthException catch (e) {
      print(
        '❌ [SERVICE] Erro ao enviar email de recuperação: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    print('✅ [SERVICE] Usuário deslogado');
  }

  // MÉTODOS NOVOS ADICIONADOS:

  // Buscar usuário por ID
  Future<Usuario?> getUserById(String userId) async {
    try {
      print('🔍 [SERVICE] Buscando usuário por ID: $userId');
      return await _firestoreService.getUserById(userId);
    } catch (e) {
      print('❌ [SERVICE] Erro ao buscar usuário por ID: $e');
      return null;
    }
  }

  // Obter usuário atual
  Future<Usuario?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('👤 [SERVICE] Usuário atual encontrado: ${user.uid}');
        return await getUserById(user.uid);
      }
      print('ℹ️ [SERVICE] Nenhum usuário logado atualmente');
      return null;
    } catch (e) {
      print('❌ [SERVICE] Erro ao obter usuário atual: $e');
      return null;
    }
  }

  // Alterar senha do usuário atual
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        print('✅ [SERVICE] Senha alterada com sucesso');
      } else {
        throw Exception('Usuário não está autenticado');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [SERVICE] Erro ao alterar senha: ${e.code} - ${e.message}');
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
      print('❌ [SERVICE] Erro ao verificar email: $e');
      return false;
    }
  }

  // Enviar email de verificação
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        print('✅ [SERVICE] Email de verificação enviado');
      } else {
        throw Exception('Usuário não está autenticado');
      }
    } on FirebaseAuthException catch (e) {
      print(
        '❌ [SERVICE] Erro ao enviar email de verificação: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  // Atualizar perfil do usuário
  Future<void> updateUserProfile(Usuario usuario) async {
    try {
      await _firestoreService.saveUser(usuario);
      print('✅ [SERVICE] Perfil do usuário atualizado: ${usuario.nome}');
    } catch (e) {
      print('❌ [SERVICE] Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // Deletar conta do usuário
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Primeiro deleta do Firestore
        await _firestoreService.deleteUser(user.uid);
        // Depois deleta do Auth
        await user.delete();
        print('✅ [SERVICE] Conta do usuário deletada com sucesso');
      } else {
        throw Exception('Usuário não está autenticado');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [SERVICE] Erro ao deletar conta: ${e.code} - ${e.message}');
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

  // Limpar tentativas de login (para testes)
  static void clearLoginAttempts() {
    _loginAttempts.clear();
    print('🧹 [SERVICE] Tentativas de login limpas');
  }

  // Obter estatísticas de rate limiting (para debug)
  static Map<String, int> get loginAttemptsStats {
    return Map.from(_loginAttempts);
  }
}
