import 'package:flutter/material.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import '../models/usuario.dart';
import '../utils/permission_checker.dart';

// Widget base para controle de acesso por permissão
class PermissionWidget extends StatelessWidget {
  final Usuario? usuario;
  final Widget child;
  final Widget? fallback;
  final bool Function(Usuario?) condition;

  const PermissionWidget({
    Key? key,
    required this.usuario,
    required this.child,
    required this.condition,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (condition(usuario)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

// Widget específico para uma única permissão
class SinglePermissionWidget extends StatelessWidget {
  final Usuario? usuario;
  final PermissaoUsuario permissao;
  final Widget child;
  final Widget? fallback;

  const SinglePermissionWidget({
    Key? key,
    required this.usuario,
    required this.permissao,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.temPermissao(user, permissao),
      child: child,
      fallback: fallback,
    );
  }
}

// Widget para múltiplas permissões (TODAS requeridas)
class AllPermissionsWidget extends StatelessWidget {
  final Usuario? usuario;
  final List<PermissaoUsuario> permissoes;
  final Widget child;
  final Widget? fallback;

  const AllPermissionsWidget({
    Key? key,
    required this.usuario,
    required this.permissoes,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) =>
          PermissionChecker.temTodasPermissoes(user, permissoes),
      child: child,
      fallback: fallback,
    );
  }
}

// Widget para múltiplas permissões (PELO MENOS UMA requerida)
class AnyPermissionWidget extends StatelessWidget {
  final Usuario? usuario;
  final List<PermissaoUsuario> permissoes;
  final Widget child;
  final Widget? fallback;

  const AnyPermissionWidget({
    Key? key,
    required this.usuario,
    required this.permissoes,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) =>
          PermissionChecker.temAlgumaPermissao(user, permissoes),
      child: child,
      fallback: fallback,
    );
  }
}

// Widget específico para administradores
class AdminOnlyWidget extends StatelessWidget {
  final Usuario? usuario;
  final Widget child;
  final Widget? fallback;

  const AdminOnlyWidget({
    Key? key,
    required this.usuario,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.isAdmin(user),
      child: child,
      fallback: fallback,
    );
  }
}

// Widget para gerenciamento de pedidos
class PedidoManagementWidget extends StatelessWidget {
  final Usuario? usuario;
  final Widget child;
  final Widget? fallback;

  const PedidoManagementWidget({
    Key? key,
    required this.usuario,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.podeGerenciarPedidos(user),
      child: child,
      fallback: fallback,
    );
  }
}




/*EXEMPLOS DE USO:
// Exemplo 1: Botão que só aparece para quem pode cadastrar pedidos
SinglePermissionWidget(
  usuario: usuarioLogado,
  permissao: PermissaoUsuario.cadastrarPedidos,
  child: ElevatedButton(
    onPressed: () => _cadastrarPedido(),
    child: Text('Novo Pedido'),
  ),
  fallback: SizedBox.shrink(), // ou um Widget de "acesso negado"
),

// Exemplo 2: Seção completa que requer múltiplas permissões
AllPermissionsWidget(
  usuario: usuarioLogado,
  permissoes: [
    PermissaoUsuario.visualizarCadastro,
    PermissaoUsuario.cadastrarPedidos,
  ],
  child: Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Área de Vendas'),
          // ... outros widgets
        ],
      ),
    ),
  ),
),

// Exemplo 3: Menu que aparece para administradores
AdminOnlyWidget(
  usuario: usuarioLogado,
  child: PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        child: Text('Gerenciar Usuários'),
        onTap: () => _gerenciarUsuarios(),
      ),
    ],
  ),
),

// Exemplo 4: Com fallback personalizado
AnyPermissionWidget(
  usuario: usuarioLogado,
  permissoes: [
    PermissaoUsuario.visualizarRelatorios,
    PermissaoUsuario.administrarUsuarios,
  ],
  child: RelatoriosScreen(),
  fallback: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.block, size: 64, color: Colors.grey),
        Text('Acesso não autorizado'),
      ],
    ),
  ),
),
 */