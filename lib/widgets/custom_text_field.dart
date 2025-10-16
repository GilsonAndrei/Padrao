// widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import '../core/themes/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final Widget? suffixIcon; // Alterado para Widget
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final VoidCallback? onSuffixIconPressed;
  final bool enabled;
  final int? maxLines;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.prefixIconColor,
    this.suffixIcon, // Agora aceita qualquer Widget
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.onSuffixIconPressed,
    this.enabled = true,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.maxLines,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppColors.textDisabled,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: widget.prefixIconColor ?? AppColors.textSecondary,
                size: 20,
              )
            : null,
        suffixIcon: _buildSuffixIcon(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: widget.enabled ? AppColors.surface : AppColors.borderLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    // Se foi fornecido um suffixIcon customizado, usa ele
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    // Se for campo de senha, cria o botão de mostrar/esconder
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return null;
  }
}
