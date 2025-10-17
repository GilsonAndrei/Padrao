import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/routes/app_routes.dart';
import '../models/usuario.dart';

class PermissionChecker {
  // ✅ VERIFICA SE É ADMINISTRADOR (usando o campo isAdmin)
  static bool isAdmin(Usuario? usuario) {
    if (usuario == null) return false;
    return usuario.isAdmin; // Agora usa o campo direto
  }

  // ✅ VERIFICA SE TEM UMA PERMISSÃO ESPECÍFICA
  static bool temPermissao(Usuario? usuario, PermissaoUsuario permissao) {
    if (usuario == null) return false;

    // Se é admin, tem todas as permissões
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica no perfil
    return usuario.perfil.permissoes.contains(permissao);
  }

  // ✅ VERIFICA SE TEM TODAS AS PERMISSÕES DE UMA LISTA
  static bool temTodasPermissoes(
    Usuario? usuario,
    List<PermissaoUsuario> permissoesRequeridas,
  ) {
    if (usuario == null) return false;

    // Se é admin, tem todas as permissões
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica se tem todas
    return permissoesRequeridas.every(
      (permissao) => usuario.perfil.permissoes.contains(permissao),
    );
  }

  // ✅ VERIFICA SE TEM PELO MENOS UMA DAS PERMISSÕES DA LISTA
  static bool temAlgumaPermissao(
    Usuario? usuario,
    List<PermissaoUsuario> permissoesRequeridas,
  ) {
    if (usuario == null) return false;

    // Se é admin, tem todas as permissões
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica se tem pelo menos uma
    return permissoesRequeridas.any(
      (permissao) => usuario.perfil.permissoes.contains(permissao),
    );
  }

  // ✅ VERIFICA SE PODE GERENCIAR PEDIDOS
  static bool podeGerenciarPedidos(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode gerenciar tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissões específicas
    return temAlgumaPermissao(usuario, [
      PermissaoUsuario.cadastrarPedidos,
      PermissaoUsuario.editarPedidos,
      PermissaoUsuario.excluirPedidos,
      PermissaoUsuario.visualizarCadastro,
    ]);
  }

  // ✅ VERIFICA SE PODE VISUALIZAR RELATÓRIOS
  static bool podeVisualizarRelatorios(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode ver tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissões específicas
    return temAlgumaPermissao(usuario, [
      PermissaoUsuario.visualizarRelatorios,
      PermissaoUsuario.relatorioVisualizar,
    ]);
  }

  // ✅ VERIFICA SE PODE GERENCIAR USUÁRIOS
  static bool podeGerenciarUsuarios(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode gerenciar tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissões específicas
    return temAlgumaPermissao(usuario, [
      PermissaoUsuario.administrarUsuarios,
      PermissaoUsuario.usuarioVisualizar,
      PermissaoUsuario.usuarioEditar,
    ]);
  }

  // ✅ VERIFICA SE PODE CONFIGURAR O SISTEMA
  static bool podeConfigurarSistema(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode configurar tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissões específicas
    return temAlgumaPermissao(usuario, [
      PermissaoUsuario.configurarSistema,
      PermissaoUsuario.configuracaoVisualizar,
    ]);
  }

  // ✅ VERIFICA SE PODE VISUALIZAR CADASTROS
  static bool podeVisualizarCadastros(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode ver tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissão específica
    return temPermissao(usuario, PermissaoUsuario.visualizarCadastro);
  }

  // ✅ VERIFICA SE PODE CRIAR/EDITAR PEDIDOS
  static bool podeCriarEditarPedidos(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode fazer tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissões específicas
    return temAlgumaPermissao(usuario, [
      PermissaoUsuario.cadastrarPedidos,
      PermissaoUsuario.editarPedidos,
    ]);
  }

  // ✅ VERIFICA SE PODE EXCLUIR PEDIDOS
  static bool podeExcluirPedidos(Usuario? usuario) {
    if (usuario == null) return false;

    // Se é admin, pode excluir tudo
    if (usuario.isAdmin) return true;

    // Caso contrário, verifica permissão específica
    return temPermissao(usuario, PermissaoUsuario.excluirPedidos);
  }

  // ✅ FILTRA UMA LISTA BASEADO NAS PERMISSÕES DO USUÁRIO
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

  // ✅ OBTÉM PERMISSÕES FALTANTES
  static List<PermissaoUsuario> permissoesFaltantes(
    Usuario? usuario,
    List<PermissaoUsuario> permissoesRequeridas,
  ) {
    if (usuario == null) return permissoesRequeridas;

    // Se é admin, não falta nenhuma permissão
    if (usuario.isAdmin) return [];

    // Caso contrário, verifica quais faltam
    return permissoesRequeridas
        .where((permissao) => !usuario.perfil.permissoes.contains(permissao))
        .toList();
  }

  // ✅ VERIFICA SE TEM ACESSO A UMA FUNCIONALIDADE ESPECÍFICA
  static bool temAcessoFuncionalidade(Usuario? usuario, String funcionalidade) {
    if (usuario == null) return false;

    // Se é admin, tem acesso a tudo
    if (usuario.isAdmin) return true;

    // Mapeamento de funcionalidades para permissões
    final mapFuncionalidades = {
      'usuarios': [
        PermissaoUsuario.administrarUsuarios,
        PermissaoUsuario.usuarioVisualizar,
        PermissaoUsuario.usuarioEditar,
      ],
      'perfis': [PermissaoUsuario.administrarUsuarios],
      'pedidos': [
        PermissaoUsuario.cadastrarPedidos,
        PermissaoUsuario.editarPedidos,
        PermissaoUsuario.excluirPedidos,
        PermissaoUsuario.visualizarCadastro,
      ],
      'relatorios': [
        PermissaoUsuario.visualizarRelatorios,
        PermissaoUsuario.relatorioVisualizar,
      ],
      'configuracoes': [
        PermissaoUsuario.configurarSistema,
        PermissaoUsuario.configuracaoVisualizar,
      ],
      'cadastros': [PermissaoUsuario.visualizarCadastro],
    };

    final permissoesRequeridas = mapFuncionalidades[funcionalidade] ?? [];
    return temAlgumaPermissao(usuario, permissoesRequeridas);
  }

  // ✅ OBTÉM LISTA DE PERMISSÕES DO USUÁRIO (incluindo admin)
  static List<PermissaoUsuario> obterPermissoes(Usuario? usuario) {
    if (usuario == null) return [];

    // Se é admin, retorna todas as permissões
    if (usuario.isAdmin) return PermissaoUsuario.values;

    // Caso contrário, retorna as permissões do perfil
    return usuario.perfil.permissoes;
  }

  // ✅ VERIFICA SE PODE REALIZAR AÇÃO EM UM RECURSO ESPECÍFICO
  static bool podeRealizarAcao(
    Usuario? usuario, {
    required String recurso,
    required String acao, // 'visualizar', 'criar', 'editar', 'excluir'
  }) {
    if (usuario == null) return false;

    // Se é admin, pode fazer qualquer ação
    if (usuario.isAdmin) return true;

    // Mapeamento de ações para permissões
    final mapAcoes = {
      'usuarios': {
        'visualizar': [
          PermissaoUsuario.usuarioVisualizar,
          PermissaoUsuario.administrarUsuarios,
        ],
        'criar': [PermissaoUsuario.administrarUsuarios],
        'editar': [
          PermissaoUsuario.usuarioEditar,
          PermissaoUsuario.administrarUsuarios,
        ],
        'excluir': [PermissaoUsuario.administrarUsuarios],
      },
      'perfis': {
        'visualizar': [PermissaoUsuario.administrarUsuarios],
        'criar': [PermissaoUsuario.administrarUsuarios],
        'editar': [PermissaoUsuario.administrarUsuarios],
        'excluir': [PermissaoUsuario.administrarUsuarios],
      },
      'pedidos': {
        'visualizar': [PermissaoUsuario.visualizarCadastro],
        'criar': [PermissaoUsuario.cadastrarPedidos],
        'editar': [PermissaoUsuario.editarPedidos],
        'excluir': [PermissaoUsuario.excluirPedidos],
      },
      'relatorios': {
        'visualizar': [
          PermissaoUsuario.visualizarRelatorios,
          PermissaoUsuario.relatorioVisualizar,
        ],
      },
    };

    final acoesRecurso = mapAcoes[recurso];
    final permissoesRequeridas = acoesRecurso?[acao] ?? [];

    return temAlgumaPermissao(usuario, permissoesRequeridas);
  }

  // ✅ VALIDA SE USUÁRIO PODE ACESSAR UMA ROTA/ TELA
  static bool podeAcessarRota(Usuario? usuario, String rota) {
    if (usuario == null) return false;

    // Se é admin, pode acessar todas as rotas
    if (usuario.isAdmin) return true;

    // Mapeamento de rotas para permissões
    final mapRotas = {
      AppRoutes.users: [
        PermissaoUsuario.administrarUsuarios,
        PermissaoUsuario.usuarioVisualizar,
      ],
      AppRoutes.userForm: [PermissaoUsuario.administrarUsuarios],
      AppRoutes.profiles: [PermissaoUsuario.administrarUsuarios],
      AppRoutes.profileForm: [PermissaoUsuario.administrarUsuarios],
      AppRoutes.orders: [PermissaoUsuario.visualizarCadastro],
      AppRoutes.reports: [
        PermissaoUsuario.visualizarRelatorios,
        PermissaoUsuario.relatorioVisualizar,
      ],
      AppRoutes.settings: [
        PermissaoUsuario.configurarSistema,
        PermissaoUsuario.configuracaoVisualizar,
      ],
    };

    final permissoesRequeridas = mapRotas[rota] ?? [];
    return temAlgumaPermissao(usuario, permissoesRequeridas);
  }
}
