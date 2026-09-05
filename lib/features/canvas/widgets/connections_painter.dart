import 'package:flutter/material.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/models/canvas_node_model.dart';

class ConnectionsPainter extends CustomPainter {
  ConnectionsPainter(this.nodes);

  final List<CanvasNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.thread.withOpacity(0.45)
      ..strokeWidth = 1.4;

    final byId = {for (final n in nodes) n.id: n};

    for (final node in nodes) {
      final parent = node.parentId == null ? null : byId[node.parentId];
      if (parent == null) continue;
      canvas.drawLine(parent.position, node.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}
