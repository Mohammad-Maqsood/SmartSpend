import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/expense.dart';
import 'package:spendwise/models/expense_category.dart';
import 'package:spendwise/models/load_state.dart';
import 'package:spendwise/models/summary_period.dart';
import 'package:spendwise/providers/expense_provider.dart';

import 'helpers/fake_expense_storage.dart';

Expense expense(
  String id,
  double amount,
  ExpenseCategory category,
  DateTime date,
) =>
    Expense(
      id: id,
      title: 'Expense $id',
      amount: amount,
      category: category,
      date: date,
      createdAt: date,
    );

void main() {
  // A fixed "now" so results do not depend on when the tests run.
  final now = DateTime(2026, 11, 15, 10);

  final sample = [
    expense('1', 300, ExpenseCategory.food, DateTime(2026, 11, 15)),
    expense('2', 200, ExpenseCategory.food, DateTime(2026, 11, 10)),
    expense('3', 500, ExpenseCategory.bills, DateTime(2026, 11, 2)),
    expense('4', 400, ExpenseCategory.transport, DateTime(2026, 10, 12)),
    expense('5', 1000, ExpenseCategory.shopping, DateTime(2025, 12, 31)),
  ];

  Future<ExpenseProvider> loadedProvider(FakeExpenseStorage storage) async {
    final provider = ExpenseProvider(storage, clock: () => now);
    await provider.loadExpenses();
    return provider;
  }

  test('loads expenses sorted newest first', () async {
    final provider =
        await loadedProvider(FakeExpenseStorage(initial: sample.reversed.toList()));

    expect(provider.loadState, LoadState.loaded);
    expect(provider.expenses.map((e) => e.id), ['1', '2', '3', '4', '5']);
  });

  test('goes to the error state when reading fails', () async {
    final provider =
        await loadedProvider(FakeExpenseStorage(failedReadsLeft: 1));

    expect(provider.loadState, LoadState.error);
    expect(provider.errorMessage, isNotNull);
  });

  test('totals per period', () async {
    final provider = await loadedProvider(FakeExpenseStorage(initial: sample));

    expect(provider.totalFor(SummaryPeriod.thisMonth), 1000);
    expect(provider.totalFor(SummaryPeriod.lastMonth), 400);
    expect(provider.totalFor(SummaryPeriod.thisYear), 1400);
    expect(provider.totalFor(SummaryPeriod.allTime), 2400);
    expect(provider.spentToday, 300);
  });

  test('category totals are grouped, counted and sorted largest first',
      () async {
    final provider = await loadedProvider(FakeExpenseStorage(initial: sample));
    final totals = provider.categoryTotals(SummaryPeriod.thisMonth);

    expect(totals.map((t) => t.category),
        [ExpenseCategory.food, ExpenseCategory.bills]);
    expect(totals.first.amount, 500);
    expect(totals.first.count, 2);
    expect(totals.first.share, closeTo(0.5, 0.0001));
  });

  test('last seven days ends with today', () async {
    final provider = await loadedProvider(FakeExpenseStorage(initial: sample));
    final week = provider.lastSevenDays;

    expect(week, hasLength(7));
    expect(week.last, 300); // 15 Nov
    expect(week[1], 200); // 10 Nov
    expect(provider.spentLastSevenDays, 500);
  });

  test('compares this month with the same days of last month', () async {
    final provider = await loadedProvider(FakeExpenseStorage(initial: sample));
    // Nov 1-15: 1000. Oct 1-15: 400. Change = +150%.
    expect(provider.changeFromLastMonth, closeTo(150, 0.0001));
  });

  test('filter matches search text, category and period', () async {
    final provider = await loadedProvider(FakeExpenseStorage(initial: sample));

    expect(provider.filter(query: 'expense 3').map((e) => e.id), ['3']);
    expect(provider.filter(category: ExpenseCategory.food), hasLength(2));
    expect(provider.filter(period: SummaryPeriod.lastMonth).single.id, '4');
    expect(provider.filter(query: 'bills'), hasLength(1));
  });

  test('add, update and delete are saved to storage', () async {
    final storage = FakeExpenseStorage();
    final provider = await loadedProvider(storage);
    final item = sample.first;

    expect(await provider.addExpense(item), isTrue);
    expect(storage.saved.single.id, item.id);

    expect(await provider.updateExpense(item.copyWith(amount: 999)), isTrue);
    expect(storage.saved.single.amount, 999);

    expect(await provider.deleteExpense(item.id), isTrue);
    expect(storage.saved, isEmpty);
    expect(provider.isEmpty, isTrue);
  });

  test('a failed save is rolled back so the screen matches storage', () async {
    final storage = FakeExpenseStorage(initial: [sample.first]);
    final provider = await loadedProvider(storage);
    storage.failWrites = true;

    expect(await provider.addExpense(sample[1]), isFalse);
    expect(provider.expenses, hasLength(1));

    expect(await provider.deleteExpense(sample.first.id), isFalse);
    expect(provider.expenses, hasLength(1));
  });

  test('never overwrites storage after a failed load', () async {
    final storage =
        FakeExpenseStorage(initial: sample, failedReadsLeft: 1);
    final provider = await loadedProvider(storage);

    expect(await provider.addExpense(sample.first), isFalse);
    expect(storage.saved, hasLength(sample.length));
  });

  test('undo restores a deleted expense', () async {
    final storage = FakeExpenseStorage(initial: sample);
    final provider = await loadedProvider(storage);

    await provider.deleteExpense('3');
    await provider.restoreExpense(sample[2]);

    expect(provider.findById('3'), isNotNull);
    expect(storage.saved, hasLength(sample.length));
  });
}
