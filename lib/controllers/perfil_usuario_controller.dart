// controllers/perfil_usuario_controller.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/repositories/perfil_usuario_repository.dart';
import 'package:projeto_padrao/controllers/generic_search_controller.dart';

class PerfilUsuarioController extends GenericSearchController<PerfilUsuario> {
  final PerfilUsuarioRepository _perfilRepository;

  PerfilUsuarioController()
    : _perfilRepository = PerfilUsuarioRepository(),
      super(repository: PerfilUsuarioRepository());

  // Métodos específicos para perfis
  Future<void> toggleAtivo(PerfilUsuario perfil) async {
    final updatedPerfil = perfil.copyWith(
      ativo: !perfil.ativo,
      dataAtualizacao: DateTime.now(),
    );

    await _perfilRepository.collection
        .doc(perfil.id)
        .update(updatedPerfil.toMap());

    // Atualiza a lista local
    final index = items.indexWhere((p) => p.id == perfil.id);
    if (index != -1) {
      items[index] = updatedPerfil;
      notifyListeners();
    }
  }

  Future<void> deletePerfil(String id) async {
    await _perfilRepository.collection.doc(id).update({
      'ativo': false,
      'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
    });

    // Remove da lista local
    items.removeWhere((perfil) => perfil.id == id);
    notifyListeners();
  }
}
