// services/perfil/perfil_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/paginated_response.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';

class PerfilService {
  final CollectionReference _perfisCollection = FirebaseFirestore.instance
      .collection(AppConstants.profilesCollection);

  // ✅ MÉTODO UNIFICADO PARA BUSCA PAGINADA
  Future<PaginatedResponse<PerfilUsuario>> searchPerfis({
    String searchTerm = '',
    int page = 1,
    int pageSize = 20,
    bool apenasAtivos = false,
  }) async {
    try {
      // ✅ VALIDAÇÃO DE PARÂMETROS
      if (page < 1) throw ArgumentError('Page deve ser maior que 0');
      final effectiveLimit = pageSize > 0 ? pageSize : 20;

      Query query = _perfisCollection;

      // ✅ APLICAR FILTROS
      if (apenasAtivos) {
        query = query.where('ativo', isEqualTo: true);
      }

      if (searchTerm.isNotEmpty) {
        query = query
            .where('nome', isGreaterThanOrEqualTo: searchTerm)
            .where('nome', isLessThan: searchTerm + 'z');
      }

      // ✅ ORDENAÇÃO E LIMITE
      query = query.orderBy('nome').limit(effectiveLimit);

      // ✅ PAGINAÇÃO
      if (page > 1) {
        Query previousPageQuery = _perfisCollection;

        if (apenasAtivos) {
          previousPageQuery = previousPageQuery.where('ativo', isEqualTo: true);
        }

        if (searchTerm.isNotEmpty) {
          previousPageQuery = previousPageQuery
              .where('nome', isGreaterThanOrEqualTo: searchTerm)
              .where('nome', isLessThan: searchTerm + 'z');
        }

        final previousQuery = previousPageQuery
            .orderBy('nome')
            .limit((page - 1) * effectiveLimit);

        final previousSnapshot = await previousQuery.get();
        if (previousSnapshot.docs.isNotEmpty) {
          final lastDoc = previousSnapshot.docs.last;
          query = query.startAfterDocument(lastDoc);
        }
      }

      // ✅ EXECUTAR CONSULTA
      final querySnapshot = await query.get();

      // ✅ CALCULAR TOTAL DE ITENS
      Query totalQuery = _perfisCollection;

      if (apenasAtivos) {
        totalQuery = totalQuery.where('ativo', isEqualTo: true);
      }

      if (searchTerm.isNotEmpty) {
        totalQuery = totalQuery
            .where('nome', isGreaterThanOrEqualTo: searchTerm)
            .where('nome', isLessThan: searchTerm + 'z');
      }

      final totalSnapshot = await totalQuery.count().get();
      final totalItems = totalSnapshot.count;
      final totalPages = (totalItems! / effectiveLimit).ceil();

      // ✅ CONVERTER RESULTADOS
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

  // ✅ MÉTODO PARA PAGINAÇÃO BASEADA EM CURSOR (RECOMENDADO)
  Future<PaginatedResponse<PerfilUsuario>> searchPerfisWithCursor({
    String searchTerm = '',
    DocumentSnapshot? lastDocument,
    int limit = 20,
    bool apenasAtivos = false,
  }) async {
    try {
      // ✅ VALIDAÇÃO DE PARÂMETROS
      final effectiveLimit = limit > 0 ? limit : 20;

      Query query = _perfisCollection;

      // ✅ APLICAR FILTROS
      if (apenasAtivos) {
        query = query.where('ativo', isEqualTo: true);
      }

      if (searchTerm.isNotEmpty) {
        query = query
            .where('nome', isGreaterThanOrEqualTo: searchTerm)
            .where('nome', isLessThan: searchTerm + 'z');
      }

      // ✅ ORDENAÇÃO E LIMITE
      query = query.orderBy('nome').limit(effectiveLimit);

      // ✅ APLICAR CURSOR PARA PAGINAÇÃO
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // ✅ EXECUTAR CONSULTA
      final querySnapshot = await query.get();

      // ✅ CONVERTER RESULTADOS
      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _perfilFromFirestore(doc.id, data);
      }).toList();

      // ✅ USANDO O CONSTRUTOR DE CURSOR
      return PaginatedResponse<PerfilUsuario>.cursorBased(
        items: items,
        hasNextPage: items.length == effectiveLimit,
        lastDocument: querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.last
            : null,
        hasPreviousPage: lastDocument != null,
      );
    } catch (e) {
      throw Exception('Erro ao buscar perfis: $e');
    }
  }

  // ✅ MÉTODOS DE CONVENIÊNCIA (para compatibilidade)
  Future<PaginatedResponse<PerfilUsuario>> searchPerfisAtivos({
    String searchTerm = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    return searchPerfis(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
      apenasAtivos: true,
    );
  }

  Future<PaginatedResponse<PerfilUsuario>> searchPerfisAtivosWithCursor({
    String searchTerm = '',
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    return searchPerfisWithCursor(
      searchTerm: searchTerm,
      lastDocument: lastDocument,
      limit: limit,
      apenasAtivos: true,
    );
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
      return countQuery.count ?? 0; // ✅ CORREÇÃO: Null check
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
      return countQuery.count ?? 0; // ✅ CORREÇÃO: Null check
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
