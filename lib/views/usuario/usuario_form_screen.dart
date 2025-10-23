import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_search_controller.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/services/perfil/perfil_service.dart';
import 'package:projeto_padrao/views/search/generic_search_screen.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/responsive/responsive_layout.dart';
import 'package:projeto_padrao/core/responsive/responsive_utils.dart';
import 'package:projeto_padrao/core/responsive/breakpoints.dart';

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
  bool _loadingPerfil = false;

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

    // ✅ CORREÇÃO: Carregar perfil se estiver editando
    if (widget.usuario?.perfil != null &&
        widget.usuario!.perfil.id.isNotEmpty) {
      _carregarPerfilUsuario();
    }

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

  // ✅ NOVO MÉTODO: Carregar perfil do usuário
  Future<void> _carregarPerfilUsuario() async {
    if (widget.usuario?.perfil == null) return;

    setState(() {
      _loadingPerfil = true;
    });

    try {
      final perfilService = PerfilService();
      final perfilCompleto = await perfilService.getPerfilById(
        widget.usuario!.perfil.id,
      );

      if (perfilCompleto != null) {
        setState(() {
          _perfilSelecionado = perfilCompleto;
        });
      }
    } catch (e) {
      print('Erro ao carregar perfil: $e');
    } finally {
      setState(() {
        _loadingPerfil = false;
      });
    }
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
          : ResponsiveLayout(
              mobile: _buildMobileForm(
                context,
                usuarioController,
                perfilController,
              ),
              tablet: _buildTabletForm(
                context,
                usuarioController,
                perfilController,
              ),
              desktop: _buildDesktopForm(
                context,
                usuarioController,
                perfilController,
              ),
            ),
    );
  }

  Widget _buildMobileForm(
    BuildContext context,
    UsuarioController usuarioController,
    PerfilController perfilController,
  ) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsiveScreenPadding(context),
      child: _buildFormContent(context, usuarioController, perfilController),
    );
  }

  Widget _buildTabletForm(
    BuildContext context,
    UsuarioController usuarioController,
    PerfilController perfilController,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsiveScreenPadding(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildUserPhotoSection()),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: _buildFormFields(
                context,
                usuarioController,
                perfilController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopForm(
    BuildContext context,
    UsuarioController usuarioController,
    PerfilController perfilController,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildUserPhotoSection(),
                const SizedBox(height: 32),
                _buildSettingsSection(perfilController),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(context, usuarioController),
                ],
              ),
            ),
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildUserPhotoSection(),
          const SizedBox(height: 24),
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildSettingsSection(perfilController),
          const SizedBox(height: 32),
          _buildActionButtons(context, usuarioController),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    UsuarioController usuarioController,
    PerfilController perfilController,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildSettingsSection(perfilController),
          const SizedBox(height: 32),
          _buildActionButtons(context, usuarioController),
        ],
      ),
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

  Widget _buildUserPhotoSection() {
    return ResponsiveValue<double>(
      mobile: 100,
      tablet: 120,
      desktop: 140,
      builder: (size) => Column(
        children: [
          Stack(
            children: [
              Container(
                width: size,
                height: size,
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
                child: Icon(
                  Icons.person,
                  size: size * 0.4,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Container(
                    width: size * 0.3,
                    height: size * 0.3,
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
                    child: Icon(
                      Icons.camera_alt,
                      size: size * 0.15,
                      color: Colors.white,
                    ),
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
      ),
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
        _buildPerfilDropdown(perfilController),
        const SizedBox(height: 20),
        _buildStatusSwitch(),
        const SizedBox(height: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil de Acesso *',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPerfilSearch(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _perfilSelecionado == null
                    ? AppColors.error.withOpacity(0.5)
                    : AppColors.border,
                width: _perfilSelecionado == null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.manage_accounts,
                  color: _perfilSelecionado == null
                      ? AppColors.error
                      : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _loadingPerfil
                      ? _buildLoadingPerfil()
                      : _perfilSelecionado == null
                      ? Text(
                          'Selecione um perfil',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _perfilSelecionado!.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_perfilSelecionado!.descricao.isNotEmpty)
                              Text(
                                _perfilSelecionado!.descricao,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (_perfilSelecionado == null && !_loadingPerfil) ...[
          const SizedBox(height: 4),
          Text(
            'Por favor, selecione um perfil',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingPerfil() {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Carregando perfil...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  // No método _showPerfilSearch do UsuarioFormScreen
  void _showPerfilSearch(BuildContext context) {
    final controller = PerfilSearchController(
      PerfilService(),
      apenasAtivos: true,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GenericSearchScreen<PerfilUsuario>(
            controller: controller,
            title: 'Selecionar Perfil', // ✅ Agora o título é usado
            searchHint: 'Buscar por nome ou descrição...',
            enableSelection: true,
            isModal: true,
            showAppBar: false, // ✅ CORREÇÃO: Não mostra o AppBar nativo
            itemBuilder: (perfil) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perfil.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (perfil.descricao.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      perfil.descricao,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: perfil.ativo
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: perfil.ativo ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          perfil.ativo ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            fontSize: 12,
                            color: perfil.ativo ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onItemSelected: (perfil) {
              setState(() {
                _perfilSelecionado = perfil;
              });
            },
          ),
        );
      },
    );
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
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: AppColors.primary),
              title: Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
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
