import 'package:flutter/material.dart';

/// The fixed set of categories an expense can belong to.
///
/// Each category carries the label and icon shown in the UI. Colours are not
/// stored here: they come from the theme (see `AppPalette`) so that the whole
/// app is styled from a single seed colour.
enum ExpenseCategory {
  food('Food', Icons.restaurant_rounded),
  transport('Transport', Icons.directions_bus_rounded),
  shopping('Shopping', Icons.shopping_bag_rounded),
  bills('Bills', Icons.receipt_long_rounded),
  health('Health', Icons.medical_services_rounded),
  entertainment('Entertainment', Icons.movie_rounded),
  education('Education', Icons.school_rounded),
  other('Other', Icons.category_rounded);

  const ExpenseCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Converts a stored name back into a category.
  /// Unknown names (for example from an older app version) become [other].
  static ExpenseCategory fromName(String? name) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => ExpenseCategory.other,
    );
  }
}
