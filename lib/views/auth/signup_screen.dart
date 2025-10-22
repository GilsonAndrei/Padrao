import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../widgets/custom_text_field.dart';
import 'package:projeto_padrao/core/responsive/responsive_layout.dart';
import 'package:projeto_padrao/core/responsive/responsive_utils.dart';
import 'package:projeto_padrao/core/responsive/breakpoints.dart';
import '../../core/themes/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../app/app_widget.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
        // Background com gradiente sutil
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
              // Sidebar premium
              Expanded(flex: 1, child: _buildPremiumSidebar()),
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

  Widget _buildPremiumSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.95),
            AppColors.secondary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone premium com efeito
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 40),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              children: [
                Text(
                  'Junte-se a Nós',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Crie sua conta e tenha acesso a todas as funcionalidades do nosso sistema de forma segura e intuitiva.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                // Features list
                _buildFeatureItem('Cadastro rápido e seguro'),
                _buildFeatureItem('Acesso a todas as funcionalidades'),
                _buildFeatureItem('Suporte 24/7'),
                _buildFeatureItem('Interface moderna e intuitiva'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
          _buildSignupForm(authController),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.textSecondary,
            ),
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

  Widget _buildSignupForm(AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header do formulário
        _buildFormHeader(),
        SizedBox(
          height: _getResponsiveValue(mobile: 40, tablet: 50, desktop: 60),
        ),

        // Campos do formulário
        _buildFormFields(authController),
        SizedBox(
          height: _getResponsiveValue(mobile: 24, tablet: 32, desktop: 40),
        ),

        // Botão de cadastro
        _buildSignupButton(authController),
        SizedBox(
          height: _getResponsiveValue(mobile: 32, tablet: 40, desktop: 48),
        ),

        // Divisor
        _buildDivider(),
        SizedBox(
          height: _getResponsiveValue(mobile: 32, tablet: 40, desktop: 48),
        ),

        // Botão de login
        _buildLoginButton(),

        // Link adicional para mobile/tablet
        ResponsiveLayout(
          mobile: _buildAdditionalLinks(),
          tablet: _buildAdditionalLinks(),
          desktop: SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo/Ícone premium
        Container(
          width: _getResponsiveValue(mobile: 70, tablet: 90, desktop: 100),
          height: _getResponsiveValue(mobile: 70, tablet: 90, desktop: 100),
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
          child: Icon(
            Icons.person_add_alt_1_rounded,
            size: _getResponsiveValue(mobile: 32, tablet: 40, desktop: 44),
            color: Colors.white,
          ),
        ),
        SizedBox(height: 24),

        Text(
          'Criar Nova Conta',
          style: TextStyle(
            fontSize: _getResponsiveValue(mobile: 32, tablet: 36, desktop: 40),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),

        Text(
          'Preencha os dados abaixo para criar sua conta e acessar todas as funcionalidades do sistema.',
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

  Widget _buildFormFields(AuthController authController) {
    return Column(
      children: [
        // Campo de Nome
        _buildNameField(),
        SizedBox(
          height: _getResponsiveValue(mobile: 20, tablet: 24, desktop: 28),
        ),

        // Campo de Email
        _buildEmailField(),
        SizedBox(
          height: _getResponsiveValue(mobile: 20, tablet: 24, desktop: 28),
        ),

        // Campo de Senha
        _buildPasswordField(),
        SizedBox(
          height: _getResponsiveValue(mobile: 20, tablet: 24, desktop: 28),
        ),

        // Campo de Confirmar Senha
        _buildConfirmPasswordField(),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome Completo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: _nomeController,
          label: 'Seu nome completo',
          prefixIcon: Icons.person_outline_rounded,
          prefixIconColor: AppColors.textSecondary,
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite seu nome';
            }
            if (value.length < 3) {
              return 'O nome deve ter pelo menos 3 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E-mail',
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Senha',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: _passwordController,
          label: 'Sua senha',
          prefixIcon: Icons.lock_outline_rounded,
          prefixIconColor: AppColors.textSecondary,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          isPassword: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite sua senha';
            }
            if (value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmar Senha',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirme sua senha',
          prefixIcon: Icons.lock_outline_rounded,
          prefixIconColor: AppColors.textSecondary,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          isPassword: _obscureConfirmPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, confirme sua senha';
            }
            if (value != _passwordController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton(AuthController authController) {
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

                  bool success = await authController.cadastrar(
                    _nomeController.text.trim(),
                    _emailController.text.trim(),
                    _passwordController.text,
                  );

                  setState(() => _isLoading = false);

                  if (success && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      NavigationService.navigateReplacement(AppRoutes.home);
                    });
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authController.errorMessage ?? 'Erro ao cadastrar',
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
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
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: _getResponsiveValue(
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Criar Minha Conta',
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border, thickness: 1, height: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: _getResponsiveValue(
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.border, thickness: 1, height: 1),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: _getResponsiveValue(mobile: 56, tablet: 60, desktop: 64),
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_rounded,
              size: _getResponsiveValue(mobile: 18, tablet: 20, desktop: 22),
            ),
            SizedBox(width: 12),
            Text(
              'Fazer Login',
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

  Widget _buildAdditionalLinks() {
    return Container(
      margin: EdgeInsets.only(top: 32),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Já tem uma conta? ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: _getResponsiveValue(
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Text(
              'Fazer login',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: _getResponsiveValue(
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
          ),
        ],
      ),
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
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
