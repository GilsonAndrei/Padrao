// services/usuario_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usuariosCollection = FirebaseFirestore.instance
      .collection('usuarios');

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

  Future<void> saveUsuario(Usuario usuario) async {
    try {
      final usuarioData = _usuarioToFirestore(usuario);

      if (usuario.id.isEmpty || usuario.id == 'null') {
        // Novo usuário
        final docRef = _usuariosCollection.doc();
        await docRef.set({
          ...usuarioData,
          'dataCriacao': FieldValue.serverTimestamp(),
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      } else {
        // Usuário existente
        if (usuario.id.isNotEmpty && usuario.id != 'null') {
          await _usuariosCollection.doc(usuario.id).update({
            ...usuarioData,
            'dataAtualizacao': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception('ID de usuário inválido: ${usuario.id}');
        }
      }
    } catch (e) {
      throw Exception('Erro ao salvar usuário: $e');
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
  Map<String, dynamic> _usuarioToFirestore(Usuario usuario) {
    return {
      'nome': usuario.nome,
      'email': usuario.email,
      'telefone': usuario.telefone,
      'fotoUrl': usuario.fotoUrl,
      'perfil': _perfilToFirestore(usuario.perfil),
      'ativo': usuario.ativo,
      'emailVerificado': usuario.emailVerificado,
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
}
