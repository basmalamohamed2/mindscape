import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/logic/auth_controller.dart';

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .sendEmailSignInLink(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      final justFinished = previous?.isLoading == true && !next.isLoading;
      if (justFinished && !next.hasError) {
        setState(() => _linkSent = true);
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.paper),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _linkSent ? _buildConfirmation() : _buildForm(isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Continue with email',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.paper,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll send a sign-in link — no password to remember.",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: GoogleFonts.inter(color: AppColors.paper, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: GoogleFonts.inter(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.thread),
              ),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              final valid = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(email);
              return valid ? null : 'Enter a valid email address';
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.spark,
                disabledBackgroundColor: AppColors.spark.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(AppColors.sparkText),
                      ),
                    )
                  : Text(
                      'Send sign-in link',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sparkText,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        const Icon(
          Icons.mark_email_read_outlined,
          color: AppColors.thread,
          size: 40,
        ),
        const SizedBox(height: 20),
        Text(
          'Check your inbox',
          style: GoogleFonts.fraunces(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.paper,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We sent a sign-in link to ${_emailController.text.trim()}. "
          "Open it on this device to continue.",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
