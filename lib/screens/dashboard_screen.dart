import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/load_state.dart';
import '../models/summary_period.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../utils/safe_navigation.dart';
import '../widgets/app_logo.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/expense_card_list.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_header.dart';
import '../widgets/spending_hero_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/weekly_bar_chart.dart';
import 'expense_detail_screen.dart';

/// The home tab: this month's spending at a glance, the last seven days,
/// and the most recent expenses.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onSeeAll,
    required this.onAddExpense,
  });

  /// Switches to the Expenses tab.
  final VoidCallback onSeeAll;
  final VoidCallback onAddExpense;

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final now = expenses.now;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: Layout.pagePadding(context).left,
        title: Row(
          children: [
            const AppLogo(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting(now),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Text('SpendWise'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: switch (expenses.loadState) {
        LoadState.loading => const LoadingView(),
        LoadState.error => ErrorView(
            message: expenses.errorMessage,
            onRetry: expenses.loadExpenses,
          ),
        LoadState.loaded => _buildContent(context, expenses),
      },
    );
  }

  Widget _buildContent(BuildContext context, ExpenseProvider expenses) {
    final budget = context.watch<SettingsProvider>().monthlyBudget;
    final now = expenses.now;
    final recent = expenses.expenses.take(5).toList();
    final week = expenses.lastSevenDays;

    return ListView(
      padding: Layout.pagePadding(context, bottom: 100),
      children: [
        SpendingHeroCard(
          month: now,
          spent: expenses.totalFor(SummaryPeriod.thisMonth),
          changePercent: expenses.changeFromLastMonth,
          budget: budget,
          onBudgetTap: () => BudgetDialog.edit(context),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  value: Formatters.currencyWhole(expenses.spentToday),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.date_range_rounded,
                  label: 'Last 7 days',
                  value: Formatters.currencyWhole(expenses.spentLastSevenDays),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.speed_rounded,
                  label: 'Daily average',
                  value:
                      Formatters.currencyWhole(expenses.dailyAverageThisMonth),
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Last 7 days',
          trailing: Formatters.currency(expenses.spentLastSevenDays),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            child: WeeklyBarChart(values: week, today: now),
          ),
        ),
        SectionHeader(
          title: 'Recent expenses',
          actionLabel: recent.isEmpty ? null : 'See all',
          onAction: onSeeAll,
        ),
        if (recent.isEmpty)
          Card(
            child: EmptyView(
              fillPage: false,
              icon: Icons.receipt_long_rounded,
              title: 'No expenses yet',
              message: 'Add your first expense and your spending '
                  'summary will appear here.',
              actionLabel: 'Add expense',
              onAction: onAddExpense,
            ),
          )
        else
          ExpenseCardList(
            expenses: recent,
            showDate: true,
            now: now,
            onTap: (expense) =>
                context.pushScreen(ExpenseDetailScreen(expenseId: expense.id)),
          ),
      ],
    );
  }
}
