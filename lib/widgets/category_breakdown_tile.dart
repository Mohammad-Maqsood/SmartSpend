import 'package:flutter/material.dart';

import '../models/category_total.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import 'category_icon_badge.dart';

/// One category row on the insights screen: amount, share bar and count.
class CategoryBreakdownTile extends StatelessWidget {
  const CategoryBreakdownTile({
    super.key,
    required this.total,
    required this.onTap,
  });

  final CategoryTotal total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final count = total.count;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            CategoryIconBadge(category: total.category),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          total.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        Formatters.currency(total.amount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total.share.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: palette.categoryColor(total.category),
                      backgroundColor: palette.categoryBackground(
                        total.category,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$count ${count == 1 ? 'expense' : 'expenses'}',
                          style: muted,
                        ),
                      ),
                      Text(
                        '${(total.share * 100).toStringAsFixed(1)}%',
                        style: muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
