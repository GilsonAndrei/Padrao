// controllers/usuario/usuario_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/base/base_controller.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/paginated_response.dart';
import 'package:projeto_padrao/services/usuario/usuario_service.dart';

class UsuarioController extends BaseController<Usuario> {
  final UsuarioService _service = UsuarioService();

  int _currentPage = 0;
  int _totalItems = 0;
  bool _hasMoreItems = true;
  final int _itemsPerPage = 20; // ✅ MESMO PADRÃO DO PERFIL
  DocumentSnapshot? _lastDocument;

  int get totalItems => _totalItems;
  bool get hasMoreItems => _hasMoreItems;
  DocumentSnapshot? get lastDocument => _lastDocument;

  UsuarioController() {
    loadItems();
  }

  @override
  Future<void> loadItems({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      items = [];
      _hasMoreItems = true;
      _totalItems = 0;
      _lastDocument = null;
    }

    if (isLoading || !_hasMoreItems) return;

    try {
      setLoading(true);

      // ✅ USANDO PAGINAÇÃO COM CURSOR (MAIS EFICIENTE)
      final PaginatedResponse<Usuario> response = await _service
          .searchUsuariosWithCursor(
            limit: _itemsPerPage,
            lastDocument: _lastDocument,
            apenasAtivos: true,
          );

      if (reset) {
        items = response.items;
      } else {
        items.addAll(response.items);
      }

      _currentPage++;
      _lastDocument = response.lastDocument;
      _hasMoreItems = response.hasNextPage;

      // ✅ ATUALIZA CONTAGEM TOTAL
      await _updateTotalCount();
    } catch (e) {
      print('Erro ao carregar usuários: $e');
    } finally {
      setLoading(false);
    }
  }

  // ✅ ALTERNATIVA: Método com paginação numérica
  Future<void> loadItemsWithNumericPagination({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      items = [];
      _hasMoreItems = true;
      _totalItems = 0;
    }

    if (isLoading || !_hasMoreItems) return;

    try {
      setLoading(true);

      final PaginatedResponse<Usuario> response = await _service.searchUsuarios(
        page: _currentPage + 1,
        pageSize: _itemsPerPage,
        apenasAtivos: true,
      );

      if (reset) {
        items = response.items;
      } else {
        items.addAll(response.items);
      }

      _currentPage = response.currentPage;
      _totalItems = response.totalItems;
      _hasMoreItems = response.hasNextPage;
    } catch (e) {
      print('Erro ao carregar usuários: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _updateTotalCount() async {
    try {
      _totalItems = await _service.getTotalUsuarios(apenasAtivos: true);
    } catch (e) {
      print('Erro ao contar usuários: $e');
      _totalItems = items.length;
    }
  }

  Future<void> loadMore() async {
    if (!isLoading && _hasMoreItems) {
      await loadItems();
    }
  }

  @override
  Future<bool> saveItem(Usuario usuario, {String? senha}) async {
    try {
      setLoading(true);
      await _service.saveUsuario(usuario, senha: senha);

      // ✅ RECARREGA A LISTA COMPLETA PARA GARANTIR CONSISTÊNCIA
      await loadItems(reset: true);

      return true;
    } catch (e) {
      print('Erro ao salvar usuário: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  Future<bool> deleteItem(Usuario usuario) async {
    try {
      setLoading(true);
      await _service.deleteUsuario(usuario.id);

      // ✅ RECARREGA A LISTA COMPLETA PARA GARANTIR CONSISTÊNCIA
      await loadItems(reset: true);

      return true;
    } catch (e) {
      print('Erro ao excluir usuário: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ✅ MÉTODO ESPECÍFICO PARA SALVAR (USADO NO FORM)
  Future<bool> saveUsuario(Usuario usuario, {String? senha}) async {
    return await saveItem(usuario, senha: senha);
  }

  // ✅ MÉTODO PARA ALTERNAR STATUS DO USUÁRIO
  Future<bool> toggleUserStatus(Usuario usuario) async {
    try {
      final updatedUser = usuario.copyWith(ativo: !usuario.ativo);
      final success = await saveItem(updatedUser);
      return success;
    } catch (e) {
      print('Erro ao alternar status do usuário: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA BUSCA LOCAL
  List<Usuario> searchUsuarios(String query) {
    if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
    return items.where((usuario) {
      return usuario.nome.toLowerCase().contains(lowercaseQuery) ||
          usuario.email.toLowerCase().contains(lowercaseQuery) ||
          usuario.perfil.nome.toLowerCase().contains(lowercaseQuery) ||
          (usuario.telefone?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // ✅ MÉTODO PARA RESETAR A LISTA
  void reset() {
    _currentPage = 0;
    items = [];
    _hasMoreItems = true;
    _totalItems = 0;
    _lastDocument = null;
    notifyListeners();
  }

  // ✅ MÉTODO PARA OBTER USUÁRIO POR ID
  Usuario? getUsuarioById(String id) {
    try {
      return items.firstWhere((usuario) => usuario.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ NOVO: BUSCA AVANÇADA COM FILTROS
  Future<PaginatedResponse<Usuario>> searchUsuariosAvancado({
    String searchTerm = '',
    int page = 1,
    int pageSize = 20,
    bool apenasAtivos = true,
  }) async {
    try {
      return await _service.searchUsuarios(
        searchTerm: searchTerm,
        page: page,
        pageSize: pageSize,
        apenasAtivos: apenasAtivos,
      );
    } catch (e) {
      print('Erro na busca avançada: $e');
      return PaginatedResponse<Usuario>(
        items: [],
        currentPage: page,
        totalPages: 0,
        totalItems: 0,
        hasNextPage: false,
      );
    }
  }

  // ✅ MÉTODOS DE GESTÃO DE SENHA
  Future<bool> resetarSenha(String email) async {
    try {
      await _service.resetarSenhaUsuario(email);
      return true;
    } catch (e) {
      print('Erro ao resetar senha: $e');
      return false;
    }
  }

  Future<bool> enviarConviteSenha(String email) async {
    try {
      await _service.enviarConviteSenha(email);
      return true;
    } catch (e) {
      print('Erro ao enviar convite: $e');
      return false;
    }
  }

  Future<bool> definirSenha(String userId, String senha) async {
    try {
      await _service.definirSenhaUsuario(userId, senha);
      return true;
    } catch (e) {
      print('Erro ao definir senha: $e');
      return false;
    }
  }

  // ✅ MÉTODOS DE ATIVAÇÃO/INATIVAÇÃO
  Future<bool> inativarUsuario(String userId) async {
    try {
      await _service.inativarUsuario(userId);
      await loadItems(reset: true); // Recarrega a lista
      return true;
    } catch (e) {
      print('Erro ao inativar usuário: $e');
      return false;
    }
  }

  Future<bool> reativarUsuario(String userId) async {
    try {
      await _service.reativarUsuario(userId);
      await loadItems(reset: true); // Recarrega a lista
      return true;
    } catch (e) {
      print('Erro ao reativar usuário: $e');
      return false;
    }
  }
}
