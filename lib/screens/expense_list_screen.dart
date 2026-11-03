import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/load_state.dart';
import '../models/summary_period.dart';
import '../providers/expense_provider.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../utils/safe_navigation.dart';
import '../widgets/date_group_header.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/expense_card_list.dart';
import '../widgets/loading_view.dart';
import 'expense_detail_screen.dart';

/// The main list screen: every expense grouped by day, with search,
/// category and period filters.
///
/// It handles the four required screen states: loading, error (with retry),
/// empty, and data. It is used as a tab on the home screen, and is also
/// opened on its own from the insights screen with a category pre-selected.
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({
    super.key,
    this.initialCategory,
    this.initialPeriod = SummaryPeriod.allTime,
    this.onAddExpense,
  });

  final ExpenseCategory? initialCategory;
  final SummaryPeriod initialPeriod;

  /// Opens the add form. Null when this screen was pushed on its own.
  final VoidCallback? onAddExpense;

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchController = TextEditingController();
  ExpenseCategory? _category;
  late SummaryPeriod _period;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _period = widget.initialPeriod;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty ||
      _category != null ||
      _period != SummaryPeriod.allTime;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _category = null;
      _period = SummaryPeriod.allTime;
    });
  }

  void _openDetail(Expense expense) {
    context.pushScreen(ExpenseDetailScreen(expenseId: expense.id));
  }

  Future<void> _deleteWithUndo(Expense expense) async {
    final provider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);
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
    final title = widget.initialCategory != null && widget.onAddExpense == null
        ? '${widget.initialCategory!.label} expenses'
        : 'Expenses';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<SummaryPeriod>(
            tooltip: 'Filter by period',
            icon: Badge(
              isLabelVisible: _period != SummaryPeriod.allTime,
              smallSize: 8,
              child: const Icon(Icons.date_range_rounded),
            ),
            initialValue: _period,
            onSelected: (period) => setState(() => _period = period),
            itemBuilder: (_) => SummaryPeriod.values
                .map(
                  (period) => CheckedPopupMenuItem(
                    value: period,
                    checked: period == _period,
                    child: Text(period.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: switch (provider.loadState) {
        LoadState.loading => const LoadingView(),
        LoadState.error => ErrorView(
          message: provider.errorMessage,
          onRetry: provider.loadExpenses,
        ),
        LoadState.loaded when provider.isEmpty => EmptyView(
          icon: Icons.receipt_long_rounded,
          title: 'No expenses yet',
          message:
              'Every expense you add will appear here, '
              'grouped by day.',
          actionLabel: 'Add your first expense',
          onAction: widget.onAddExpense,
        ),
        LoadState.loaded => _buildList(provider),
      },
    );
  }

  Widget _buildList(ExpenseProvider provider) {
    final theme = Theme.of(context);
    final now = provider.now;
    final results = provider.filter(
      query: _searchController.text,
      category: _category,
      period: _period,
    );
    final total = results.fold<double>(0, (sum, e) => sum + e.amount);

    // Group results by day. A map keeps insertion order, and the provider
    // already sorts newest first, so the groups come out newest first too.
    final groups = <DateTime, List<Expense>>{};
    for (final expense in results) {
      groups
          .putIfAbsent(DateUtils.dateOnly(expense.date), () => [])
          .add(expense);
    }
    final days = groups.keys.toList();
    final padding = Layout.pagePadding(context, bottom: 100);

    return RefreshIndicator(
      onRefresh: () => provider.loadExpenses(showLoading: false),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 0),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search title, note or category',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  10,
                  padding.right,
                  6,
                ),
                children: [
                  _categoryChip(null),
                  for (final category in ExpenseCategory.values)
                    _categoryChip(category),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left + 4,
              8,
              padding.right + 4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${results.length} '
                      '${results.length == 1 ? 'expense' : 'expenses'}'
                      '${_period == SummaryPeriod.allTime ? '' : ' · ${_period.label}'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.currency(total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (results.isEmpty)
            SliverToBoxAdapter(
              child: EmptyView(
                fillPage: false,
                icon: Icons.search_off_rounded,
                title: 'No matching expenses',
                message: 'Try a different search, category or time period.',
                actionLabel: _hasFilters ? 'Clear filters' : null,
                actionIcon: Icons.filter_alt_off_rounded,
                onAction: _clearFilters,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                padding.bottom,
              ),
              sliver: SliverList.builder(
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final dayExpenses = groups[day]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DateGroupHeader(
                        day: day,
                        now: now,
                        total: dayExpenses.fold<double>(
                          0,
                          (sum, e) => sum + e.amount,
                        ),
                      ),
                      ExpenseCardList(
                        expenses: dayExpenses,
                        onTap: _openDetail,
                        onDismissed: _deleteWithUndo,
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(ExpenseCategory? category) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = _category == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: category == null
            ? null
            : Icon(
                category.icon,
                size: 18,
                color: palette.categoryColor(category),
              ),
        label: Text(category?.label ?? 'All'),
        selected: selected,
        selectedColor: category == null
            ? scheme.primaryContainer
            : palette.categoryBackground(category),
        onSelected: (_) => setState(() => _category = category),
      ),
    );
  }
}
