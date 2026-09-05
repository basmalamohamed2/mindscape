import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/core/utils/relative_time.dart';
import 'package:mindspace/models/mind_map_model.dart';

class MindMapCard extends StatelessWidget {
  const MindMapCard({
    super.key,
    required this.mindMap,
    required this.onTap,
    required this.onDelete,
  });

  final MindMap mindMap;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const _MiniConstellationThumb(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mindMap.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.paper,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final edited = 'edited ${relativeTime(mindMap.updatedAt)}';
    if (mindMap.collaboratorCount == 0) return '$edited · solo';
    final count = mindMap.collaboratorCount;
    final noun = count == 1 ? 'collaborator' : 'collaborators';
    return '$edited · $count $noun';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete "${mindMap.title}"?',
          style: GoogleFonts.inter(color: AppColors.paper),
        ),
        content: Text(
          'This can\'t be undone.',
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

    if (confirmed == true) onDelete();
  }
}

class _MiniConstellationThumb extends StatelessWidget {
  const _MiniConstellationThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _ThumbPainter()),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hero = Offset(size.width * 0.5, size.height * 0.35);
    final a = Offset(size.width * 0.25, size.height * 0.7);
    final b = Offset(size.width * 0.75, size.height * 0.7);

    final line = Paint()
      ..color = AppColors.thread.withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(hero, a, line);
    canvas.drawLine(hero, b, line);

    canvas.drawCircle(hero, 3.5, Paint()..color = AppColors.spark);
    canvas.drawCircle(a, 2.2, Paint()..color = AppColors.thread);
    canvas.drawCircle(b, 2.2, Paint()..color = AppColors.thread);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
