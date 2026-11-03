import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// The heading above a day's expenses, e.g. "Today ......... ₹1,250.00".
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({
    super.key,
    required this.day,
    required this.total,
    required this.now,
  });

  final DateTime day;
  final double total;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Formatters.relativeDay(day, now),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            Formatters.currency(total),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
