import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Turns numbers and dates into text for display, Indian style (₹1,23,456).
class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _currencyWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
  );

  /// ₹1,250.50
  static String currency(double amount) => _currency.format(amount);

  /// ₹1,251
  static String currencyWhole(double amount) => _currencyWhole.format(amount);

  /// ₹80, ₹1.25K, ₹3.4L, ₹1Cr — for small chart labels.
  static String compactCurrency(double amount) =>
      amount < 1000 ? currencyWhole(amount) : _compact.format(amount);

  /// 3 Nov 2026
  static String date(DateTime date) => DateFormat('d MMM yyyy').format(date);

  /// Tuesday, 3 November 2026
  static String fullDate(DateTime date) =>
      DateFormat('EEEE, d MMMM yyyy').format(date);

  /// 3 Nov 2026, 9:45 PM
  static String dateTime(DateTime date) =>
      DateFormat('d MMM yyyy, h:mm a').format(date);

  /// November 2026
  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  /// November
  static String monthName(DateTime date) => DateFormat('MMMM').format(date);

  /// Tue
  static String weekdayShort(DateTime date) => DateFormat('E').format(date);

  /// "Today", "Yesterday", or "Mon, 2 Nov" for older dates.
  static String relativeDay(DateTime date, DateTime now) {
    final day = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(now);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    final pattern = day.year == today.year ? 'EEE, d MMM' : 'EEE, d MMM yyyy';
    return DateFormat(pattern).format(day);
  }

  /// Parses user input such as "250", "99.5" or "99,5" into a number.
  static double? parseAmount(String? text) {
    final cleaned = (text ?? '').trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || !value.isFinite) return null;
    return value;
  }
}
