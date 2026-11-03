import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

/// Saves and loads expenses on the device using SharedPreferences.
///
/// The whole list is stored as one JSON string. This keeps the code simple
/// and is fast enough for the few thousand records a person creates.
class ExpenseStorage {
  static const storageKey = 'spendwise.expenses.v1';

  Future<List<Expense>> readExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Saved expenses are not a list');
    }

    final expenses = <Expense>[];
    for (final item in decoded) {
      // One damaged record should not hide all the others, so skip it.
      if (item is! Map<String, dynamic>) continue;
      try {
        expenses.add(Expense.fromJson(item));
      } on FormatException {
        continue;
      }
    }
    return expenses;
  }

  Future<void> writeExpenses(List<Expense> expenses) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(expenses.map((e) => e.toJson()).toList());
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('The device refused to save expenses');
    }
  }
}
