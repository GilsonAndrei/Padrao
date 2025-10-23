// controllers/perfil/perfil_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/controllers/base/base_controller.dart';
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/models/paginated_response.dart';
import 'package:projeto_padrao/services/perfil/perfil_service.dart';

class PerfilController extends BaseController<PerfilUsuario> {
  final PerfilService _service = PerfilService();

  List<PerfilUsuario> _perfisAtivos = [];
  int _currentPage = 0;
  int _totalItems = 0;
  bool _hasMoreItems = true;
  final int _itemsPerPage = AppConstants.itemsPerPageProfile;
  DocumentSnapshot? _lastDocument;

  List<PerfilUsuario> get perfisAtivos => _perfisAtivos;
  int get totalItems => _totalItems;
  bool get hasMoreItems => _hasMoreItems;
  DocumentSnapshot? get lastDocument => _lastDocument;

  PerfilController() {
    loadItems();
  }

  @override
  Future<void> loadItems({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      items = [];
      _perfisAtivos = [];
      _hasMoreItems = true;
      _totalItems = 0;
      _lastDocument = null;
    }

    if (isLoading || !_hasMoreItems) return;

    try {
      setLoading(true);

      // ✅ USANDO PAGINAÇÃO COM CURSOR (MAIS EFICIENTE)
      final PaginatedResponse<PerfilUsuario> response = await _service
          .searchPerfisWithCursor(
            limit: _itemsPerPage,
            lastDocument: _lastDocument,
          );

      if (reset) {
        items = response.items;
      } else {
        items.addAll(response.items);
      }

      _currentPage++;
      _lastDocument = response.lastDocument;
      _hasMoreItems = response.hasNextPage;

      _updatePerfisAtivos();

      // ✅ ATUALIZA CONTAGEM TOTAL
      await _updateTotalCount();
    } catch (e) {
      print('Erro ao carregar perfis: $e');
    } finally {
      setLoading(false);
    }
  }

  // ✅ ALTERNATIVA: Método com paginação numérica (se preferir)
  Future<void> loadItemsWithNumericPagination({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      items = [];
      _perfisAtivos = [];
      _hasMoreItems = true;
      _totalItems = 0;
    }

    if (isLoading || !_hasMoreItems) return;

    try {
      setLoading(true);

      final PaginatedResponse<PerfilUsuario> response = await _service
          .searchPerfis(page: _currentPage + 1, pageSize: _itemsPerPage);

      if (reset) {
        items = response.items;
      } else {
        items.addAll(response.items);
      }

      _currentPage = response.currentPage;
      _totalItems = response.totalItems;
      _hasMoreItems = response.hasNextPage;

      _updatePerfisAtivos();
    } catch (e) {
      print('Erro ao carregar perfis: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _updateTotalCount() async {
    try {
      _totalItems = await _service.getTotalPerfis();
    } catch (e) {
      print('Erro ao contar perfis: $e');
      _totalItems = items.length;
    }
  }

  Future<void> loadMore() async {
    if (!isLoading && _hasMoreItems) {
      await loadItems();
    }
  }

  @override
  Future<bool> saveItem(PerfilUsuario perfil) async {
    try {
      setLoading(true);
      await _service.savePerfil(perfil);

      // ✅ RECARREGA A LISTA COMPLETA PARA GARANTIR CONSISTÊNCIA
      await loadItems(reset: true);

      return true;
    } catch (e) {
      print('Erro ao salvar perfil: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  Future<bool> deleteItem(PerfilUsuario perfil) async {
    try {
      setLoading(true);
      await _service.deletePerfil(perfil.id);

      // ✅ RECARREGA A LISTA COMPLETA PARA GARANTIR CONSISTÊNCIA
      await loadItems(reset: true);

      return true;
    } catch (e) {
      print('Erro ao excluir perfil: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ✅ MÉTODO ESPECÍFICO PARA SALVAR (USADO NO FORM)
  Future<bool> savePerfil(PerfilUsuario perfil) async {
    return await saveItem(perfil);
  }

  // ✅ MÉTODOS ESPECÍFICOS DO PERFILCONTROLLER
  void _updatePerfisAtivos() {
    _perfisAtivos = items.where((perfil) => perfil.ativo).toList();
    notifyListeners();
  }

  Future<bool> togglePerfilStatus(PerfilUsuario perfil) async {
    final novoPerfil = perfil.copyWith(ativo: !perfil.ativo);
    final success = await saveItem(novoPerfil);
    if (success) {
      _updatePerfisAtivos();
    }
    return success;
  }

  List<PerfilUsuario> searchPerfis(String query) {
    if (query.isEmpty) return items;

    return items.where((perfil) {
      return perfil.nome.toLowerCase().contains(query.toLowerCase()) ||
          perfil.descricao.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // ✅ MÉTODO PARA RESETAR A LISTA
  void reset() {
    _currentPage = 0;
    items = [];
    _perfisAtivos = [];
    _hasMoreItems = true;
    _totalItems = 0;
    _lastDocument = null;
    notifyListeners();
  }

  // ✅ MÉTODO PARA CARREGAR PERFIS ATIVOS (PARA DROPDOWNS)
  Future<void> loadPerfisAtivos() async {
    try {
      setLoading(true);
      final perfisAtivos = await _service.getPerfisAtivos(limit: 100);
      _perfisAtivos = perfisAtivos;
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar perfis ativos: $e');
    } finally {
      setLoading(false);
    }
  }

  // ✅ MÉTODO PARA OBTER PERFIL POR ID
  PerfilUsuario? getPerfilById(String id) {
    try {
      return items.firstWhere((perfil) => perfil.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ NOVO: BUSCA AVANÇADA COM FILTROS
  Future<PaginatedResponse<PerfilUsuario>> searchPerfisAvancado({
    String searchTerm = '',
    int page = 1,
    int pageSize = 20,
    bool apenasAtivos = false,
  }) async {
    try {
      return await _service.searchPerfis(
        searchTerm: searchTerm,
        page: page,
        pageSize: pageSize,
        apenasAtivos: apenasAtivos,
      );
    } catch (e) {
      print('Erro na busca avançada: $e');
      return PaginatedResponse<PerfilUsuario>(
        items: [],
        currentPage: page,
        totalPages: 0,
        totalItems: 0,
        hasNextPage: false,
      );
    }
  }
}
