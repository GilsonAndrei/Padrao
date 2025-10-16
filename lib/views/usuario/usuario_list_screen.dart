// views/usuarios/usuario_list_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:projeto_padrao/views/usuario/usuario_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  void _loadUsuarios() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<UsuarioController>(context, listen: false);
      controller.loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsuarios),
        ],
      ),
      body: Consumer<UsuarioController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return _buildEmptyState();
          }

          return _buildUserList(context, controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context, null),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'Nenhum usuário cadastrado',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no + para adicionar o primeiro usuário',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context, UsuarioController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.items.length} usuário(s) encontrado(s)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: controller.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final usuario = controller.items[index];
                return _buildUserCard(context, usuario, controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(context, usuario),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: usuario.ativo
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            usuario.ativo ? 'Ativo' : 'Inativo',
                            style: TextStyle(
                              color: usuario.ativo
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            usuario.perfil.nome,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status email
              Icon(
                usuario.emailVerificado ? Icons.verified : Icons.unpublished,
                color: usuario.emailVerificado
                    ? AppColors.success
                    : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 12),
              // Menu de ações
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, usuario, controller),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          usuario.ativo ? Icons.block : Icons.check_circle,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(usuario.ativo ? 'Inativar' : 'Ativar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, Usuario? usuario) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UsuarioFormScreen(usuario: usuario),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Usuario usuario,
    UsuarioController controller,
  ) {
    switch (action) {
      case 'edit':
        _navigateToForm(context, usuario);
        break;
      case 'toggle_status':
        _toggleUserStatus(context, usuario, controller);
        break;
      case 'delete':
        _deleteUser(context, usuario, controller);
        break;
    }
  }

  void _toggleUserStatus(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    final novoUsuario = usuario.copyWith(ativo: !usuario.ativo);
    controller.saveItem(novoUsuario);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Usuário ${novoUsuario.ativo ? 'ativado' : 'inativado'} com sucesso',
        ),
        backgroundColor: novoUsuario.ativo
            ? AppColors.success
            : AppColors.warning,
      ),
    );
  }

  void _deleteUser(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o usuário ${usuario.nome}?',
          textAlign: TextAlign.center,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteItem(usuario);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Usuário ${usuario.nome} excluído com sucesso'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
