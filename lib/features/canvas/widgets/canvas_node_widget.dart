import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/models/canvas_node_model.dart';

class CanvasNodeWidget extends StatelessWidget {
  const CanvasNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final CanvasNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;

  static const double _rootDiameter = 64;
  static const double _childDiameter = 44;

  @override
  Widget build(BuildContext context) {
    final diameter = node.isRoot ? _rootDiameter : _childDiameter;
    Offset dragPosition = node.position;

    return Positioned(
      left: node.position.dx - diameter / 2,
      top: node.position.dy - diameter / 2,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: (_) => dragPosition = node.position,
        onPanUpdate: (details) {
          dragPosition = dragPosition + details.delta;
          onDragUpdate(dragPosition);
        },
        onPanEnd: (_) => onDragEnd(dragPosition),
        child: SizedBox(
          width: diameter + 6,
          height: diameter + 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: node.isRoot ? node.color : AppColors.surface,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.paper
                        : (node.isRoot ? Colors.transparent : node.color),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: node.isRoot
                      ? [
                          BoxShadow(
                            color: node.color.withOpacity(0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  node.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: node.isRoot ? 11 : 9.5,
                    fontWeight: FontWeight.w700,
                    color: node.isRoot ? AppColors.sparkText : AppColors.paper,
                  ),
                ),
              ),
              if (node.hasImage)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.thread,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.ink, width: 1.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      size: 9,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
