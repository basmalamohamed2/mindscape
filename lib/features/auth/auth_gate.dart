import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';
import 'package:mindspace/features/auth/logic/provider/user_profile_repository.dart';
import 'package:mindspace/features/auth/screens/onboarding_screen.dart';
import 'package:mindspace/features/home/screens/home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    ref.listen(authStateChangesProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value?.uid != user.uid) {
        ref.read(userProfileRepositoryProvider).upsertProfile(user);
      }
    });

    return authState.when(
      data: (user) =>
          user == null ? const OnboardingScreen() : const HomeScreen(),
      loading: () => const _SplashLoader(),
      error: (error, _) => _AuthGateError(
        onRetry: () => ref.invalidate(authStateChangesProvider),
      ),
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.spark),
        ),
      ),
    );
  }
}

class _AuthGateError extends StatelessWidget {
  const _AuthGateError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Couldn't start MindScape.\nCheck your connection and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
