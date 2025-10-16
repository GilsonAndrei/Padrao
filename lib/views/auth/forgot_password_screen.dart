// views/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                _buildHeader(),
                SizedBox(height: 40),

                if (!_emailSent) ...[
                  // Campo de email
                  CustomTextField(
                    controller: _emailController,
                    label: 'E-mail cadastrado',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'Digite um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),

                  // Botão de recuperação
                  _buildRecoveryButton(authController),
                ] else ...[
                  // Mensagem de sucesso
                  _buildSuccessMessage(),
                ],

                SizedBox(height: 30),

                // Link para login
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_reset, size: 70, color: Colors.orange),
        SizedBox(height: 20),
        Text(
          'Recuperar senha',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _emailSent
              ? 'Verifique seu e-mail'
              : 'Digite seu e-mail para recuperar a senha',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecoveryButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authController.isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await authController.recuperarSenha(
                      _emailController.text.trim(),
                    );
                    setState(() {
                      _emailSent = true;
                    });
                  } catch (e) {
                    // O erro já é tratado no controller e mostrado via SnackBar
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.orange.withOpacity(0.3),
        ),
        child: authController.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Enviar link de recuperação',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 50, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'E-mail enviado com sucesso!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Enviamos um link de recuperação para:',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _emailController.text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: RichText(
          text: TextSpan(
            text: 'Lembrou sua senha? ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            children: [
              TextSpan(
                text: 'Faça login',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
