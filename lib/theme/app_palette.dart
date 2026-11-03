import 'package:flutter/material.dart';

import '../models/expense_category.dart';

/// Extra theme colours that Material's ColorScheme does not cover:
/// one colour per expense category.
///
/// The colours are not typed in by hand. They are calculated from the app's
/// seed colour by rotating its hue around the colour wheel, so the whole app
/// still comes from one seed colour.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.categoryColors});

  factory AppPalette.fromSeed(Color seed, Brightness brightness) {
    final base = HSLColor.fromColor(seed);
    final count = ExpenseCategory.values.length;
    final isDark = brightness == Brightness.dark;
    return AppPalette(
      categoryColors: List.generate(count, (index) {
        final hue = (base.hue + index * 360 / count) % 360;
        return HSLColor.fromAHSL(1, hue, 0.60, isDark ? 0.70 : 0.44).toColor();
      }),
    );
  }

  final List<Color> categoryColors;

  Color categoryColor(ExpenseCategory category) =>
      categoryColors[category.index % categoryColors.length];

  /// A soft tint of the category colour, used behind category icons.
  Color categoryBackground(ExpenseCategory category) =>
      categoryColor(category).withValues(alpha: 0.16);

  /// Reads the palette from the current theme.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({List<Color>? categoryColors}) =>
      AppPalette(categoryColors: categoryColors ?? this.categoryColors);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      categoryColors: List.generate(
        categoryColors.length,
        (i) => Color.lerp(categoryColors[i], other.categoryColors[i], t)!,
      ),
    );
  }
}
