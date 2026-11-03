import 'package:flutter/material.dart';

import '../models/category_total.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/load_state.dart';
import '../models/summary_period.dart';
import '../services/expense_storage.dart';

/// The single source of truth for expenses, shared by every screen.
///
/// Screens read data with `context.watch<ExpenseProvider>()` and change it
/// through the methods below. Every change is saved to the device right away;
/// if saving fails the change is rolled back so the screen never shows data
/// that is not really stored.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ExpenseStorage _storage;

  /// Gives the current time. Tests pass a fixed clock to get stable results.
  final DateTime Function() _clock;

  List<Expense> _expenses = const [];
  LoadState _loadState = LoadState.loading;
  String? _errorMessage;

  /// All expenses, newest first. The list cannot be modified directly.
  List<Expense> get expenses => _expenses;
  LoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _expenses.isEmpty;
  DateTime get now => _clock();

  // ---------------------------------------------------------------------------
  // Loading and saving
  // ---------------------------------------------------------------------------

  /// Reads expenses from the device.
  ///
  /// Pull-to-refresh passes [showLoading] false so the list stays on screen
  /// (the refresh indicator already shows progress).
  Future<void> loadExpenses({bool showLoading = true}) async {
    if (showLoading) {
      _loadState = LoadState.loading;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _expenses = _sorted(await _storage.readExpenses());
      _loadState = LoadState.loaded;
    } catch (_) {
      _errorMessage =
          'We could not read your saved expenses. Please try again.';
      _loadState = LoadState.error;
    }
    notifyListeners();
  }

  Future<bool> addExpense(Expense expense) {
    return _commit([..._expenses, expense]);
  }

  Future<bool> updateExpense(Expense updated) async {
    if (findById(updated.id) == null) return false;
    return _commit([
      for (final expense in _expenses)
        expense.id == updated.id ? updated : expense,
    ]);
  }

  Future<bool> deleteExpense(String id) {
    return _commit(_expenses.where((expense) => expense.id != id).toList());
  }

  /// Puts back an expense that was just deleted (used by "Undo").
  Future<bool> restoreExpense(Expense expense) async {
    if (findById(expense.id) != null) return true;
    return addExpense(expense);
  }

  Future<bool> clearAll() => _commit([]);

  /// Shows [next] immediately, then saves it. Rolls back if saving fails.
  Future<bool> _commit(List<Expense> next) async {
    // Never overwrite storage while the saved data has not loaded correctly.
    if (_loadState != LoadState.loaded) return false;

    final previous = _expenses;
    _expenses = _sorted(next);
    notifyListeners();
    try {
      await _storage.writeExpenses(_expenses);
      return true;
    } catch (_) {
      _expenses = previous;
      notifyListeners();
      return false;
    }
  }

  static List<Expense> _sorted(List<Expense> expenses) {
    final copy = [...expenses]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
    return List.unmodifiable(copy);
  }

  // ---------------------------------------------------------------------------
  // Queries used by the screens
  // ---------------------------------------------------------------------------

  Expense? findById(String id) {
    for (final expense in _expenses) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  /// Expenses matching a search text, an optional category and a period.
  List<Expense> filter({
    String query = '',
    ExpenseCategory? category,
    SummaryPeriod period = SummaryPeriod.allTime,
  }) {
    final now = _clock();
    final text = query.trim().toLowerCase();
    return _expenses.where((expense) {
      if (category != null && expense.category != category) return false;
      if (!period.includes(expense.date, now)) return false;
      if (text.isEmpty) return true;
      return expense.title.toLowerCase().contains(text) ||
          expense.note.toLowerCase().contains(text) ||
          expense.category.label.toLowerCase().contains(text);
    }).toList();
  }

  List<Expense> expensesIn(SummaryPeriod period) => filter(period: period);

  double totalFor(SummaryPeriod period) => _sum(expensesIn(period));

  /// Totals per category for [period], largest first.
  List<CategoryTotal> categoryTotals(SummaryPeriod period) {
    final inPeriod = expensesIn(period);
    final total = _sum(inPeriod);
    final amounts = <ExpenseCategory, double>{};
    final counts = <ExpenseCategory, int>{};
    for (final expense in inPeriod) {
      amounts.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
      counts.update(expense.category, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return amounts.entries
        .map((entry) => CategoryTotal(
              category: entry.key,
              amount: entry.value,
              count: counts[entry.key]!,
              share: total == 0 ? 0 : entry.value / total,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// Expenses in the same calendar month as [month], optionally one category.
  List<Expense> expensesInMonth(DateTime month, {ExpenseCategory? category}) {
    return _expenses
        .where((expense) =>
            expense.date.year == month.year &&
            expense.date.month == month.month &&
            (category == null || expense.category == category))
        .toList();
  }

  double get spentToday {
    final today = _clock();
    return _sum(
        _expenses.where((expense) => DateUtils.isSameDay(expense.date, today)));
  }

  /// Spending on each of the last seven days, oldest first (index 6 = today).
  List<double> get lastSevenDays {
    final today = DateUtils.dateOnly(_clock());
    return List.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day - (6 - index));
      return _sum(
          _expenses.where((expense) => DateUtils.isSameDay(expense.date, day)));
    });
  }

  double get spentLastSevenDays =>
      lastSevenDays.fold(0, (total, amount) => total + amount);

  double get dailyAverageThisMonth {
    final now = _clock();
    return totalFor(SummaryPeriod.thisMonth) / now.day;
  }

  /// Percentage change of this month so far against the same days of last
  /// month. Returns null when there is nothing to compare with.
  double? get changeFromLastMonth {
    final now = _clock();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthSoFar = _sum(expensesInMonth(lastMonth)
        .where((expense) => expense.date.day <= now.day));
    if (lastMonthSoFar == 0) return null;
    final thisMonth = totalFor(SummaryPeriod.thisMonth);
    return (thisMonth - lastMonthSoFar) / lastMonthSoFar * 100;
  }

  static double _sum(Iterable<Expense> expenses) =>
      expenses.fold(0, (total, expense) => total + expense.amount);
}
