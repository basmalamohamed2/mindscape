import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/canvas/logic/canvas_controller.dart';
import 'package:mindspace/features/canvas/widgets/ai_suggestions_sheet.dart';
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

  Future<void> _pickAndAttachImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    try {
      await _controller.attachImage(widget.node.id, picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't upload that photo. Please try again."),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    final dueDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await _controller.convertToTask(widget.node.id, dueDate);
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
    final liveNode = _liveNode;
    final isUploadingThisNode =
        ref.watch(nodeImageUploadProvider) == widget.node.id;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
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
            if (liveNode.hasImage || isUploadingThisNode) ...[
              _ImagePreview(
                imageUrl: liveNode.imageUrl,
                isUploading: isUploadingThisNode,
                onRemove: () => _controller.removeImage(widget.node.id),
              ),
              const SizedBox(height: 14),
            ],
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
                    selected: liveNode.color.value == color.value,
                    onTap: () =>
                        _controller.updateNodeColor(widget.node.id, color),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 18),
            _TaskSection(
              node: liveNode,
              onConvert: () => _pickDueDate(context),
              onToggleComplete: (value) =>
                  _controller.setTaskCompleted(widget.node.id, value),
              onRemoveTask: () => _controller.removeTaskStatus(widget.node.id),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AiSuggestionsSheet.show(
                  context,
                  mapId: widget.mapId,
                  node: liveNode,
                ),
                label: Text(
                  'Suggest related ideas',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paper,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.thread.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SheetAction(
                    icon: Icons.image_outlined,
                    label: liveNode.hasImage ? 'Change photo' : 'Add photo',
                    onTap: isUploadingThisNode ? null : _pickAndAttachImage,
                  ),
                ),
                const SizedBox(width: 10),
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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageUrl,
    required this.isUploading,
    required this.onRemove,
  });

  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.surface2),
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.thread),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.muted,
                  ),
                ),
              ),
            if (isUploading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.thread),
                  ),
                ),
              ),
            if (!isUploading && imageUrl != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
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
  final VoidCallback? onTap;
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

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.node,
    required this.onConvert,
    required this.onToggleComplete,
    required this.onRemoveTask,
  });

  final CanvasNode node;
  final VoidCallback onConvert;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onRemoveTask;

  @override
  Widget build(BuildContext context) {
    if (!node.isTask) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onConvert,
          icon: const Icon(
            Icons.event_available_outlined,
            size: 17,
            color: AppColors.muted,
          ),
          label: Text(
            'Convert to task',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.paper),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    final isOverdue =
        !node.isCompleted && node.dueDate!.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: node.isCompleted,
            onChanged: (value) => onToggleComplete(value ?? false),
            activeColor: AppColors.thread,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.isCompleted ? 'Completed' : 'Due',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDueDate(node.dueDate!),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: isOverdue
                        ? const Color(0xFFF26B6B)
                        : AppColors.paper,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove task',
            onPressed: onRemoveTask,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDueDate(DateTime dueDate) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = dueDate.hour % 12 == 0 ? 12 : dueDate.hour % 12;
    final period = dueDate.hour < 12 ? 'AM' : 'PM';
    final minute = dueDate.minute.toString().padLeft(2, '0');
    return '${months[dueDate.month - 1]} ${dueDate.day}, $hour12:$minute $period';
  }
}
