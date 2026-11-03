import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import 'formatters.dart';

/// Validation rules for the expense form and the budget dialog.
///
/// Each method returns an error message to show under the field,
/// or null when the value is valid.
class Validators {
  Validators._();

  static const titleMaxLength = 60;
  static const noteMaxLength = 200;
  static const maxAmount = 10000000.0; // ₹1 crore

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter what this expense was for';
    if (text.length < 2) return 'Title must be at least 2 characters';
    if (text.length > titleMaxLength) {
      return 'Title must be $titleMaxLength characters or fewer';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) {
      return 'Title must contain at least one letter';
    }
    return null;
  }

  static String? amount(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Please enter the amount';
    final amount = Formatters.parseAmount(value);
    if (amount == null) return 'Enter a valid amount, for example 250 or 99.50';
    if (amount <= 0) return 'Amount must be more than ₹0';
    if (amount > maxAmount) {
      return 'Amount cannot be more than ${Formatters.currencyWhole(maxAmount)}';
    }
    return null;
  }

  static String? category(ExpenseCategory? value) {
    return value == null ? 'Please choose a category' : null;
  }

  static String? date(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Please choose a date';
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    if (DateUtils.dateOnly(value).isAfter(today)) {
      return 'Date cannot be in the future';
    }
    if (value.year < 2000) return 'Date must be in the year 2000 or later';
    return null;
  }

  static String? note(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > noteMaxLength) {
      return 'Note must be $noteMaxLength characters or fewer';
    }
    return null;
  }

  static String? budget(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Please enter a budget amount';
    final amount = Formatters.parseAmount(value);
    if (amount == null) return 'Enter a valid amount, for example 15000';
    if (amount < 100) return 'Budget must be at least ₹100';
    if (amount > maxAmount) {
      return 'Budget cannot be more than ${Formatters.currencyWhole(maxAmount)}';
    }
    return null;
  }
}
