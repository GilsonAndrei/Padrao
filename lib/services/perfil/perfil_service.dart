// services/perfil/perfil_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/paginated_response.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';

class PerfilService {
  final CollectionReference _perfisCollection = FirebaseFirestore.instance
      .collection(AppConstants.profilesCollection);

  // ✅ MÉTODO PARA BUSCA PAGINADA GENÉRICA
  Future<PaginatedResponse<PerfilUsuario>> searchPerfis({
    required String searchTerm,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      // ✅ CORREÇÃO: Garantir que o pageSize seja sempre positivo
      final effectiveLimit = pageSize > 0 ? pageSize : 20;
      final startIndex = (page - 1) * effectiveLimit;

      Query query = _perfisCollection.orderBy('nome').limit(effectiveLimit);

      // Aplicar filtro de busca se houver termo
      if (searchTerm.isNotEmpty) {
        query = _perfisCollection
            .where('nome', isGreaterThanOrEqualTo: searchTerm)
            .where('nome', isLessThan: searchTerm + 'z')
            .orderBy('nome')
            .limit(effectiveLimit);
      }

      // Para paginação além da primeira página
      if (startIndex > 0) {
        // Precisamos buscar os documentos anteriores para usar startAfter
        final previousPageQuery = _perfisCollection
            .orderBy('nome')
            .limit(startIndex);

        final previousSnapshot = await previousPageQuery.get();
        if (previousSnapshot.docs.isNotEmpty) {
          final lastDoc = previousSnapshot.docs.last;
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();

      // Buscar o total de documentos para calcular paginação
      final totalQuery = searchTerm.isEmpty
          ? _perfisCollection
          : _perfisCollection
                .where('nome', isGreaterThanOrEqualTo: searchTerm)
                .where('nome', isLessThan: searchTerm + 'z');

      final totalSnapshot = await totalQuery.count().get();
      final totalItems = totalSnapshot.count ?? 0;
      final totalPages = (totalItems / effectiveLimit).ceil();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }).toList();

      return PaginatedResponse<PerfilUsuario>(
        items: items,
        currentPage: page,
        totalPages: totalPages,
        totalItems: totalItems,
        hasNextPage: page < totalPages,
      );
    } catch (e) {
      throw Exception('Erro ao buscar perfis: $e');
    }
  }

  // ✅ MÉTODO ALTERNATIVO: Busca apenas perfis ativos com paginação
  Future<PaginatedResponse<PerfilUsuario>> searchPerfisAtivos({
    required String searchTerm,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final effectiveLimit = pageSize > 0 ? pageSize : 20;
      final startIndex = (page - 1) * effectiveLimit;

      Query query = _perfisCollection
          .where('ativo', isEqualTo: true)
          .orderBy('nome')
          .limit(effectiveLimit);

      // Aplicar filtro de busca se houver termo
      if (searchTerm.isNotEmpty) {
        query = _perfisCollection
            .where('ativo', isEqualTo: true)
            .where('nome', isGreaterThanOrEqualTo: searchTerm)
            .where('nome', isLessThan: searchTerm + 'z')
            .orderBy('nome')
            .limit(effectiveLimit);
      }

      // Para paginação além da primeira página
      if (startIndex > 0) {
        final previousPageQuery = _perfisCollection
            .where('ativo', isEqualTo: true)
            .orderBy('nome')
            .limit(startIndex);

        final previousSnapshot = await previousPageQuery.get();
        if (previousSnapshot.docs.isNotEmpty) {
          final lastDoc = previousSnapshot.docs.last;
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();

      // Buscar o total de documentos ativos
      final totalQuery = searchTerm.isEmpty
          ? _perfisCollection.where('ativo', isEqualTo: true)
          : _perfisCollection
                .where('ativo', isEqualTo: true)
                .where('nome', isGreaterThanOrEqualTo: searchTerm)
                .where('nome', isLessThan: searchTerm + 'z');

      final totalSnapshot = await totalQuery.count().get();
      final totalItems = totalSnapshot.count ?? 0;
      final totalPages = (totalItems / effectiveLimit).ceil();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }).toList();

      return PaginatedResponse<PerfilUsuario>(
        items: items,
        currentPage: page,
        totalPages: totalPages,
        totalItems: totalItems,
        hasNextPage: page < totalPages,
      );
    } catch (e) {
      throw Exception('Erro ao buscar perfis ativos: $e');
    }
  }

  // ✅ MÉTODOS EXISTENTES (mantidos para compatibilidade)
  Future<List<PerfilUsuario>> getPerfis({
    int page = 1,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final effectiveLimit = limit > 0 ? limit : 20;

      Query query = _perfisCollection
          .orderBy('dataCriacao', descending: true)
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
      throw Exception('Erro ao carregar perfis: $e');
    }
  }

  Future<int> getTotalPerfis() async {
    try {
      final countQuery = await _perfisCollection.count().get();
      return countQuery.count ?? 0;
    } catch (e) {
      print('Erro ao contar perfis: $e');
      return 0;
    }
  }

  Future<void> savePerfil(PerfilUsuario perfil) async {
    try {
      final perfilData = _perfilToFirestore(perfil);

      if (perfil.id.isEmpty || perfil.id == 'null') {
        final docRef = _perfisCollection.doc();
        await docRef.set({
          ...perfilData,
          'dataCriacao': FieldValue.serverTimestamp(),
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      } else {
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

  Future<List<PerfilUsuario>> getPerfisAtivos({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
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

  Future<int> getTotalPerfisAtivos() async {
    try {
      final countQuery = await _perfisCollection
          .where('ativo', isEqualTo: true)
          .count()
          .get();
      return countQuery.count ?? 0;
    } catch (e) {
      print('Erro ao contar perfis ativos: $e');
      return 0;
    }
  }

  // ✅ MÉTODOS DE CONVERSÃO
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

  Map<String, dynamic> _perfilToFirestore(PerfilUsuario perfil) {
    return {
      'nome': perfil.nome,
      'descricao': perfil.descricao,
      'permissoes': perfil.permissoes.map((p) => p.codigo).toList(),
      'ativo': perfil.ativo,
    };
  }

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

  PermissaoUsuario? _permissaoFromString(String codigo) {
    try {
      return PermissaoUsuario.values.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      return null;
    }
  }
}
