import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';

class PerfilFormScreen extends StatefulWidget {
  final PerfilUsuario? perfil;

  const PerfilFormScreen({super.key, this.perfil});

  @override
  State<PerfilFormScreen> createState() => _PerfilFormScreenState();
}

class _PerfilFormScreenState extends State<PerfilFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeFocusNode = FocusNode();
  final _descricaoFocusNode = FocusNode();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;

  final List<PermissaoUsuario> _permissoesSelecionadas = [];
  bool _ativo = true;
  bool _isSubmitting = false;

  // Controladores para os dropdowns expansivos
  final Map<String, bool> _categoriasAbertas = {};

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.perfil?.nome ?? '');
    _descricaoController = TextEditingController(
      text: widget.perfil?.descricao ?? '',
    );
    _permissoesSelecionadas.addAll(widget.perfil?.permissoes ?? []);
    _ativo = widget.perfil?.ativo ?? true;

    // Inicializa todas as categorias como fechadas
    _inicializarCategorias();
  }

  void _inicializarCategorias() {
    for (final categoria in PermissaoUsuarioExtension.categorias) {
      _categoriasAbertas[categoria] = false;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _nomeFocusNode.dispose();
    _descricaoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PerfilController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.perfil != null
          ? AppTheme.createGradientAppBarWithDelete(
              title: 'Editar Perfil',
              onDelete: () => _deletePerfil(context, controller),
              isDeleting: _isSubmitting,
            )
          : AppTheme.createGradientAppBar(title: 'Novo Perfil'),
      body: _isSubmitting
          ? _buildLoadingState()
          : _buildFormContent(context, controller),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Salvando perfil...',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, PerfilController controller) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Header com informações
          //_buildFormHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Ícone do perfil
                      _buildPerfilIconSection(),
                      const SizedBox(height: 32),

                      // Informações básicas
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),

                      // Configurações
                      _buildSettingsSection(),
                      const SizedBox(height: 32),

                      // Botões de ação
                      _buildActionButtons(context, controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.perfil == null ? 'Criar Novo Perfil' : 'Editar Perfil',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.perfil == null
                ? 'Configure as permissões e informações do novo perfil'
                : 'Atualize as informações e permissões do perfil',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilIconSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.manage_accounts,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Perfil de Acesso',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações Básicas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dados principais do perfil de acesso',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Nome
        _buildTextField(
          controller: _nomeController,
          focusNode: _nomeFocusNode,
          label: 'Nome do Perfil',
          hintText: 'Digite o nome do perfil',
          prefixIcon: Icons.manage_accounts_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira o nome do perfil';
            }
            if (value.length < 3) {
              return 'O nome deve ter pelo menos 3 caracteres';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_descricaoFocusNode);
          },
        ),
        const SizedBox(height: 16),

        // Descrição
        _buildTextField(
          controller: _descricaoController,
          focusNode: _descricaoFocusNode,
          label: 'Descrição',
          hintText: 'Descreva a função deste perfil...',
          prefixIcon: Icons.description_outlined,
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
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Defina o status e as permissões do perfil',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Status
        _buildStatusSwitch(),
        const SizedBox(height: 24),

        // Permissões
        _buildPermissoesSection(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return _buildSwitchCard(
      title: 'Status do Perfil',
      subtitle: _ativo
          ? 'Perfil ativo e disponível para atribuição'
          : 'Perfil inativo e não disponível para uso',
      value: _ativo,
      activeIcon: Icons.check_circle,
      inactiveIcon: Icons.block,
      activeColor: AppColors.success,
      inactiveColor: AppColors.error,
      onChanged: (value) => setState(() => _ativo = value),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required Color inactiveColor,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              value ? activeIcon : inactiveIcon,
              color: value ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
              inactiveTrackColor: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissoesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Permissões de Acesso',
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
              'Selecione as categorias e permissões desejadas:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Contador de permissões selecionadas
            if (_permissoesSelecionadas.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_permissoesSelecionadas.length} permissão(ões) selecionada(s)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Dropdowns por categoria
            _buildCategoriasPermissoes(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasPermissoes() {
    final categoriasPermissoes = PermissaoUsuarioExtension.agrupadoPorCategoria;

    return Column(
      children: categoriasPermissoes.entries.map((entry) {
        final categoria = entry.key;
        final permissoes = entry.value;
        final isOpen = _categoriasAbertas[categoria] ?? false;

        // Conta quantas permissões estão selecionadas nesta categoria
        final permissoesSelecionadas = permissoes
            .where((permissao) => _permissoesSelecionadas.contains(permissao))
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: permissoesSelecionadas > 0
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          child: ExpansionTile(
            key: Key(categoria),
            initiallyExpanded: isOpen,
            onExpansionChanged: (expanded) {
              setState(() {
                _categoriasAbertas[categoria] = expanded;
              });
            },
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: permissoesSelecionadas > 0
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PermissaoUsuarioExtension.obterIconeCategoria(categoria),
                size: 18,
                color: permissoesSelecionadas > 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    categoria,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (permissoesSelecionadas > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$permissoesSelecionadas/${permissoes.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              isOpen ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Opção "Selecionar Tudo" para a categoria
                    if (permissoesSelecionadas < permissoes.length)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'Selecionar todas as permissões',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            for (final permissao in permissoes) {
                              if (!_permissoesSelecionadas.contains(
                                permissao,
                              )) {
                                _permissoesSelecionadas.add(permissao);
                              }
                            }
                          });
                        },
                      ),

                    // Lista de permissões da categoria
                    ...permissoes.map((permissao) {
                      final isSelected = _permissoesSelecionadas.contains(
                        permissao,
                      );
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permissao.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              permissao.codigo,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _permissoesSelecionadas.add(permissao);
                            } else {
                              _permissoesSelecionadas.remove(permissao);
                            }
                          });
                        },
                        secondary: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isSelected
                              ? AppColors.success
                              : AppColors.textDisabled,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleSavePerfil(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              widget.perfil == null ? 'CRIAR PERFIL' : 'ATUALIZAR PERFIL',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.perfil == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.primary),
              ),
              child: Text(
                'CANCELAR',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleSavePerfil(
    BuildContext context,
    PerfilController controller,
  ) async {
    if (!_validarFormulario()) return;

    setState(() => _isSubmitting = true);

    try {
      final perfil = PerfilUsuario(
        id: widget.perfil?.id ?? '',
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        permissoes: _permissoesSelecionadas,
        dataCriacao: widget.perfil?.dataCriacao ?? DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: _ativo,
      );

      final success = await controller.savePerfil(perfil);

      if (success && mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage(context);
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validarFormulario() {
    if (!_formKey.currentState!.validate()) {
      _showValidationError('Por favor, corrija os erros no formulário');
      return false;
    }

    if (_permissoesSelecionadas.isEmpty) {
      _showValidationError('Selecione pelo menos uma permissão para o perfil');
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Perfil ${widget.perfil == null ? 'criado' : 'atualizado'} com sucesso!',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Erro: $error')),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _deletePerfil(
    BuildContext context,
    PerfilController controller,
  ) async {
    if (widget.perfil == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tem certeza que deseja excluir o perfil',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.perfil!.nome}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);

      try {
        await controller.deleteItem(widget.perfil!);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perfil "${widget.perfil!.nome}" excluído com sucesso',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          _showErrorMessage(context, error.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}
