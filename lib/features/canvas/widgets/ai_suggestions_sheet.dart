import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/canvas/logic/ai_suggestions_controller.dart';
import 'package:mindspace/features/canvas/logic/canvas_controller.dart';
import 'package:mindspace/models/canvas_node_model.dart';

class AiSuggestionsSheet extends ConsumerStatefulWidget {
  const AiSuggestionsSheet({
    super.key,
    required this.mapId,
    required this.node,
  });

  final String mapId;
  final CanvasNode node;

  static Future<void> show(
    BuildContext context, {
    required String mapId,
    required CanvasNode node,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiSuggestionsSheet(mapId: mapId, node: node),
    );
  }

  @override
  ConsumerState<AiSuggestionsSheet> createState() => _AiSuggestionsSheetState();
}

class _AiSuggestionsSheetState extends ConsumerState<AiSuggestionsSheet> {
  int _addedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(aiSuggestionsControllerProvider.notifier)
          .generate(widget.node.text);
    });
  }

  void _acceptSuggestion(String suggestion) {
    final angle = _addedCount * (math.pi / 3) - math.pi / 4;
    final offset = Offset(70 * math.cos(angle), 70 * math.sin(angle));
    _addedCount++;

    ref
        .read(canvasControllerProvider(widget.mapId).notifier)
        .addSuggestedNode(
          text: suggestion,
          position: widget.node.position + offset,
          parentId: widget.node.id,
        );
    ref.read(aiSuggestionsControllerProvider.notifier).remove(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsState = ref.watch(aiSuggestionsControllerProvider);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ideas for "${widget.node.text}"',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.paper,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(child: _buildContent(suggestionsState)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AsyncValue<List<String>> suggestionsState) {
    return suggestionsState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.thread),
          ),
        ),
      ),
      error: (error, _) => _ErrorState(
        message: error is Exception
            ? error.toString()
            : 'Something went wrong.',
        onRetry: () => ref
            .read(aiSuggestionsControllerProvider.notifier)
            .generate(widget.node.text),
      ),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                _addedCount > 0
                    ? 'All added! Tap below for more ideas.'
                    : 'No suggestions right now.',
                style: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final suggestion in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SuggestionChip(
                    text: suggestion,
                    onAccept: () => _acceptSuggestion(suggestion),
                    onDismiss: () => ref
                        .read(aiSuggestionsControllerProvider.notifier)
                        .remove(suggestion),
                  ),
                ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () => ref
                      .read(aiSuggestionsControllerProvider.notifier)
                      .generate(widget.node.text),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.thread,
                  ),
                  label: Text(
                    'More ideas',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.thread,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    required this.onAccept,
    required this.onDismiss,
  });

  final String text;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.muted,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.paper),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onAccept,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.thread,
              size: 20,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.muted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try again',
              style: GoogleFonts.inter(color: AppColors.thread),
            ),
          ),
        ],
      ),
    );
  }
}
