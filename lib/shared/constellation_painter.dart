import 'package:flutter/material.dart';
import 'package:mindspace/core/theme/app_colors.dart';

class ConstellationMarkPainter extends CustomPainter {
  const ConstellationMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hero = Offset(w * 0.5, h * 0.23);
    final left = Offset(w * 0.23, h * 0.67);
    final right = Offset(w * 0.77, h * 0.67);
    final bottom = Offset(w * 0.5, h * 0.87);

    final threadPaint = Paint()
      ..color = AppColors.thread.withOpacity(0.6)
      ..strokeWidth = 1.2;
    final mutedThreadPaint = Paint()
      ..color = AppColors.muted.withOpacity(0.5)
      ..strokeWidth = 1.2;

    canvas.drawLine(hero, left, threadPaint);
    canvas.drawLine(hero, right, threadPaint);
    canvas.drawLine(left, bottom, mutedThreadPaint);
    canvas.drawLine(right, bottom, mutedThreadPaint);

    canvas.drawCircle(hero, w * 0.07, Paint()..color = AppColors.spark);
    canvas.drawCircle(left, w * 0.05, Paint()..color = AppColors.thread);
    canvas.drawCircle(right, w * 0.05, Paint()..color = AppColors.thread);
    canvas.drawCircle(bottom, w * 0.04, Paint()..color = AppColors.muted);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
