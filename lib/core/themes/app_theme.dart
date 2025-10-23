// core/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Cores Principais
      primaryColor: AppColors.primary,
      primaryColorDark: AppColors.primaryDark,
      primaryColorLight: AppColors.primaryLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar - COM GRADIENTE GLOBAL
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Transparente para o gradiente
        foregroundColor: Colors.white, // Ícones e texto em branco
        elevation: 3,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Textos
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: AppColors.textDisabled,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
      ),

      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      useMaterial3: true,
    );
  }

  // ✅ MÉTODO AUXILIAR: Para criar AppBars com gradiente consistentemente
  static AppBar createGradientAppBar({
    required String title,
    List<Widget>? actions,
    bool? automaticallyImplyLeading = true,
    Widget? leading,
    double elevation = 3,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      leading: leading,
      elevation: elevation,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
    );
  }

  // ✅ AppBar com ícone de deletar destacado (CORRIGIDO)
  static AppBar createGradientAppBarWithDelete({
    required String title,
    required VoidCallback onDelete,
    bool isDeleting = false,
    bool showDelete = true,
    List<Widget>? actions, // ✅ CORREÇÃO: Adicionado parâmetro actions
    bool? automaticallyImplyLeading = true,
    Widget? leading,
  }) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      leading: leading,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      actions: [
        // ✅ Primeiro os actions customizados
        if (actions != null) ...actions,

        // ✅ Depois o botão de deletar
        if (showDelete) ...[
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDeleting
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDeleting
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.delete_outline,
                color: isDeleting ? Colors.white54 : Colors.white,
                size: 20,
              ),
            ),
            onPressed: isDeleting ? null : onDelete,
            tooltip: 'Excluir',
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ✅ AppBar sem botão de voltar
  static AppBar createGradientAppBarNoBack({
    required String title,
    List<Widget>? actions,
    double elevation = 3,
  }) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: false,
      actions: actions,
      elevation: elevation,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
    );
  }

  // ✅ AppBar simples para telas básicas
  static AppBar createSimpleGradientAppBar({
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      ),
    );
  }
}
