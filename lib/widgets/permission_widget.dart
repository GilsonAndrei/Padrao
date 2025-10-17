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

// ✅ WIDGET ESPECÍFICO PARA ADMINISTRADORES (usando campo isAdmin)
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

// ✅ NOVO: Widget para gerenciamento de usuários
class UserManagementWidget extends StatelessWidget {
  final Usuario? usuario;
  final Widget child;
  final Widget? fallback;

  const UserManagementWidget({
    Key? key,
    required this.usuario,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.podeGerenciarUsuarios(user),
      child: child,
      fallback: fallback,
    );
  }
}

// ✅ NOVO: Widget para visualização de relatórios
class ReportsWidget extends StatelessWidget {
  final Usuario? usuario;
  final Widget child;
  final Widget? fallback;

  const ReportsWidget({
    Key? key,
    required this.usuario,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.podeVisualizarRelatorios(user),
      child: child,
      fallback: fallback,
    );
  }
}

// ✅ NOVO: Widget para configurações do sistema
class SystemConfigWidget extends StatelessWidget {
  final Usuario? usuario;
  final Widget child;
  final Widget? fallback;

  const SystemConfigWidget({
    Key? key,
    required this.usuario,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.podeConfigurarSistema(user),
      child: child,
      fallback: fallback,
    );
  }
}

// ✅ NOVO: Widget para acesso a rotas específicas
class RouteAccessWidget extends StatelessWidget {
  final Usuario? usuario;
  final String rota;
  final Widget child;
  final Widget? fallback;

  const RouteAccessWidget({
    Key? key,
    required this.usuario,
    required this.rota,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      usuario: usuario,
      condition: (user) => PermissionChecker.podeAcessarRota(user, rota),
      child: child,
      fallback: fallback,
    );
  }
}
