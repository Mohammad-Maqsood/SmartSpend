import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/category_total.dart';
import '../theme/app_palette.dart';

/// A ring chart where each coloured arc is one category's share of spending.
///
/// The ring is drawn with a [CustomPainter]. A [TweenAnimationBuilder]
/// sweeps it in from 0 to 100% when it first appears.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.totals,
    required this.centerLabel,
    required this.centerValue,
    this.size = 210,
  });

  final List<CategoryTotal> totals;
  final String centerLabel;
  final String centerValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final shares = totals.map((total) => total.share).toList();
    final colors =
        totals.map((total) => palette.categoryColor(total.category)).toList();

    return Semantics(
      label: 'Spending by category chart. $centerLabel $centerValue',
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => CustomPaint(
            painter: _DonutPainter(
              shares: shares,
              colors: colors,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              progress: progress,
            ),
            child: child,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      centerValue,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.shares,
    required this.colors,
    required this.trackColor,
    required this.progress,
  });

  final List<double> shares;
  final List<Color> colors;
  final Color trackColor;
  final double progress;

  static const _strokeWidth = 24.0;
  static const _gap = 0.04; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(_strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = trackColor);

    final gap = shares.length > 1 ? _gap : 0.0;
    var start = -math.pi / 2; // begin at the top
    for (var i = 0; i < shares.length; i++) {
      final sweep = shares[i] * math.pi * 2 * progress;
      if (sweep > gap) {
        canvas.drawArc(
            arcRect, start + gap / 2, sweep - gap, false, paint..color = colors[i]);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.shares != shares ||
      old.colors != colors;
}
