import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QiblaCompass extends StatelessWidget {
  final double? compassHeading;
  final double? qiblaDirection;

  const QiblaCompass({
    super.key,
    required this.compassHeading,
    required this.qiblaDirection,
  });

  @override
  Widget build(BuildContext context) {
    final heading = compassHeading ?? 0;
    final qibla = qiblaDirection ?? 0;
    final qiblaFromNorth = (qibla - heading + 360) % 360;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.surface,
              AppColors.background,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Compass ring
            Transform.rotate(
              angle: -heading * (math.pi / 180),
              child: CustomPaint(
                size: const Size.square(280),
                painter: CompassPainter(),
              ),
            ),
            // Qibla indicator
            Transform.rotate(
              angle: qiblaFromNorth * (math.pi / 180),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mosque,
                      color: AppColors.textOnAccent,
                      size: 32,
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent,
                          AppColors.accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Center indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw compass circle
    final circlePaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw degree markers
    final markerPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 30) {
      final angle = i * (math.pi / 180);
      final outer = Offset(
        center.dx + radius * math.cos(angle - math.pi / 2),
        center.dy + radius * math.sin(angle - math.pi / 2),
      );
      final inner = Offset(
        center.dx + (radius - 15) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 15) * math.sin(angle - math.pi / 2),
      );
      canvas.drawLine(inner, outer, markerPaint);
    }

    // Draw cardinal directions
    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final directions = ['U', 'T', 'S', 'B'];
    for (int i = 0; i < 4; i++) {
      final angle = i * 90 * (math.pi / 180);
      final pos = Offset(
        center.dx + (radius - 35) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 35) * math.sin(angle - math.pi / 2),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: i == 0
              ? textStyle.copyWith(color: AppColors.error)
              : textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
