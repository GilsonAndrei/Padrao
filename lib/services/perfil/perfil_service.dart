// services/perfil/perfil_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';

class PerfilService {
  final CollectionReference _perfisCollection = FirebaseFirestore.instance
      .collection('perfis');

  Future<List<PerfilUsuario>> getPerfis({
    int page = 1,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // ✅ CORREÇÃO: Garantir que o limite seja sempre positivo
      final effectiveLimit = limit > 0 ? limit : 20;

      Query query = _perfisCollection
          .orderBy('dataCriacao', descending: true)
          .limit(effectiveLimit);

      // Para paginação, usa o último documento carregado
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar perfis: $e');
    }
  }

  // ✅ CORREÇÃO: Método para contar o total de perfis com tratamento de null
  Future<int> getTotalPerfis() async {
    try {
      final countQuery = await _perfisCollection.count().get();
      return countQuery.count ?? 0; // ✅ Usa ?? para fornecer valor padrão
    } catch (e) {
      print('Erro ao contar perfis: $e');
      return 0; // ✅ Retorna 0 em caso de erro
    }
  }

  // Método para buscar perfis com filtro (para search)
  Future<List<PerfilUsuario>> searchPerfis({
    required String searchTerm,
    int limit = 20,
  }) async {
    try {
      // ✅ CORREÇÃO: Garantir que o limite seja sempre positivo
      final effectiveLimit = limit > 0 ? limit : 20;

      if (searchTerm.isEmpty) {
        return getPerfis(limit: effectiveLimit);
      }

      final querySnapshot = await _perfisCollection
          .where('nome', isGreaterThanOrEqualTo: searchTerm)
          .where('nome', isLessThan: searchTerm + 'z')
          .orderBy('nome')
          .limit(effectiveLimit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar perfis: $e');
    }
  }

  Future<void> savePerfil(PerfilUsuario perfil) async {
    try {
      final perfilData = _perfilToFirestore(perfil);

      if (perfil.id.isEmpty || perfil.id == 'null') {
        // Novo perfil
        final docRef = _perfisCollection.doc();
        await docRef.set({
          ...perfilData,
          'dataCriacao': FieldValue.serverTimestamp(),
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      } else {
        // Perfil existente
        if (perfil.id.isNotEmpty && perfil.id != 'null') {
          await _perfisCollection.doc(perfil.id).update({
            ...perfilData,
            'dataAtualizacao': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception('ID de perfil inválido: ${perfil.id}');
        }
      }
    } catch (e) {
      throw Exception('Erro ao salvar perfil: $e');
    }
  }

  Future<void> deletePerfil(String id) async {
    try {
      if (id.isEmpty || id == 'null') {
        throw Exception('ID inválido para exclusão: $id');
      }
      await _perfisCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao excluir perfil: $e');
    }
  }

  // Buscar perfil por ID
  Future<PerfilUsuario?> getPerfilById(String id) async {
    try {
      final doc = await _perfisCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar perfil por ID: $e');
    }
  }

  // Buscar perfis ativos com paginação
  Future<List<PerfilUsuario>> getPerfisAtivos({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // ✅ CORREÇÃO: Garantir que o limite seja sempre positivo
      final effectiveLimit = limit > 0 ? limit : 20;

      Query query = _perfisCollection
          .where('ativo', isEqualTo: true)
          .orderBy('nome')
          .limit(effectiveLimit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar perfis ativos: $e');
    }
  }

  // ✅ CORREÇÃO: Contar perfis ativos com tratamento de null
  Future<int> getTotalPerfisAtivos() async {
    try {
      final countQuery = await _perfisCollection
          .where('ativo', isEqualTo: true)
          .count()
          .get();
      return countQuery.count ?? 0; // ✅ Usa ?? para fornecer valor padrão
    } catch (e) {
      print('Erro ao contar perfis ativos: $e');
      return 0; // ✅ Retorna 0 em caso de erro
    }
  }

  // ✅ CONVERTE Firestore para PerfilUsuario
  PerfilUsuario _perfilFromFirestore(String docId, Map<String, dynamic> data) {
    return PerfilUsuario(
      id: docId,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      permissoes: _parsePermissoes(data['permissoes']),
      dataCriacao: _timestampToDateTime(data['dataCriacao']),
      dataAtualizacao: _timestampToDateTime(data['dataAtualizacao']),
      ativo: data['ativo'] ?? true,
    );
  }

  // ✅ CONVERTE PerfilUsuario para Firestore
  Map<String, dynamic> _perfilToFirestore(PerfilUsuario perfil) {
    return {
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
