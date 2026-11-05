import 'package:smart_spend/models/expense.dart';
import 'package:smart_spend/services/expense_storage.dart';

/// An in-memory storage for tests that can be told to fail.
class FakeExpenseStorage extends ExpenseStorage {
  FakeExpenseStorage({
    List<Expense> initial = const [],
    this.failedReadsLeft = 0,
    this.failWrites = false,
  }) : saved = [...initial];

  List<Expense> saved;

  /// How many of the next reads should throw an error.
  int failedReadsLeft;
  bool failWrites;

  @override
  Future<List<Expense>> readExpenses() async {
    if (failedReadsLeft > 0) {
      failedReadsLeft--;
      throw Exception('Simulated read failure');
    }
    return [...saved];
  }

  @override
  Future<void> writeExpenses(List<Expense> expenses) async {
    if (failWrites) throw Exception('Simulated write failure');
    saved = [...expenses];
  }
}
