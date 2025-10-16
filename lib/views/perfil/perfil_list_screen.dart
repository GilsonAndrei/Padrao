// views/perfis/perfil_list_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/views/perfil/perfil_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';

class PerfilListScreen extends StatefulWidget {
  const PerfilListScreen({super.key});

  @override
  State<PerfilListScreen> createState() => _PerfilListScreenState();
}

class _PerfilListScreenState extends State<PerfilListScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega os perfis quando a tela inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PerfilController>(context, listen: false);
      controller.loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfis de Usuário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final controller = Provider.of<PerfilController>(
                context,
                listen: false,
              );
              controller.loadItems();
            },
          ),
        ],
      ),
      body: Consumer<PerfilController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return _buildEmptyState();
          }

          return _buildPerfilList(controller);
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
          Icon(
            Icons.manage_accounts_outlined,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum perfil cadastrado',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no + para adicionar o primeiro perfil',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilList(PerfilController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.items.length} perfil(s) encontrado(s)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: controller.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final perfil = controller.items[index];
                return _buildPerfilCard(context, perfil, controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilCard(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(context, perfil),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone do perfil
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Icon(
                  Icons.manage_accounts,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perfil.descricao,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: perfil.ativo
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            perfil.ativo ? 'Ativo' : 'Inativo',
                            style: TextStyle(
                              color: perfil.ativo
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Quantidade de permissões
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${perfil.permissoes.length} permissões',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Data criação
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
                            'Criado em ${_formatDate(perfil.dataCriacao)}',
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
              // Menu de ações
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, perfil, controller),
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
                          perfil.ativo ? Icons.block : Icons.check_circle,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(perfil.ativo ? 'Inativar' : 'Ativar'),
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

  // ✅ CORRIGIDO: Navegação COM contexto
  void _navigateToForm(BuildContext context, PerfilUsuario? perfil) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PerfilFormScreen(perfil: perfil)),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    switch (action) {
      case 'edit':
        _navigateToForm(context, perfil);
        break;
      case 'toggle_status':
        _togglePerfilStatus(context, perfil, controller);
        break;
      case 'delete':
        _deletePerfil(context, perfil, controller);
        break;
    }
  }

  void _togglePerfilStatus(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    final novoPerfil = perfil.copyWith(ativo: !perfil.ativo);
    controller.saveItem(novoPerfil);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil ${novoPerfil.ativo ? 'ativado' : 'inativado'} com sucesso',
        ),
        backgroundColor: novoPerfil.ativo
            ? AppColors.success
            : AppColors.warning,
      ),
    );
  }

  void _deletePerfil(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o perfil ${perfil.nome}?',
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
              controller.deleteItem(perfil);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Perfil ${perfil.nome} excluído com sucesso'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
