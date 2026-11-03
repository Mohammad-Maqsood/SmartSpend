import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_total.dart';
import '../models/load_state.dart';
import '../models/summary_period.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../utils/safe_navigation.dart';
import '../widgets/category_breakdown_tile.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/mini_stat.dart';
import '../widgets/section_header.dart';
import 'expense_list_screen.dart';

/// The summary screen: total spending per category for a chosen period,
/// shown as a ring chart and a ranked list.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  SummaryPeriod _period = SummaryPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: switch (provider.loadState) {
        LoadState.loading => const LoadingView(),
        LoadState.error => ErrorView(
          message: provider.errorMessage,
          onRetry: provider.loadExpenses,
        ),
        LoadState.loaded => _buildContent(provider),
      },
    );
  }

  Widget _buildContent(ExpenseProvider provider) {
    final totals = provider.categoryTotals(_period);
    final total = provider.totalFor(_period);
    final count = totals.fold<int>(0, (sum, t) => sum + t.count);
    final padding = Layout.pagePadding(context, bottom: 100);

    // The chip row scrolls sideways right to the screen edges, so it sits
    // outside the horizontal page padding used by the cards below.
    return ListView(
      padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: padding.left, right: padding.right),
            children: SummaryPeriod.values
                .map(
                  (period) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period.label),
                      selected: period == _period,
                      onSelected: (_) => setState(() => _period = period),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.only(left: padding.left, right: padding.right),
          child: _buildSummary(totals, total, count),
        ),
      ],
    );
  }

  Widget _buildSummary(List<CategoryTotal> totals, double total, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totals.isEmpty)
          Card(
            child: EmptyView(
              fillPage: false,
              icon: Icons.pie_chart_outline_rounded,
              title: 'Nothing to show',
              message:
                  'You have no expenses for '
                  '${_period.label.toLowerCase()}. '
                  'Pick another period or add an expense.',
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                children: [
                  CategoryDonutChart(
                    key: ValueKey(_period),
                    totals: totals,
                    centerLabel: _period.label,
                    centerValue: Formatters.currencyWhole(total),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStat(label: 'Expenses', value: '$count'),
                      ),
                      Expanded(
                        child: MiniStat(
                          label: 'Average',
                          value: Formatters.currencyWhole(total / count),
                        ),
                      ),
                      Expanded(
                        child: MiniStat(
                          label: 'Top category',
                          value: totals.first.category.label,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Spending by category'),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < totals.length; i++) ...[
                  if (i > 0) const Divider(indent: 74),
                  CategoryBreakdownTile(
                    total: totals[i],
                    onTap: () => context.pushScreen(
                      ExpenseListScreen(
                        initialCategory: totals[i].category,
                        initialPeriod: _period,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
