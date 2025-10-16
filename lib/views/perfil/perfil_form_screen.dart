import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';

class PerfilFormScreen extends StatefulWidget {
  final PerfilUsuario? perfil;

  const PerfilFormScreen({super.key, this.perfil});

  @override
  State<PerfilFormScreen> createState() => _PerfilFormScreenState();
}

class _PerfilFormScreenState extends State<PerfilFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;

  final List<PermissaoUsuario> _permissoesSelecionadas = [];
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.perfil?.nome ?? '');
    _descricaoController = TextEditingController(
      text: widget.perfil?.descricao ?? '',
    );
    _permissoesSelecionadas.addAll(widget.perfil?.permissoes ?? []);
    _ativo = widget.perfil?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PerfilController controller = Provider.of<PerfilController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.perfil == null ? 'Novo Perfil' : 'Editar Perfil'),
        actions: [
          if (widget.perfil != null) _buildDeleteButton(context, controller),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Nome
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do perfil',
                          prefixIcon: Icon(Icons.manage_accounts),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome do perfil';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descrição
                      TextFormField(
                        controller: _descricaoController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma descrição';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Status
                      _buildStatusSwitch(),
                      const SizedBox(height: 24),

                      // Permissões
                      _buildPermissoesSection(),
                    ],
                  ),
                ),
              ),

              // Botões de ação
              _buildActionButtons(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _ativo ? Icons.check_circle : Icons.block,
              color: _ativo ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfil ativo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _ativo
                        ? 'O perfil está disponível para uso'
                        : 'O perfil não está disponível para uso',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _ativo,
              onChanged: (value) {
                setState(() {
                  _ativo = value;
                });
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissoesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Permissões',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione as permissões que este perfil terá acesso:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPermissoesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissoesList() {
    return Column(
      children: PermissaoUsuario.values.map((permissao) {
        final isSelected = _permissoesSelecionadas.contains(permissao);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _permissoesSelecionadas.remove(permissao);
                } else {
                  _permissoesSelecionadas.add(permissao);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          permissao.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          permissao.codigo,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PerfilController controller,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _savePerfil(context, controller),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Salvar Perfil'),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.perfil == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context, PerfilController controller) {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () => _deletePerfil(context, controller),
    );
  }

  void _savePerfil(BuildContext context, PerfilController controller) async {
    if (_formKey.currentState!.validate()) {
      final perfil = PerfilUsuario(
        id:
            widget.perfil?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        permissoes: _permissoesSelecionadas,
        dataCriacao: widget.perfil?.dataCriacao ?? DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: _ativo,
      );

      final success = await controller.saveItem(perfil);
      if (success) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perfil ${widget.perfil == null ? 'criado' : 'atualizado'} com sucesso',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deletePerfil(BuildContext context, PerfilController controller) {
    if (widget.perfil != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o perfil ${widget.perfil!.nome}?',
            textAlign: TextAlign.center,
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(context).pop(); // Fecha o dialog

                final success = await controller.deleteItem(widget.perfil!);
                if (success) {
                  Navigator.of(context).pop(); // Volta para a lista

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Perfil ${widget.perfil!.nome} excluído com sucesso',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao excluir perfil'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
    }
  }
}
