import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/logic/auth_controller.dart';
import 'package:mindspace/features/auth/logic/provider/auth_repository.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  static const _confirmWord = 'DELETE';

  final _confirmController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _deleting = false;
  String? _error;

  bool get _needsPassword =>
      ref.read(authRepositoryProvider).reauthNeedsPassword;

  bool get _canDelete =>
      !_deleting &&
      _confirmController.text.trim().toUpperCase() == _confirmWord &&
      (!_needsPassword || _passwordController.text.isNotEmpty);

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_canDelete) return;
    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(
            password: _needsPassword ? _passwordController.text : null,
          );
      if (mounted) Navigator.of(context).pop();
    } on SignInCancelledException {
      _fail(null);
    } on FirebaseAuthException catch (e) {
      _fail(_authMessage(e.code));
    } on FirebaseException catch (e) {
      _fail(
        e.code == 'unavailable'
            ? 'No connection. Check your internet and try again.'
            : "Couldn't delete your data. Please try again.",
      );
    } catch (_) {
      _fail("Couldn't delete your account. Please try again.");
    }
  }

  void _fail(String? message) {
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _error = message;
    });
  }

  String _authMessage(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'missing-password':
        return 'Wrong password. Please try again.';
      case 'user-mismatch':
        return 'Please choose the same Google account you signed in with.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'requires-recent-login':
        return 'Please try again to confirm your identity.';
      default:
        return "Couldn't delete your account. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsPassword = _needsPassword;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete account',
              style: GoogleFonts.fraunces(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: AppColors.paper,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This permanently deletes your account and all the maps you '
              'own. You will also be removed from maps shared with you. '
              'This cannot be undone and needs an internet connection.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              enabled: !_deleting,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(color: AppColors.paper, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type $_confirmWord to confirm',
                hintStyle: GoogleFonts.inter(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 10),
            if (needsPassword)
              TextField(
                controller: _passwordController,
                enabled: !_deleting,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: AppColors.paper, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Your password',
                  hintStyle: GoogleFonts.inter(color: AppColors.muted),
                ),
              )
            else
              Text(
                "You'll be asked to confirm with your Google account.",
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _deleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _canDelete ? _delete : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete forever'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
