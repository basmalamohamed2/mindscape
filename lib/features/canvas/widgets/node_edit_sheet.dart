import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/canvas/logic/canvas_controller.dart';
import 'package:mindspace/models/canvas_node_model.dart';

const List<Color> _kNodeColors = [
  Color(0xFFFFB84D), // spark
  Color(0xFF6DE1D2), // thread
  Color(0xFFF26B6B), // red
  Color(0xFF8B90B3), // muted
  Color(0xFF5C6BC0), // indigo
];

class NodeEditSheet extends ConsumerStatefulWidget {
  const NodeEditSheet({super.key, required this.mapId, required this.node});

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
      builder: (_) => NodeEditSheet(mapId: mapId, node: node),
    );
  }

  @override
  ConsumerState<NodeEditSheet> createState() => _NodeEditSheetState();
}

class _NodeEditSheetState extends ConsumerState<NodeEditSheet> {
  late final TextEditingController _textController =
      TextEditingController(text: widget.node.text)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.node.text.length,
        );

  CanvasController get _controller =>
      ref.read(canvasControllerProvider(widget.mapId).notifier);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _commitText() {
    _controller.updateNodeText(widget.node.id, _textController.text);
  }

  void _commitAndClose() {
    _commitText();
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final hasChildren = ref
        .read(canvasControllerProvider(widget.mapId))
        .nodes
        .any((n) => n.parentId == widget.node.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete "${widget.node.text}"?',
          style: GoogleFonts.inter(color: AppColors.paper),
        ),
        content: Text(
          hasChildren
              ? 'This will also delete every idea branching from it. '
                    "This can't be undone."
              : "This can't be undone.",
          style: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF26B6B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _controller.deleteNode(widget.node.id);
      Navigator.of(context).pop();
    }
  }

  CanvasNode get _liveNode {
    final nodes = ref.watch(canvasControllerProvider(widget.mapId)).nodes;
    for (final node in nodes) {
      if (node.id == widget.node.id) return node;
    }
    return widget.node;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final bottomSafeArea = mediaQuery.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboardHeight > 0 ? keyboardHeight : bottomSafeArea,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            TextField(
              controller: _textController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onEditingComplete: _commitAndClose,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.paper,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final color in _kNodeColors) ...[
                  _ColorSwatch(
                    color: color,
                    selected: _liveNode.color.value == color.value,
                    onTap: () =>
                        _controller.updateNodeColor(widget.node.id, color),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SheetAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add idea',
                    onTap: () {
                      _commitText();
                      _controller.addNode(
                        position: widget.node.position + const Offset(70, 70),
                        parentId: widget.node.id,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetAction(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDestructive: true,
                    onTap: () => _confirmDelete(context),
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

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: AppColors.paper, width: 2)
              : null,
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFF26B6B) : AppColors.paper;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: color)),
          ],
        ),
      ),
    );
  }
}
