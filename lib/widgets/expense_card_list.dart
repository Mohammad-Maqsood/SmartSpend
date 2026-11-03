import 'package:flutter/material.dart';

import '../models/expense.dart';
import 'expense_tile.dart';

/// A card holding several expense rows separated by thin dividers.
///
/// When [onDismissed] is given, each row can be swiped left to delete it.
class ExpenseCardList extends StatelessWidget {
  const ExpenseCardList({
    super.key,
    required this.expenses,
    required this.onTap,
    this.onDismissed,
    this.showDate = false,
    this.now,
  });

  final List<Expense> expenses;
  final ValueChanged<Expense> onTap;
  final ValueChanged<Expense>? onDismissed;
  final bool showDate;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      Widget row = ExpenseTile(
        expense: expense,
        showDate: showDate,
        now: now,
        onTap: () => onTap(expense),
      );
      if (onDismissed != null) {
        row = Dismissible(
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDismissed!(expense),
          background: Container(
            color: scheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(Icons.delete_outline_rounded,
                color: scheme.onErrorContainer),
          ),
          child: row,
        );
      }
      if (i > 0) rows.add(const Divider(indent: 74));
      rows.add(row);
    }
    return Card(child: Column(children: rows));
  }
}
