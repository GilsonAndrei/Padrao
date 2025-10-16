enum PermissaoUsuario {
  visualizarCadastro,
  cadastrarPedidos,
  editarPedidos,
  excluirPedidos,
  visualizarRelatorios,
  administrarUsuarios,
  configurarSistema,
  // Adicione outras permissões conforme necessário
}

extension PermissaoUsuarioExtension on PermissaoUsuario {
  String get nome {
    switch (this) {
      case PermissaoUsuario.visualizarCadastro:
        return 'Visualizar Cadastro';
      case PermissaoUsuario.cadastrarPedidos:
        return 'Cadastrar Pedidos';
      case PermissaoUsuario.editarPedidos:
        return 'Editar Pedidos';
      case PermissaoUsuario.excluirPedidos:
        return 'Excluir Pedidos';
      case PermissaoUsuario.visualizarRelatorios:
        return 'Visualizar Relatórios';
      case PermissaoUsuario.administrarUsuarios:
        return 'Administrar Usuários';
      case PermissaoUsuario.configurarSistema:
        return 'Configurar Sistema';
    }
  }

  String get codigo {
    switch (this) {
      case PermissaoUsuario.visualizarCadastro:
        return 'VISUALIZAR_CADASTRO';
      case PermissaoUsuario.cadastrarPedidos:
        return 'CADASTRAR_PEDIDOS';
      case PermissaoUsuario.editarPedidos:
        return 'EDITAR_PEDIDOS';
      case PermissaoUsuario.excluirPedidos:
        return 'EXCLUIR_PEDIDOS';
      case PermissaoUsuario.visualizarRelatorios:
        return 'VISUALIZAR_RELATORIOS';
      case PermissaoUsuario.administrarUsuarios:
        return 'ADMINISTRAR_USUARIOS';
      case PermissaoUsuario.configurarSistema:
        return 'CONFIGURAR_SISTEMA';
    }
  }
}
