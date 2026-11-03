import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_palette.dart';

/// A rounded square showing a category's icon in the category's colour.
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({super.key, required this.category, this.size = 44});

  final ExpenseCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.categoryBackground(category),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        category.icon,
        size: size * 0.5,
        color: palette.categoryColor(category),
      ),
    );
  }
}
