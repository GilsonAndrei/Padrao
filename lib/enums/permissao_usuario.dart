import 'package:flutter/material.dart';

enum PermissaoUsuario {
  visualizarCadastro(
    nome: 'Visualizar Cadastro',
    codigo: 'VISUALIZAR_CADASTRO',
    categoria: '📦 Produtos',
    icone: Icons.inventory_2_outlined,
  ),
  cadastrarPedidos(
    nome: 'Cadastrar Pedidos',
    codigo: 'CADASTRAR_PEDIDOS',
    categoria: '📦 Produtos',
    icone: Icons.inventory_2_outlined,
  ),
  editarPedidos(
    nome: 'Editar Pedidos',
    codigo: 'EDITAR_PEDIDOS',
    categoria: '📦 Produtos',
    icone: Icons.inventory_2_outlined,
  ),
  excluirPedidos(
    nome: 'Excluir Pedidos',
    codigo: 'EXCLUIR_PEDIDOS',
    categoria: '📦 Produtos',
    icone: Icons.inventory_2_outlined,
  ),
  visualizarRelatorios(
    nome: 'Visualizar Relatórios',
    codigo: 'VISUALIZAR_RELATORIOS',
    categoria: '📊 Relatórios',
    icone: Icons.analytics_outlined,
  ),
  administrarUsuarios(
    nome: 'Administrar Usuários',
    codigo: 'ADMINISTRAR_USUARIOS',
    categoria: '👥 Usuários',
    icone: Icons.people_outlined,
  ),
  configurarSistema(
    nome: 'Configurar Sistema',
    codigo: 'CONFIGURAR_SISTEMA',
    categoria: '⚙️ Sistema',
    icone: Icons.settings_outlined,
  ),
  usuarioVisualizar(
    nome: 'Visualizar Usuários',
    codigo: 'USUARIO_VISUALIZAR',
    categoria: '👥 Usuários',
    icone: Icons.people_outlined,
  ),
  usuarioEditar(
    nome: 'Editar Usuários',
    codigo: 'USUARIO_EDITAR',
    categoria: '👥 Usuários',
    icone: Icons.people_outlined,
  ),
  relatorioVisualizar(
    nome: 'Visualizar Relatórios',
    codigo: 'RELATORIO_VISUALIZAR',
    categoria: '📊 Relatórios',
    icone: Icons.analytics_outlined,
  ),
  configuracaoVisualizar(
    nome: 'Visualizar Configurações',
    codigo: 'CONFIGURACAO_VISUALIZAR',
    categoria: '⚙️ Sistema',
    icone: Icons.settings_outlined,
  );

  final String nome;
  final String codigo;
  final String categoria;
  final IconData icone;

  const PermissaoUsuario({
    required this.nome,
    required this.codigo,
    required this.categoria,
    required this.icone,
  });
}

extension PermissaoUsuarioExtension on PermissaoUsuario {
  // Método para agrupar por categoria
  static Map<String, List<PermissaoUsuario>> get agrupadoPorCategoria {
    final Map<String, List<PermissaoUsuario>> categorias = {};

    for (final permissao in PermissaoUsuario.values) {
      if (!categorias.containsKey(permissao.categoria)) {
        categorias[permissao.categoria] = [];
      }
      categorias[permissao.categoria]!.add(permissao);
    }

    return categorias;
  }

  // Método para obter todas as categorias únicas
  static List<String> get categorias {
    return PermissaoUsuario.values.map((e) => e.categoria).toSet().toList();
  }

  // Método para obter permissões por categoria
  static List<PermissaoUsuario> obterPorCategoria(String categoria) {
    return PermissaoUsuario.values
        .where((permissao) => permissao.categoria == categoria)
        .toList();
  }

  // Método para obter ícone da categoria
  static IconData obterIconeCategoria(String categoria) {
    final permissao = PermissaoUsuario.values.firstWhere(
      (p) => p.categoria == categoria,
      orElse: () => PermissaoUsuario.visualizarCadastro,
    );
    return permissao.icone;
  }
}
