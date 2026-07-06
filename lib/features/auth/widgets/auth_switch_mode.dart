import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';

class AuthSwitchMode extends StatelessWidget {
  const AuthSwitchMode({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.thread),
        ),
      ),
    );
  }
}
