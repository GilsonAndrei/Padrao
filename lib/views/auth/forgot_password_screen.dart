import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../widgets/custom_text_field.dart';
import 'package:projeto_padrao/core/responsive/responsive_layout.dart';
import 'package:projeto_padrao/core/responsive/responsive_utils.dart';
import 'package:projeto_padrao/core/responsive/breakpoints.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _emailSent = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(authController),
        tablet: _buildTabletLayout(authController),
        desktop: _buildDesktopLayout(authController),
      ),
    );
  }

  Widget _buildMobileLayout(AuthController authController) {
    return Stack(
      children: [
        // Background gradient
        _buildBackground(),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: _buildFormContent(authController),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(AuthController authController) {
    return Stack(
      children: [
        _buildBackground(),
        SafeArea(
          child: Center(
            child: Container(
              width: 520,
              padding: EdgeInsets.all(40),
              child: SingleChildScrollView(
                child: _buildFormContent(authController),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AuthController authController) {
    return Stack(
      children: [
        _buildBackground(),
        SafeArea(
          child: Row(
            children: [
              // Sidebar ilustrativo
              Expanded(flex: 1, child: _buildIllustrationSidebar()),
              // Formulário
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(60),
                  child: SingleChildScrollView(
                    child: _buildFormContent(authController),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.98),
            AppColors.background.withOpacity(0.95),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.secondary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone animado (simulado)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_reset, size: 60, color: Colors.white),
          ),
          SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  'Recuperação Segura',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Enviaremos um link seguro para redefinir sua senha. Verifique sua caixa de entrada.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(AuthController authController) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com navegação
          _buildNavigationHeader(),
          SizedBox(
            height: _getResponsiveValue(mobile: 40, tablet: 60, desktop: 80),
          ),

          // Conteúdo principal
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: _emailSent
                ? _buildSuccessState()
                : _buildRecoveryForm(authController),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(width: 16),
        Text(
          'Voltar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryForm(AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header do formulário
        _buildFormHeader(),
        SizedBox(
          height: _getResponsiveValue(mobile: 40, tablet: 50, desktop: 60),
        ),

        // Campo de email
        _buildEmailField(),
        SizedBox(
          height: _getResponsiveValue(mobile: 30, tablet: 36, desktop: 42),
        ),

        // Botão de recuperação
        _buildRecoveryButton(authController),
        SizedBox(
          height: _getResponsiveValue(mobile: 24, tablet: 28, desktop: 32),
        ),

        // Informações adicionais
        _buildAdditionalInfo(),
      ],
    );
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone animado
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.lock_reset, size: 36, color: Colors.white),
        ),
        SizedBox(height: 24),

        Text(
          'Recuperar Acesso',
          style: TextStyle(
            fontSize: _getResponsiveValue(mobile: 32, tablet: 36, desktop: 40),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),

        Text(
          'Digite seu e-mail cadastrado e enviaremos um link seguro para redefinir sua senha.',
          style: TextStyle(
            fontSize: _getResponsiveValue(mobile: 16, tablet: 17, desktop: 18),
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E-mail de recuperação',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: _emailController,
          label: 'seu@email.com',
          prefixIcon: Icons.email_outlined,
          prefixIconColor: AppColors.textSecondary,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite seu e-mail';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Digite um e-mail válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRecoveryButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      height: _getResponsiveValue(mobile: 56, tablet: 60, desktop: 64),
      child: ElevatedButton(
        onPressed: (_isLoading || authController.isLoading)
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  FocusScope.of(context).unfocus();

                  try {
                    await authController.recuperarSenha(
                      _emailController.text.trim(),
                    );

                    // Simula um delay para melhor UX
                    await Future.delayed(Duration(milliseconds: 500));

                    setState(() {
                      _emailSent = true;
                      _isLoading = false;
                    });
                  } catch (e) {
                    setState(() => _isLoading = false);
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: (_isLoading || authController.isLoading)
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Enviar Link de Recuperação',
                    style: TextStyle(
                      fontSize: _getResponsiveValue(
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.info),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verifique também sua pasta de spam caso não encontre o e-mail.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de sucesso
        _buildSuccessHeader(),
        SizedBox(
          height: _getResponsiveValue(mobile: 40, tablet: 50, desktop: 60),
        ),

        // Card de confirmação
        _buildSuccessCard(),
        SizedBox(
          height: _getResponsiveValue(mobile: 32, tablet: 40, desktop: 48),
        ),

        // Ações
        _buildSuccessActions(),
      ],
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Icon(Icons.check_circle, size: 36, color: AppColors.success),
        ),
        SizedBox(height: 24),

        Text(
          'E-mail Enviado!',
          style: TextStyle(
            fontSize: _getResponsiveValue(mobile: 32, tablet: 36, desktop: 40),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),

        Text(
          'Enviamos um link seguro para redefinir sua senha.',
          style: TextStyle(
            fontSize: _getResponsiveValue(mobile: 16, tablet: 17, desktop: 18),
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 24, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E-mail enviado para:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: AppColors.borderLight),
          SizedBox(height: 20),
          _buildInstructionItem(
            icon: Icons.access_time,
            text: 'O link expira em 1 hora',
            color: AppColors.warning,
          ),
          SizedBox(height: 12),
          _buildInstructionItem(
            icon: Icons.security,
            text: 'Link 100% seguro e criptografado',
            color: AppColors.success,
          ),
          SizedBox(height: 12),
          _buildInstructionItem(
            icon: Icons.folder_open,
            text: 'Verifique a pasta de spam',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: _getResponsiveValue(mobile: 56, tablet: 60, desktop: 64),
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
                _emailController.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Enviar para outro e-mail',
              style: TextStyle(
                fontSize: _getResponsiveValue(
                  mobile: 16,
                  tablet: 17,
                  desktop: 18,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: RichText(
              text: TextSpan(
                text: 'Lembrou sua senha? ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Fazer login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ MÉTODO AUXILIAR PARA VALORES RESPONSIVOS
  double _getResponsiveValue({
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (Breakpoints.isMobile(width)) return mobile;
    if (Breakpoints.isTablet(width)) return tablet;
    return desktop;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
