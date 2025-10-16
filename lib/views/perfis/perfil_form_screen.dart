// views/perfis/perfil_form_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/repositories/perfil_usuario_repository.dart';

class PerfilFormScreen extends StatefulWidget {
  final PerfilUsuario? perfil;

  const PerfilFormScreen({Key? key, this.perfil}) : super(key: key);

  @override
  State<PerfilFormScreen> createState() => _PerfilFormScreenState();
}

class _PerfilFormScreenState extends State<PerfilFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _perfilRepository = PerfilUsuarioRepository();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;

  Map<PermissaoUsuario, bool> _permissoesSelecionadas = {};
  bool _ativo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.perfil?.nome ?? '');
    _descricaoController = TextEditingController(
      text: widget.perfil?.descricao ?? '',
    );
    _ativo = widget.perfil?.ativo ?? true;

    // Inicializar permissões
    _inicializarPermissoes();
  }

  void _inicializarPermissoes() {
    // Para cada permissão disponível, marcar como selecionada se já existir no perfil
    for (var permissao in PermissaoUsuario.values) {
      _permissoesSelecionadas[permissao] =
          widget.perfil?.permissoes.contains(permissao) ?? false;
    }
  }

  List<PermissaoUsuario> get _permissoesAtivas {
    return _permissoesSelecionadas.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    if (_permissoesAtivas.isEmpty) {
      _showError('Selecione pelo menos uma permissão');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final perfil = PerfilUsuario(
        id: widget.perfil?.id ?? '',
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        permissoes: _permissoesAtivas,
        dataCriacao: widget.perfil?.dataCriacao ?? DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: _ativo,
      );

      if (widget.perfil == null) {
        // Novo perfil
        await _perfilRepository.collection.add(perfil.toMap());
        _showSuccess('Perfil criado com sucesso!');
      } else {
        // Editar perfil
        await _perfilRepository.collection
            .doc(perfil.id)
            .update(perfil.toMap());
        _showSuccess('Perfil atualizado com sucesso!');
      }

      Navigator.pop(context);
    } catch (e) {
      _showError('Erro ao salvar perfil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _getDescricaoPermissao(PermissaoUsuario permissao) {
    switch (permissao) {
      case PermissaoUsuario.visualizarCadastro:
        return 'Permite visualizar cadastros no sistema';
      case PermissaoUsuario.cadastrarPedidos:
        return 'Permite criar novos pedidos';
      case PermissaoUsuario.editarPedidos:
        return 'Permite editar pedidos existentes';
      case PermissaoUsuario.excluirPedidos:
        return 'Permite excluir pedidos do sistema';
      case PermissaoUsuario.visualizarRelatorios:
        return 'Permite acessar relatórios e análises';
      case PermissaoUsuario.administrarUsuarios:
        return 'Permite gerenciar usuários e perfis';
      case PermissaoUsuario.configurarSistema:
        return 'Permite alterar configurações do sistema';
    }
  }

  Widget _buildPermissaoItem(PermissaoUsuario permissao) {
    final isSelecionada = _permissoesSelecionadas[permissao] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: isSelecionada,
          onChanged: (value) {
            setState(() {
              _permissoesSelecionadas[permissao] = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        title: Text(
          permissao.nome,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelecionada ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _getDescricaoPermissao(permissao),
          style: TextStyle(
            color: isSelecionada ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelecionada
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.border,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            permissao.codigo,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelecionada
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        onTap: () {
          setState(() {
            _permissoesSelecionadas[permissao] = !isSelecionada;
          });
        },
      ),
    );
  }

  Widget _buildSelecaoPermissoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permissões',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione as permissões que este perfil terá acesso:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Contador de permissões selecionadas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_permissoesAtivas.length} permissões selecionadas',
                style: TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_permissoesAtivas.length == PermissaoUsuario.values.length)
                Text(
                  'Todas as permissões',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Botões de seleção rápida
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    for (var permissao in PermissaoUsuario.values) {
                      _permissoesSelecionadas[permissao] = true;
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Selecionar Todas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    for (var permissao in PermissaoUsuario.values) {
                      _permissoesSelecionadas[permissao] = false;
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Limpar Todas'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista de permissões
        SizedBox(
          height: 400,
          child: ListView(
            children: [...PermissaoUsuario.values.map(_buildPermissaoItem)],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPerfil() {
    final permissoesPreview = _permissoesAtivas.take(3).toList();
    final temMaisPermissoes = _permissoesAtivas.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome: ${_nomeController.text}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Descrição: ${_descricaoController.text}',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...permissoesPreview
                .map(
                  (permissao) => Chip(
                    label: Text(
                      permissao.nome,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppColors.primary),
                  ),
                )
                .toList(),
            if (temMaisPermissoes)
              Chip(
                label: Text(
                  '+${_permissoesAtivas.length - 3} mais',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                labelStyle: TextStyle(color: AppColors.secondary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _ativo ? Icons.check_circle : Icons.block,
              color: _ativo ? AppColors.success : AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _ativo ? 'Perfil ativo' : 'Perfil inativo',
              style: TextStyle(
                color: _ativo ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.perfil == null ? 'Novo Perfil' : 'Editar Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.perfil != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _salvarPerfil,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Campo Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Perfil',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment_ind),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome do perfil';
                        }
                        if (value.length < 3) {
                          return 'O nome deve ter pelo menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Descrição
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma descrição';
                        }
                        if (value.length < 10) {
                          return 'A descrição deve ter pelo menos 10 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Seção de Permissões
                    _buildSelecaoPermissoes(),
                    const SizedBox(height: 24),

                    // Switch Ativo
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Perfil ativo',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Switch(
                              value: _ativo,
                              onChanged: (value) {
                                setState(() {
                                  _ativo = value;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvarPerfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Salvar Perfil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Preview das permissões (apenas em edição)
                    if (widget.perfil != null) ...[
                      const SizedBox(height: 24),
                      Card(
                        color: AppColors.background,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pré-visualização do Perfil',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildPreviewPerfil(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}
