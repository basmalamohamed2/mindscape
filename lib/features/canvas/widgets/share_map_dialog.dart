import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/core/utils/validators.dart';
import 'package:mindspace/features/auth/logic/provider/user_profile_repository.dart';
import 'package:mindspace/features/home/logic/provider/mind_map_repository.dart';

class ShareMapDialog extends ConsumerStatefulWidget {
  const ShareMapDialog({super.key, required this.mapId});

  final String mapId;

  static Future<void> show(BuildContext context, {required String mapId}) {
    return showDialog(
      context: context,
      builder: (_) => ShareMapDialog(mapId: mapId),
    );
  }

  @override
  ConsumerState<ShareMapDialog> createState() => _ShareMapDialogState();
}

class _ShareMapDialogState extends ConsumerState<ShareMapDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final uid = await ref
          .read(userProfileRepositoryProvider)
          .findUidByEmail(email);

      if (uid == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('No MindScape account found for $email.'),
            backgroundColor: AppColors.surface2,
          ),
        );
        return;
      }

      await ref
          .read(mindMapRepositoryProvider)
          .addCollaborator(widget.mapId, uid);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$email can now edit this map.'),
          backgroundColor: AppColors.surface2,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't send the invite. Please try again."),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite a collaborator',
                style: GoogleFonts.fraunces(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: AppColors.paper,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "They'll be able to view and edit this map. They need "
                'a MindScape account already.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: GoogleFonts.inter(color: AppColors.paper, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'friend@example.com',
                  hintStyle: GoogleFonts.inter(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.spark,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.sparkText,
                              ),
                            ),
                          )
                        : Text(
                            'Invite',
                            style: GoogleFonts.inter(
                              color: AppColors.sparkText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
