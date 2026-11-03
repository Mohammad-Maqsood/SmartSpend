import 'expense_category.dart';

/// The amount spent in one category over a period, used by the summary screen.
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.amount,
    required this.count,
    required this.share,
  });

  final ExpenseCategory category;

  /// Total money spent in this category.
  final double amount;

  /// Number of expenses in this category.
  final int count;

  /// Fraction of the period's total, from 0.0 to 1.0.
  final double share;
}
