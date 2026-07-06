import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';

enum PasswordStrength { weak, medium, strong }

PasswordStrength _scorePassword(String password) {
  if (password.length < 6) return PasswordStrength.weak;

  var variety = 0;
  if (RegExp(r'[a-z]').hasMatch(password)) variety++;
  if (RegExp(r'[A-Z]').hasMatch(password)) variety++;
  if (RegExp(r'[0-9]').hasMatch(password)) variety++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) variety++;

  if (password.length >= 10 && variety >= 3) return PasswordStrength.strong;
  if (password.length >= 8 && variety >= 2) return PasswordStrength.strong;
  if (variety >= 2) return PasswordStrength.medium;
  return PasswordStrength.weak;
}

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox(height: 20);

    final strength = _scorePassword(password);
    final (color, label, fraction) = switch (strength) {
      PasswordStrength.weak => (const Color(0xFFF26B6B), 'Weak', 1 / 3),
      PasswordStrength.medium => (AppColors.spark, 'Medium', 2 / 3),
      PasswordStrength.strong => (AppColors.thread, 'Strong', 1.0),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 4,
              width: double.infinity,
              color: AppColors.surface2,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
