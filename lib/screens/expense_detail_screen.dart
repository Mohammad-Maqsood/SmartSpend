import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../utils/safe_navigation.dart';
import '../widgets/category_icon_badge.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_view.dart';
import '../widgets/info_row.dart';
import 'expense_form_screen.dart';

/// Shows everything about one expense, with edit and delete actions.
///
/// It receives only the expense id and looks the expense up in the provider,
/// so it always shows the latest data (for example right after editing).
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  Future<void> _edit(BuildContext context, Expense expense) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await context.pushScreen<bool>(
      ExpenseFormScreen(expense: expense),
    );
    if (saved == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Changes saved')));
    }
  }

  Future<void> _delete(BuildContext context, Expense expense) async {
    final provider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete this expense?',
      message:
          'This removes it from your records. '
          'You can undo straight after.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    navigator.pop();
    final deleted = await provider.deleteExpense(expense.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        deleted
            ? SnackBar(
                content: const Text('Expense deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => provider.restoreExpense(expense),
                ),
              )
            : const SnackBar(
                content: Text(
                  'Could not delete this expense. Please try again.',
                ),
              ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expense = provider.findById(expenseId);

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense details')),
        body: EmptyView(
          icon: Icons.search_off_rounded,
          title: 'Expense not found',
          message: 'It may have been deleted.',
          actionLabel: 'Go back',
          actionIcon: Icons.arrow_back_rounded,
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final categoryColor = palette.categoryColor(expense.category);

    // Extra context that the list row does not show.
    final sameCategory = provider.expensesInMonth(
      expense.date,
      category: expense.category,
    );
    final categoryTotal = sameCategory.fold<double>(
      0,
      (total, e) => total + e.amount,
    );
    final monthTotal = provider
        .expensesInMonth(expense.date)
        .fold<double>(0, (total, e) => total + e.amount);
    final shareOfCategory = categoryTotal == 0
        ? 0
        : expense.amount / categoryTotal * 100;
    final shareOfMonth = monthTotal == 0
        ? 0
        : expense.amount / monthTotal * 100;
    final monthLabel = Formatters.monthYear(expense.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, expense),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(context, expense),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: Layout.pagePadding(context, bottom: 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  CategoryIconBadge(category: expense.category, size: 68),
                  const SizedBox(height: 16),
                  SelectableText(
                    expense.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Formatters.currency(expense.amount),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.categoryBackground(expense.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      expense.category.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: Formatters.fullDate(expense.date),
                ),
                const Divider(indent: 64),
                InfoRow(
                  icon: expense.paymentMethod.icon,
                  label: 'Paid with',
                  value: expense.paymentMethod.label,
                ),
                const Divider(indent: 64),
                InfoRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Note',
                  value: expense.hasNote ? expense.note : 'No note added',
                  muted: !expense.hasNote,
                ),
                const Divider(indent: 64),
                InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Recorded on',
                  value: Formatters.dateTime(expense.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'This is ${shareOfCategory.toStringAsFixed(0)}% of your '
                      '${expense.category.label} spending in $monthLabel '
                      '(${Formatters.currency(categoryTotal)} across '
                      '${sameCategory.length} '
                      '${sameCategory.length == 1 ? 'expense' : 'expenses'}), '
                      'and ${shareOfMonth.toStringAsFixed(0)}% of everything '
                      'you spent that month.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
