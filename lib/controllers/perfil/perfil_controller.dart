// controllers/perfil_controller.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/base/base_controller.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/services/perfil/perfil_service.dart';

class PerfilController extends BaseController<PerfilUsuario> {
  final PerfilService _service = PerfilService();

  List<PerfilUsuario> _perfisAtivos = [];

  List<PerfilUsuario> get perfisAtivos => _perfisAtivos;

  PerfilController() {
    loadItems();
  }

  @override
  Future<void> loadItems() async {
    try {
      setLoading(true);
      final lista = await _service.getPerfis();
      items = lista;
      _updatePerfisAtivos();
    } catch (e) {
      print('Erro ao carregar perfis: $e');
    } finally {
      setLoading(false);
    }
  }

  @override
  Future<bool> saveItem(PerfilUsuario perfil) async {
    try {
      setLoading(true);
      await _service.savePerfil(perfil);
      await loadItems(); // Recarrega a lista
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
      removeItem(perfil);
      _updatePerfisAtivos();
      return true;
    } catch (e) {
      print('Erro ao excluir perfil: $e');
      return false;
    } finally {
      setLoading(false);
    }
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
}
