// controllers/perfil/perfil_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/controllers/base/base_controller.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/services/perfil/perfil_service.dart';

class PerfilController extends BaseController<PerfilUsuario> {
  final PerfilService _service = PerfilService();

  List<PerfilUsuario> _perfisAtivos = [];
  int _currentPage = 0;
  int _totalItems = 0;
  bool _hasMoreItems = true;
  final int _itemsPerPage = 20;
  DocumentSnapshot? _lastDocument;

  List<PerfilUsuario> get perfisAtivos => _perfisAtivos;
  int get totalItems => _totalItems;
  bool get hasMoreItems => _hasMoreItems;

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

      final lista = await _service.getPerfis(
        page: _currentPage + 1,
        limit: _itemsPerPage,
        lastDocument: _lastDocument,
      );

      if (reset) {
        items = lista;
      } else {
        items.addAll(lista);
      }

      _currentPage++;
      _updatePerfisAtivos();

      // ✅ CORREÇÃO: Atualiza o total de itens sem usar !
      await _updateTotalCount();

      _hasMoreItems = lista.length == _itemsPerPage;
    } catch (e) {
      print('Erro ao carregar perfis: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _updateTotalCount() async {
    try {
      _totalItems = await _service.getTotalPerfis(); // ✅ Agora é int, não int?
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

      // ✅ CORREÇÃO: Recarrega a lista completa para garantir consistência
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

      // ✅ CORREÇÃO: Recarrega a lista completa para garantir consistência
      await loadItems(reset: true);

      return true;
    } catch (e) {
      print('Erro ao excluir perfil: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ✅ ADICIONE: Método específico para salvar (usado no form)
  Future<bool> savePerfil(PerfilUsuario perfil) async {
    return await saveItem(perfil);
  }

  // Métodos específicos do PerfilController
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

  // Método para resetar a lista
  void reset() {
    _currentPage = 0;
    items = [];
    _perfisAtivos = [];
    _hasMoreItems = true;
    _totalItems = 0;
    _lastDocument = null;
    notifyListeners();
  }

  // Método para carregar perfis ativos (para dropdowns)
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

  // ✅ ADICIONE: Método para obter perfil por ID
  PerfilUsuario? getPerfilById(String id) {
    try {
      return items.firstWhere((perfil) => perfil.id == id);
    } catch (e) {
      return null;
    }
  }
}
