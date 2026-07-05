import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/logic/auth_controller.dart';
import 'package:mindspace/features/auth/screens/email_signin_screen.dart';
import 'package:mindspace/shared/constellation_painter.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(_messageFor(error)),
                backgroundColor: AppColors.surface2,
              ),
            );
          ref.read(authControllerProvider.notifier).clearError();
        },
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final pendingAction = ref.watch(authPendingActionProvider);

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
                        isLoading:
                            isLoading && pendingAction == AuthAction.google,
                        onPressed: isLoading
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle(),
                      ),
                      const SizedBox(height: 12),
                      _AuthButton(
                        label: 'Continue with Email',
                        icon: Icons.mail_outline_rounded,
                        filled: false,
                        isLoading:
                            isLoading && pendingAction == AuthAction.email,
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailSignInScreen(),
                                ),
                              ),
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

  String _messageFor(Object error) {
    final raw = error.toString();
    if (raw.contains('network')) {
      return "Couldn't reach the network. Check your connection and try again.";
    }
    if (raw.contains('account-exists-with-different-credential')) {
      return 'That email is already linked to a different sign-in method.';
    }
    return "Something went wrong signing you in. Please try again.";
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.sparkText : AppColors.paper;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppColors.spark : AppColors.surface,
          disabledBackgroundColor: filled
              ? AppColors.spark.withOpacity(0.6)
              : AppColors.surface,
          disabledForegroundColor: foreground.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: AppColors.line),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(foreground),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
