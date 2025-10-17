import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;

  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _telefoneFocusNode = FocusNode();

  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  PerfilUsuario? _perfilSelecionado;
  bool _ativo = true;
  bool _emailVerificado = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _telefoneController = TextEditingController(
      text: widget.usuario?.telefone ?? '',
    );
    _perfilSelecionado = widget.usuario?.perfil;
    _ativo = widget.usuario?.ativo ?? true;
    _emailVerificado = widget.usuario?.emailVerificado ?? false;

    // Carrega os perfis se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfilController = Provider.of<PerfilController>(
        context,
        listen: false,
      );
      if (perfilController.perfisAtivos.isEmpty) {
        perfilController.loadItems();
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _nomeFocusNode.dispose();
    _emailFocusNode.dispose();
    _telefoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioController = Provider.of<UsuarioController>(context);
    final perfilController = Provider.of<PerfilController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTheme.createGradientAppBarWithDelete(
        title: widget.usuario == null ? 'Novo Usuário' : 'Editar Usuário',
        onDelete: () => _deleteUsuario(context, usuarioController),
        isDeleting: _isSubmitting,
        showDelete: widget.usuario != null,
      ),
      body: _isSubmitting
          ? _buildLoadingState()
          : _buildFormContent(context, usuarioController, perfilController),
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
            'Salvando usuário...',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    UsuarioController usuarioController,
    PerfilController perfilController,
  ) {
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
                      // Foto do usuário
                      _buildUserPhotoSection(),
                      const SizedBox(height: 32),

                      // Informações básicas
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),

                      // Configurações
                      _buildSettingsSection(perfilController),
                      const SizedBox(height: 32),

                      // Botões de ação
                      _buildActionButtons(context, usuarioController),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*Text(
            widget.usuario == null
                ? 'Cadastrar Novo Usuário'
                : 'Editar Usuário',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.usuario == null
                ? 'Preencha as informações abaixo para criar um novo usuário'
                : 'Atualize as informações do usuário',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _buildUserPhotoSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.person, size: 48, color: AppColors.primary),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  // TODO: Implementar upload de foto
                  _showPhotoOptions();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Foto do perfil',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
          'Dados principais do usuário',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Nome
        _buildTextField(
          controller: _nomeController,
          focusNode: _nomeFocusNode,
          label: 'Nome completo',
          hintText: 'Digite o nome completo',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira o nome';
            }
            if (value.length < 3) {
              return 'O nome deve ter pelo menos 3 caracteres';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_emailFocusNode);
          },
        ),
        const SizedBox(height: 16),

        // Email
        _buildTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: 'E-mail',
          hintText: 'Digite o e-mail',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira o e-mail';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Por favor, insira um e-mail válido';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_telefoneFocusNode);
          },
        ),
        const SizedBox(height: 16),

        // Telefone
        _buildTextField(
          controller: _telefoneController,
          focusNode: _telefoneFocusNode,
          label: 'Telefone',
          hintText: '(00) 00000-0000',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          optional: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(PerfilController perfilController) {
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
          'Defina as permissões e status do usuário',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Perfil
        _buildPerfilDropdown(perfilController),
        const SizedBox(height: 20),

        // Status
        _buildStatusSwitch(),
        const SizedBox(height: 16),

        // Email Verificado
        _buildEmailVerificadoSwitch(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool optional = false,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              Text(
                '(opcional)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerfilDropdown(PerfilController perfilController) {
    return Consumer<PerfilController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return _buildLoadingPerfis();
        }

        if (controller.perfisAtivos.isEmpty) {
          return _buildNoPerfisAvailable();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfil de Acesso',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PerfilUsuario>(
              value: _getInitialPerfilValue(controller),
              decoration: InputDecoration(
                hintText: 'Selecione um perfil',
                prefixIcon: Icon(
                  Icons.manage_accounts,
                  color: AppColors.primary,
                ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // ✅ CORREÇÃO ALTERNATIVA: Usando texto simples sem Column
              items: controller.perfisAtivos.map((perfil) {
                return DropdownMenuItem<PerfilUsuario>(
                  value: perfil,
                  child: Text(
                    perfil.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (PerfilUsuario? perfil) {
                setState(() {
                  _perfilSelecionado = perfil;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, selecione um perfil';
                }
                return null;
              },
              isExpanded: true,
            ),
            // ✅ Adicionando a descrição como um texto separado abaixo do dropdown
            if (_perfilSelecionado != null) ...[
              const SizedBox(height: 8),
              Text(
                _perfilSelecionado!.descricao,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingPerfis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Carregando perfis...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPerfisAvailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum perfil disponível',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crie um perfil ativo antes de cadastrar usuários',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PerfilUsuario? _getInitialPerfilValue(PerfilController controller) {
    if (_perfilSelecionado != null) {
      try {
        return controller.perfisAtivos.firstWhere(
          (p) => p.id == _perfilSelecionado!.id,
        );
      } catch (e) {}
    }

    if (widget.usuario != null) {
      try {
        return controller.perfisAtivos.firstWhere(
          (p) => p.id == widget.usuario!.perfil.id,
        );
      } catch (e) {}
    }

    return null;
  }

  Widget _buildStatusSwitch() {
    return _buildSwitchCard(
      title: 'Status do Usuário',
      subtitle: _ativo
          ? 'Usuário ativo e pode acessar o sistema'
          : 'Usuário inativo e não pode acessar o sistema',
      value: _ativo,
      activeIcon: Icons.check_circle,
      inactiveIcon: Icons.block,
      activeColor: AppColors.success,
      inactiveColor: AppColors.error,
      onChanged: (value) => setState(() => _ativo = value),
    );
  }

  Widget _buildEmailVerificadoSwitch() {
    return _buildSwitchCard(
      title: 'E-mail Verificado',
      subtitle: _emailVerificado
          ? 'O e-mail do usuário foi confirmado'
          : 'O e-mail do usuário ainda não foi verificado',
      value: _emailVerificado,
      activeIcon: Icons.verified,
      inactiveIcon: Icons.unpublished,
      activeColor: AppColors.success,
      inactiveColor: AppColors.warning,
      onChanged: (value) => setState(() => _emailVerificado = value),
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

  Widget _buildActionButtons(
    BuildContext context,
    UsuarioController controller,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleSaveUsuario(context, controller),
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
              widget.usuario == null ? 'CRIAR USUÁRIO' : 'ATUALIZAR USUÁRIO',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.usuario == null)
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Alterar Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar seleção da galeria
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: AppColors.primary),
              title: Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar câmera
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveUsuario(
    BuildContext context,
    UsuarioController controller,
  ) async {
    if (!_validarFormulario()) return;

    setState(() => _isSubmitting = true);

    try {
      final usuario = Usuario(
        id:
            widget.usuario?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        fotoUrl: null,
        perfil: _perfilSelecionado!,
        dataCriacao: widget.usuario?.dataCriacao ?? DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ultimoAcesso: widget.usuario?.ultimoAcesso,
        ativo: _ativo,
        emailVerificado: _emailVerificado,
        isAdmin: false,
      );

      await controller.saveItem(usuario);

      if (mounted) {
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

    if (_perfilSelecionado == null) {
      _showValidationError('Por favor, selecione um perfil para o usuário');
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
                'Usuário ${widget.usuario == null ? 'criado' : 'atualizado'} com sucesso!',
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

  Future<void> _deleteUsuario(
    BuildContext context,
    UsuarioController controller,
  ) async {
    if (widget.usuario == null) return;

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
              'Tem certeza que deseja excluir o usuário',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.usuario!.nome}"?',
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
        await controller.deleteItem(widget.usuario!);

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
                      'Usuário "${widget.usuario!.nome}" excluído com sucesso',
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
