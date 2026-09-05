import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/logic/auth_controller.dart';
import 'package:mindspace/features/auth/logic/auth_error.dart';
import 'package:mindspace/features/auth/widgets/password_strength_indicator.dart';
import 'package:mindspace/core/utils/validators.dart';
import 'package:mindspace/features/auth/widgets/auth_button.dart';
import 'package:mindspace/features/auth/widgets/auth_header.dart';
import 'package:mindspace/features/auth/widgets/auth_switch_mode.dart';
import 'package:mindspace/features/auth/widgets/auth_text_field.dart';
import 'package:mindspace/features/auth/widgets/forget_password_button.dart';
import 'package:mindspace/features/auth/widgets/password_field.dart';

enum _EmailMode { signIn, register }

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _EmailMode _mode = _EmailMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _isRegister => _mode == _EmailMode.register;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(authControllerProvider.notifier);

    if (_isRegister) {
      await controller.registerWithEmail(email, password);
      if (!mounted) return;
      if (!ref.read(authControllerProvider).hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created — check your inbox to verify.'),
            backgroundColor: AppColors.surface2,
          ),
        );
      }
    } else {
      await controller.signInWithEmail(email, password);
    }
  }

  void _switchMode(_EmailMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    ref.read(authControllerProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(AuthErrorMapper.map(error)),
                backgroundColor: AppColors.surface2,
              ),
            );
        },
      );
    });

    final pendingAction = ref.watch(authPendingActionProvider);
    final isLoading =
        pendingAction == AuthAction.emailSignIn ||
        pendingAction == AuthAction.emailRegister;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.paper),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                AuthHeader(
                  title: _isRegister ? 'Create your account' : 'Welcome back',
                  subtitle: _isRegister
                      ? 'Just an email and a password to get started.'
                      : 'Sign in with your email and password.',
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _emailController,
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  autofillHints: [
                    _isRegister
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  validator: _isRegister
                      ? Validators.password
                      : Validators.signInPassword,
                ),
                if (_isRegister)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _passwordController,
                    builder: (context, value, _) =>
                        PasswordStrengthIndicator(password: value.text),
                  )
                else
                  const SizedBox(height: 4),
                if (_isRegister) ...[
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _confirmController,
                    hint: 'Confirm password',
                    obscure: _obscureConfirm,
                    onToggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: Validators.confirmPassword(_passwordController),
                  ),
                ],
                if (!_isRegister) ...[
                  const SizedBox(height: 4),
                  const ForgotPasswordButton(),
                ],
                const SizedBox(height: 18),
                AuthButton(
                  label: _isRegister ? 'Create account' : 'Sign in',
                  loading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                AuthSwitchMode(
                  label: _isRegister
                      ? 'Already have an account? Sign in'
                      : "Don't have an account? Sign up",
                  onPressed: isLoading
                      ? null
                      : () => _switchMode(
                          _isRegister ? _EmailMode.signIn : _EmailMode.register,
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
