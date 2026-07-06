import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';

class AppInputDecoration {
  const AppInputDecoration._();

  static InputDecoration build({
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.thread),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFF26B6B)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFF26B6B)),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 11.5,
        color: const Color(0xFFF26B6B),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
