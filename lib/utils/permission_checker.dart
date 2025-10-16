import 'package:projeto_padrao/enums/permissao_usuario.dart';

import '../models/usuario.dart';

class PermissionChecker {
  // Verifica se o usuário tem uma permissão específica
  static bool temPermissao(Usuario? usuario, PermissaoUsuario permissao) {
    if (usuario == null) return false;
    return usuario.perfil.permissoes.contains(permissao);
  }

  // Verifica se o usuário tem todas as permissões de uma lista
  static bool temTodasPermissoes(
    Usuario? usuario,
    List<PermissaoUsuario> permissoesRequeridas,
  ) {
    if (usuario == null) return false;
    return permissoesRequeridas.every(
      (permissao) => usuario.perfil.permissoes.contains(permissao),
    );
  }

  // Verifica se o usuário tem pelo menos uma das permissões da lista
  static bool temAlgumaPermissao(
    Usuario? usuario,
    List<PermissaoUsuario> permissoesRequeridas,
  ) {
    if (usuario == null) return false;
    return permissoesRequeridas.any(
      (permissao) => usuario.perfil.permissoes.contains(permissao),
    );
  }

  // Verifica se o usuário é administrador
  static bool isAdmin(Usuario? usuario) {
    if (usuario == null) return false;
    return temTodasPermissoes(usuario, [
      PermissaoUsuario.administrarUsuarios,
      PermissaoUsuario.configurarSistema,
    ]);
  }

  // Verifica se o usuário pode gerenciar pedidos
  static bool podeGerenciarPedidos(Usuario? usuario) {
    if (usuario == null) return false;
    return temAlgumaPermissao(usuario, [
      PermissaoUsuario.cadastrarPedidos,
      PermissaoUsuario.editarPedidos,
      PermissaoUsuario.excluirPedidos,
    ]);
  }

  // Verifica se o usuário pode visualizar relatórios
  static bool podeVisualizarRelatorios(Usuario? usuario) {
    if (usuario == null) return false;
    return temPermissao(usuario, PermissaoUsuario.visualizarRelatorios);
  }

  // Filtra uma lista baseado nas permissões do usuário
  static List<T> filtrarPorPermissao<T>({
    required Usuario? usuario,
    required List<T> items,
    required PermissaoUsuario permissao,
    required bool Function(T item, Usuario usuario) condicional,
  }) {
    if (usuario == null) return [];

    if (!temPermissao(usuario, permissao)) {
      return [];
    }

    return items.where((item) => condicional(item, usuario)).toList();
  }

  // Obtém permissões faltantes
  static List<PermissaoUsuario> permissoesFaltantes(
    Usuario? usuario,
    List<PermissaoUsuario> permissoesRequeridas,
  ) {
    if (usuario == null) return permissoesRequeridas;

    return permissoesRequeridas
        .where((permissao) => !usuario.perfil.permissoes.contains(permissao))
        .toList();
  }
}
