// services/usuario_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/services/auth/auth_service.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usuariosCollection = FirebaseFirestore.instance
      .collection(AppConstants.usersCollection);
  final AuthService _authService = AuthService(); // ✅ INSTÂNCIA DO AUTH SERVICE

  Future<List<Usuario>> getUsuarios() async {
    try {
      final querySnapshot = await _usuariosCollection
          .orderBy('dataCriacao', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _usuarioFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar usuários: $e');
    }
  }

  // ✅ MÉTODO ATUALIZADO: Salvar usuário com suporte a senha
  // ✅ MÉTODO PRINCIPAL: Salvar usuário (sempre usa Cloud Function para novos)
  Future<void> saveUsuario(Usuario usuario, {String? senha}) async {
    try {
      if (usuario.id.isEmpty || usuario.id == 'null') {
        // NOVO USUÁRIO - Usar Cloud Function
        if (senha != null && senha.isNotEmpty) {
          await _authService.criarUsuarioCompleto(
            email: usuario.email,
            senha: senha,
            nome: usuario.nome,
            perfil: usuario.perfil,
            telefone: usuario.telefone,
            isAdmin: usuario.isAdmin,
          );
          print('✅ [SERVICE] Usuário criado via Cloud Function');
        } else {
          throw Exception('Para novo usuário, uma senha é obrigatória');
        }
      } else {
        // USUÁRIO EXISTENTE - Apenas atualizar Firestore
        await _atualizarUsuarioFirestore(usuario);
      }
    } catch (e) {
      throw Exception('Erro ao salvar usuário: $e');
    }
  }

  // ✅ MÉTODO PRIVADO: Atualizar apenas no Firestore
  Future<void> _atualizarUsuarioFirestore(Usuario usuario) async {
    try {
      final usuarioData = _usuarioToFirestore(usuario);

      await _usuariosCollection.doc(usuario.id).update({
        ...usuarioData,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      print('✅ [SERVICE] Usuário atualizado no Firestore: ${usuario.id}');
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  Future<void> deleteUsuario(String id) async {
    try {
      if (id.isEmpty || id == 'null') {
        throw Exception('ID inválido para exclusão: $id');
      }
      await _usuariosCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao excluir usuário: $e');
    }
  }

  // ✅ CONVERTE Firestore para Usuario
  Usuario _usuarioFromFirestore(String docId, Map<String, dynamic> data) {
    return Usuario(
      id: docId,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      telefone: data['telefone'],
      fotoUrl: data['fotoUrl'],
      perfil: _perfilFromFirestore(data['perfil'] ?? {}),
      dataCriacao: _timestampToDateTime(data['dataCriacao']),
      dataAtualizacao: _timestampToDateTime(data['dataAtualizacao']),
      ultimoAcesso: _timestampToDateTime(data['ultimoAcesso']),
      ativo: data['ativo'] ?? true,
      emailVerificado: data['emailVerificado'] ?? false,
      isAdmin: false,
    );
  }

  // ✅ CONVERTE Perfil do Firestore
  PerfilUsuario _perfilFromFirestore(dynamic perfilData) {
    if (perfilData is Map<String, dynamic>) {
      return PerfilUsuario(
        id: perfilData['id']?.toString() ?? '',
        nome: perfilData['nome']?.toString() ?? '',
        descricao: perfilData['descricao']?.toString() ?? '',
        permissoes: _parsePermissoes(perfilData['permissoes']),
        dataCriacao: _timestampToDateTime(perfilData['dataCriacao']),
        dataAtualizacao: _timestampToDateTime(perfilData['dataAtualizacao']),
        ativo: perfilData['ativo'] ?? true,
      );
    }
    // Retorna um perfil padrão se não houver dados
    return PerfilUsuario(
      id: 'default',
      nome: 'Perfil Padrão',
      descricao: 'Perfil temporário',
      permissoes: [],
      dataCriacao: DateTime.now(),
      ativo: true,
    );
  }

  // ✅ CONVERTE Usuario para Firestore
  // ✅ CONVERTE Usuario para Firestore (ATUALIZADO)
  Map<String, dynamic> _usuarioToFirestore(Usuario usuario) {
    return {
      'nome': usuario.nome,
      'email': usuario.email,
      'telefone': usuario.telefone,
      'fotoUrl': usuario.fotoUrl,
      'perfil': _perfilToFirestore(usuario.perfil),
      'ativo': usuario.ativo,
      'emailVerificado': usuario.emailVerificado,
      'isAdmin': usuario.isAdmin,
      'temSenhaDefinida': usuario.temSenhaDefinida ?? false, // ✅ SALVAR FLAG
      'uidFirebase': usuario.uidFirebase, // ✅ SALVAR UID FIREBASE
    };
  }

  // ✅ CONVERTE Perfil para Firestore
  Map<String, dynamic> _perfilToFirestore(PerfilUsuario perfil) {
    return {
      'id': perfil.id,
      'nome': perfil.nome,
      'descricao': perfil.descricao,
      'permissoes': perfil.permissoes.map((p) => p.codigo).toList(),
      'ativo': perfil.ativo,
    };
  }

  // ✅ CONVERTE Timestamp para DateTime
  DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  // ✅ CORRIGIDO: Conversão de permissões com tipo correto
  List<PermissaoUsuario> _parsePermissoes(dynamic permissoes) {
    final List<PermissaoUsuario> result = [];

    if (permissoes is List) {
      for (var permissao in permissoes) {
        final permissaoEnum = _permissaoFromString(permissao.toString());
        if (permissaoEnum != null) {
          result.add(permissaoEnum);
        }
      }
    }

    return result;
  }

  // ✅ CORRIGIDO: Conversão de string para PermissaoUsuario
  PermissaoUsuario? _permissaoFromString(String codigo) {
    try {
      return PermissaoUsuario.values.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      return null;
    }
  }

  // ✅ MÉTODO NOVO: Resetar senha do usuário
  Future<void> resetarSenhaUsuario(String email) async {
    try {
      await _authService.resetarSenhaUsuario(email);
    } catch (e) {
      throw Exception('Erro ao resetar senha: $e');
    }
  }

  // ✅ MÉTODO NOVO: Verificar se usuário tem senha definida
  Future<bool> usuarioTemSenhaDefinida(String userId) async {
    return await _authService.usuarioTemSenhaDefinida(userId);
  }

  // ✅ MÉTODO NOVO: Enviar convite para definir senha
  Future<void> enviarConviteSenha(String email) async {
    try {
      await _authService.enviarConviteSenha(email);
    } catch (e) {
      throw Exception('Erro ao enviar convite: $e');
    }
  }

  // ✅ MÉTODO: Inativar usuário (Auth + Firestore)
  Future<void> inativarUsuario(String userId) async {
    try {
      print('🔄 [USUARIO SERVICE] Inativando usuário: $userId');
      await _authService.inativarUsuario(userId);
      print('✅ [USUARIO SERVICE] Usuário inativado com sucesso');
    } catch (e) {
      print('❌ [USUARIO SERVICE] Erro ao inativar usuário: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO: Reativar usuário (Auth + Firestore)
  Future<void> reativarUsuario(String userId) async {
    try {
      print('🔄 [USUARIO SERVICE] Reativando usuário: $userId');
      await _authService.reativarUsuario(userId);
      print('✅ [USUARIO SERVICE] Usuário reativado com sucesso');
    } catch (e) {
      print('❌ [USUARIO SERVICE] Erro ao reativar usuário: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO: Alterar senha do usuário
  Future<void> alterarSenhaUsuario(String userId, String novaSenha) async {
    try {
      print('🔐 [USUARIO SERVICE] Alterando senha do usuário: $userId');
      await _authService.alterarSenhaUsuario(
        userId: userId,
        novaSenha: novaSenha,
      );
      print('✅ [USUARIO SERVICE] Senha alterada com sucesso');
    } catch (e) {
      print('❌ [USUARIO SERVICE] Erro ao alterar senha: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO: Definir senha (alias para alterarSenhaUsuario)
  Future<void> definirSenhaUsuario(String userId, String senha) async {
    await alterarSenhaUsuario(userId, senha);
  }
}
