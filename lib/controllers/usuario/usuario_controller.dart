// controllers/usuario_controller.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/base/base_controller.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/services/usuario/usuario_service.dart';

class UsuarioController extends BaseController<Usuario> {
  final UsuarioService _service = UsuarioService();

  UsuarioController() {
    // Carrega os usuários automaticamente quando o controller é criado
    loadItems();
  }

  @override
  Future<void> loadItems() async {
    try {
      setLoading(true);
      final lista = await _service.getUsuarios();
      items = lista;
    } catch (e) {
      print('Erro ao carregar usuários: $e');
    } finally {
      setLoading(false);
    }
  }

  @override
  Future<bool> saveItem(Usuario usuario) async {
    try {
      setLoading(true);
      await _service.saveUsuario(usuario);
      await loadItems(); // Recarrega a lista para garantir dados atualizados
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
      removeItem(usuario);
      return true;
    } catch (e) {
      print('Erro ao excluir usuário: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Métodos específicos do UsuarioController
  Future<bool> toggleUserStatus(Usuario usuario) async {
    final novoUsuario = usuario.copyWith(ativo: !usuario.ativo);
    return await saveItem(novoUsuario);
  }

  List<Usuario> get usuariosAtivos {
    return items.where((usuario) => usuario.ativo).toList();
  }

  List<Usuario> get usuariosInativos {
    return items.where((usuario) => !usuario.ativo).toList();
  }

  Usuario? findUsuarioById(String id) {
    try {
      return items.firstWhere((usuario) => usuario.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Usuario> searchUsuarios(String query) {
    if (query.isEmpty) return items;

    return items.where((usuario) {
      return usuario.nome.toLowerCase().contains(query.toLowerCase()) ||
          usuario.email.toLowerCase().contains(query.toLowerCase()) ||
          usuario.perfil.nome.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
