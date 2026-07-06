import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/core/theme/app_input_decoration.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
    this.hint = 'Password',
    this.autofillHints,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final FormFieldValidator<String> validator;
  final String hint;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autofillHints: autofillHints,
      style: GoogleFonts.inter(color: AppColors.paper, fontSize: 14),
      decoration: AppInputDecoration.build(
        hint: hint,
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.muted,
            size: 19,
          ),
        ),
      ),
    );
  }
}
