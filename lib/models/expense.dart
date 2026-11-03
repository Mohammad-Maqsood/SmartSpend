import 'expense_category.dart';
import 'payment_method.dart';

/// A single expense recorded by the user.
///
/// Instances are immutable: editing an expense creates a new object with
/// [copyWith] and the provider replaces the old one.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdAt,
    this.paymentMethod = PaymentMethod.cash,
    this.note = '',
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;

  /// The day the money was spent (time part is midnight).
  final DateTime date;

  /// When the record was first saved; used as a tie-breaker when sorting.
  final DateTime createdAt;

  final PaymentMethod paymentMethod;
  final String note;

  bool get hasNote => note.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.name,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'paymentMethod': paymentMethod.name,
    'note': note,
  };

  /// Builds an expense from saved JSON.
  ///
  /// Throws a [FormatException] when a required field is missing or has the
  /// wrong type, so the storage service can skip that record safely.
  factory Expense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final amount = json['amount'];
    final date = DateTime.tryParse('${json['date']}');
    if (id is! String || title is! String || amount is! num || date == null) {
      throw const FormatException('Invalid expense record');
    }
    return Expense(
      id: id,
      title: title,
      amount: amount.toDouble(),
      category: ExpenseCategory.fromName(json['category'] as String?),
      date: date,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? date,
      paymentMethod: PaymentMethod.fromName(json['paymentMethod'] as String?),
      note: json['note'] is String ? json['note'] as String : '',
    );
  }

  Expense copyWith({
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? note,
  }) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
    );
  }
}
