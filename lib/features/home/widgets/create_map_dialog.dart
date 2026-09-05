import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/home/logic/home_controller.dart';

class CreateMapDialog extends ConsumerStatefulWidget {
  const CreateMapDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const CreateMapDialog(),
    );
  }

  @override
  ConsumerState<CreateMapDialog> createState() => _CreateMapDialogState();
}

class _CreateMapDialogState extends ConsumerState<CreateMapDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final id = await ref
        .read(homeControllerProvider.notifier)
        .createMindMap(title);
    if (!mounted) return;

    if (id == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the map. Please try again.'),
          backgroundColor: AppColors.surface2,
        ),
      );
      return;
    }

    navigator.pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name your map',
              style: GoogleFonts.fraunces(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: AppColors.paper,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.inter(color: AppColors.paper, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Q3 Product Launch',
                hintStyle: GoogleFonts.inter(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.spark,
                  ),
                  child: _submitting
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
                          'Create',
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
    );
  }
}
