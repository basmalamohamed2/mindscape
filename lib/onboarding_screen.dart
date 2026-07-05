import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/shared/constellation_painter.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    this.onContinueWithGoogle,
    this.onContinueWithEmail,
  });

  final VoidCallback? onContinueWithGoogle;
  final VoidCallback? onContinueWithEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.4, -0.6),
                  radius: 0.9,
                  colors: [Color(0x1A6DE1D2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5, 0.3),
                  radius: 0.9,
                  colors: [Color(0x1AFFB84D), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: CustomPaint(painter: ConstellationMarkPainter()),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'MindScape',
                        style: GoogleFonts.fraunces(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          color: AppColors.paper,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Where thoughts find\ntheir shape.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _AuthButton(
                        label: 'Continue with Google',
                        icon: Icons.link_rounded,
                        filled: true,
                        onPressed: onContinueWithGoogle,
                      ),
                      const SizedBox(height: 12),
                      _AuthButton(
                        label: 'Continue with Email',
                        icon: Icons.mail_outline_rounded,
                        filled: false,
                        onPressed: onContinueWithEmail,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'By continuing you agree to the\nTerms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: AppColors.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: filled ? AppColors.sparkText : AppColors.paper,
        ),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: filled ? AppColors.sparkText : AppColors.paper,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppColors.spark : AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: AppColors.line),
          ),
        ),
      ),
    );
  }
}
