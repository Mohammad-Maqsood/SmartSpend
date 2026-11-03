import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// A simple bar chart of spending over the last seven days.
///
/// Built from ordinary widgets (no chart package): each bar is a container
/// whose height is its value divided by the largest value.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.values, required this.today});

  /// Seven amounts, oldest first. The last one is today.
  final List<double> values;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = values.fold<double>(0, math.max);

    return Semantics(
      label: 'Bar chart of spending over the last 7 days',
      child: SizedBox(
        height: 170,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (index) {
            final value = values[index];
            final isToday = index == values.length - 1;
            final day = DateTime(
                today.year, today.month, today.day - (values.length - 1 - index));
            final fraction = maxValue == 0 ? 0.0 : value / maxValue;
            return Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value > 0 ? Formatters.compactCurrency(value) : '',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          width: math.min(28, constraints.maxWidth * 0.6),
                          height: math.max(6, constraints.maxHeight * fraction),
                          decoration: BoxDecoration(
                            color: isToday
                                ? scheme.primary
                                : scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isToday ? 'Today' : Formatters.weekdayShort(day),
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
