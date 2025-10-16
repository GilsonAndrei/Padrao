// views/perfis/perfil_list_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/controllers/perfil_usuario_controller.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/views/generic/generic_search_screen.dart';
import 'package:projeto_padrao/views/perfis/perfil_form_screen.dart';

class PerfilListScreen extends StatelessWidget {
  final PerfilUsuarioController _controller = PerfilUsuarioController();

  PerfilListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericSearchScreen<PerfilUsuario>(
      title: 'Perfis de Usuário',
      controller: _controller,
      itemBuilder: (context, perfil) => _buildPerfilItem(context, perfil),
      filterBuilder: _buildFilters,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PerfilFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPerfilItem(BuildContext context, PerfilUsuario perfil) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.assignment_ind, color: AppColors.primary),
        ),
        title: Text(
          perfil.nome,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              perfil.descricao,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: perfil.ativo ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    perfil.ativo ? 'Ativo' : 'Inativo',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${perfil.permissoes.length} permissões',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, perfil),
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
              value: perfil.ativo ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(
                    perfil.ativo ? Icons.block : Icons.check_circle,
                    size: 18,
                    color: perfil.ativo ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(perfil.ativo ? 'Desativar' : 'Ativar'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PerfilFormScreen(perfil: perfil),
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    PerfilUsuario perfil,
  ) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilFormScreen(perfil: perfil),
          ),
        );
        break;
      case 'disable':
      case 'enable':
        _controller.toggleAtivo(perfil);
        break;
    }
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
