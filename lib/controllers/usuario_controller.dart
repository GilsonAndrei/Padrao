// controllers/usuario_controller.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/repositories/usuario_repository.dart';
import 'package:projeto_padrao/controllers/generic_search_controller.dart';

class UsuarioController extends GenericSearchController<Usuario> {
  final UsuarioRepository _usuarioRepository;

  UsuarioController()
    : _usuarioRepository = UsuarioRepository(),
      super(repository: UsuarioRepository());

  // Métodos específicos para usuários
  Future<void> toggleAtivo(Usuario usuario) async {
    final updatedUser = usuario.copyWith(
      ativo: !usuario.ativo,
      dataAtualizacao: DateTime.now(),
    );

    await _usuarioRepository.collection
        .doc(usuario.id)
        .update(updatedUser.toMap());

    // Atualiza a lista local
    final index = items.indexWhere((u) => u.id == usuario.id);
    if (index != -1) {
      items[index] = updatedUser;
      notifyListeners();
    }
  }

  Future<void> deleteUsuario(String id) async {
    await _usuarioRepository.collection.doc(id).update({
      'ativo': false,
      'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
    });

    // Remove da lista local
    items.removeWhere((usuario) => usuario.id == id);
    notifyListeners();
  }
}
