// views/usuarios/usuario_list_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/controllers/usuario_controller.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/views/generic/generic_search_screen.dart';
import 'package:projeto_padrao/views/usuarios/usuario_form_screen.dart';

class UsuarioListScreen extends StatelessWidget {
  final UsuarioController _controller = UsuarioController();

  UsuarioListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericSearchScreen<Usuario>(
      title: 'Usuários',
      controller: _controller,
      itemBuilder: (context, usuario) => _buildUsuarioItem(context, usuario),
      filterBuilder: _buildFilters,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UsuarioFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUsuarioItem(BuildContext context, Usuario usuario) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          backgroundImage: usuario.fotoUrl != null
              ? NetworkImage(usuario.fotoUrl!)
              : null,
          child: usuario.fotoUrl == null
              ? Text(
                  usuario.nome.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          usuario.nome,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              usuario.email,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: usuario.ativo ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    usuario.ativo ? 'Ativo' : 'Inativo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
                    color: usuario.perfil.ativo
                        ? AppColors.info
                        : AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    usuario.perfil.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, usuario),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: usuario.ativo ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(
                    usuario.ativo ? Icons.block : Icons.check_circle,
                    size: 18,
                    color: usuario.ativo
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(usuario.ativo ? 'Desativar' : 'Ativar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UsuarioFormScreen(usuario: usuario),
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Usuario usuario) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UsuarioFormScreen(usuario: usuario),
          ),
        );
        break;
      case 'disable':
      case 'enable':
        _controller.toggleAtivo(usuario);
        break;
      case 'delete':
        _showDeleteDialog(context, usuario);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o usuário ${usuario.nome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _controller.deleteUsuario(usuario.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    Function(Map<String, dynamic>) onFiltersApplied,
  ) {
    String? statusFilter;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              const DropdownMenuItem(value: 'ativo', child: Text('Ativos')),
              const DropdownMenuItem(value: 'inativo', child: Text('Inativos')),
            ],
            onChanged: (value) {
              statusFilter = value;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final filters = <String, dynamic>{};
                if (statusFilter != null) {
                  filters['ativo'] = statusFilter == 'ativo';
                }
                onFiltersApplied(filters);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Aplicar Filtros',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
