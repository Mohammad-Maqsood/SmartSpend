import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/expense.dart';
import 'package:spendwise/models/expense_category.dart';
import 'package:spendwise/models/payment_method.dart';
import 'package:spendwise/utils/validators.dart';

void main() {
  group('Expense JSON', () {
    test('survives a save and load round trip', () {
      final original = Expense(
        id: '42',
        title: 'Bus pass',
        amount: 499.5,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 11, 3),
        createdAt: DateTime(2026, 11, 3, 9, 30),
        paymentMethod: PaymentMethod.card,
        note: 'Monthly pass',
      );

      final copy = Expense.fromJson(original.toJson());

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.amount, original.amount);
      expect(copy.category, original.category);
      expect(copy.date, original.date);
      expect(copy.createdAt, original.createdAt);
      expect(copy.paymentMethod, original.paymentMethod);
      expect(copy.note, original.note);
    });

    test('unknown category and missing optional fields get defaults', () {
      final expense = Expense.fromJson({
        'id': '1',
        'title': 'Old record',
        'amount': 10,
        'category': 'pets',
        'date': '2026-01-05T00:00:00.000',
      });

      expect(expense.category, ExpenseCategory.other);
      expect(expense.paymentMethod, PaymentMethod.cash);
      expect(expense.note, '');
    });

    test('a broken record throws a FormatException', () {
      expect(() => Expense.fromJson({'id': '1', 'amount': 'ten'}),
          throwsFormatException);
    });
  });

  group('Validators', () {
    test('amount', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('NaN'), isNotNull);
      expect(Validators.amount('99999999'), isNotNull);
      expect(Validators.amount('250'), isNull);
      expect(Validators.amount('99,50'), isNull);
    });

    test('title', () {
      expect(Validators.title('   '), isNotNull);
      expect(Validators.title('a'), isNotNull);
      expect(Validators.title('1234'), isNotNull);
      expect(Validators.title('x' * 61), isNotNull);
      expect(Validators.title('Tea'), isNull);
    });

    test('date cannot be in the future', () {
      final now = DateTime(2026, 11, 3, 12);
      expect(Validators.date(null, now: now), isNotNull);
      expect(Validators.date(DateTime(2026, 11, 4), now: now), isNotNull);
      expect(Validators.date(DateTime(2026, 11, 3), now: now), isNull);
    });

    test('category, note and budget', () {
      expect(Validators.category(null), isNotNull);
      expect(Validators.category(ExpenseCategory.food), isNull);
      expect(Validators.note('n' * 201), isNotNull);
      expect(Validators.note(''), isNull);
      expect(Validators.budget('50'), isNotNull);
      expect(Validators.budget('15000'), isNull);
    });
  });
}
