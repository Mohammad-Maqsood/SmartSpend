import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/app.dart';
import 'package:spendwise/models/expense.dart';
import 'package:spendwise/models/expense_category.dart';
import 'package:spendwise/models/payment_method.dart';
import 'package:spendwise/providers/expense_provider.dart';
import 'package:spendwise/providers/settings_provider.dart';
import 'package:spendwise/services/expense_storage.dart';
import 'package:spendwise/services/settings_storage.dart';

import 'helpers/fake_expense_storage.dart';

/// Starts the whole app the same way `main()` does, using mock storage.
Future<void> pumpSpendWise(
  WidgetTester tester, {
  ExpenseStorage? storage,
  List<Expense> saved = const [],
}) async {
  // A typical phone screen: 411 x 914 logical pixels.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (saved.isNotEmpty)
      ExpenseStorage.storageKey:
          jsonEncode(saved.map((e) => e.toJson()).toList()),
  });
  final settings = SettingsProvider(SettingsStorage());
  await settings.load();
  final expenses = ExpenseProvider(storage ?? ExpenseStorage());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: expenses),
      ],
      child: const SpendWiseApp(),
    ),
  );
  await expenses.loadExpenses();
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

Future<void> openAddForm(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  final button = find.text('Save expense');
  // Close the keyboard first, like a user would. Otherwise the focused text
  // field keeps scrolling itself back into view.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  // The button is below the fold, so scroll the form until it is built.
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find
        .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
        .first,
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Scrolls the form back to the top so the first fields are on screen.
Future<void> scrollFormToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Form), const Offset(0, 3000));
  await tester.pumpAndSettle();
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final groceries = Expense(
    id: 'e1',
    title: 'Weekly groceries',
    amount: 1250.5,
    category: ExpenseCategory.food,
    date: today,
    createdAt: today,
    paymentMethod: PaymentMethod.upi,
    note: 'Vegetables, fruit and milk',
  );

  testWidgets('home screen shows the app name and navigation tabs',
      (tester) async {
    await pumpSpendWise(tester);

    expect(find.text('SpendWise'), findsOneWidget);
    for (final tab in ['Home', 'Expenses', 'Insights', 'Settings']) {
      expect(find.text(tab), findsOneWidget);
    }
  });

  testWidgets('expense list shows the empty state when nothing is saved',
      (tester) async {
    await pumpSpendWise(tester);
    await openTab(tester, 'Expenses');

    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Add your first expense'), findsOneWidget);
  });

  testWidgets('shows an error with a retry button, and retry recovers',
      (tester) async {
    final storage = FakeExpenseStorage(initial: [groceries], failedReadsLeft: 1);
    await pumpSpendWise(tester, storage: storage);

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('Weekly groceries'), findsOneWidget);
  });

  testWidgets('form shows a clear message for each invalid field',
      (tester) async {
    await pumpSpendWise(tester);
    await openAddForm(tester);

    await tapSave(tester);
    await scrollFormToTop(tester);

    expect(find.text('Please enter the amount'), findsOneWidget);
    expect(find.text('Please enter what this expense was for'), findsOneWidget);
    expect(find.text('Please choose a category'), findsOneWidget);
    // Nothing was saved, so we are still on the form.
    expect(find.text('Add expense'), findsWidgets);
  });

  testWidgets('form rejects a zero amount and a title without letters',
      (tester) async {
    await pumpSpendWise(tester);
    await openAddForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), '123');
    await tapSave(tester);
    await scrollFormToTop(tester);

    expect(find.text('Amount must be more than ₹0'), findsOneWidget);
    expect(find.text('Title must contain at least one letter'), findsOneWidget);
  });

  testWidgets('amount field ignores letters and a third decimal place',
      (tester) async {
    await pumpSpendWise(tester);
    await openAddForm(tester);

    final amount = find.widgetWithText(TextFormField, 'Amount');
    await tester.enterText(amount, '12abc');
    expect(find.text('12abc'), findsNothing);

    await tester.enterText(amount, '99.99');
    await tester.enterText(amount, '99.999');
    expect(find.text('99.99'), findsOneWidget);
  });

  testWidgets('a valid expense is saved, listed and stored on the device',
      (tester) async {
    await pumpSpendWise(tester);
    await openAddForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '250');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'), 'Lunch with friends');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.pump();
    await tapSave(tester);

    expect(find.text('Expense saved'), findsOneWidget);

    await openTab(tester, 'Expenses');
    expect(find.text('Lunch with friends'), findsOneWidget);
    expect(find.text('₹250.00'), findsWidgets);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(ExpenseStorage.storageKey),
        contains('Lunch with friends'));
  });

  testWidgets('tapping an expense opens its detail screen', (tester) async {
    await pumpSpendWise(tester, saved: [groceries]);
    await openTab(tester, 'Expenses');

    await tester.tap(find.text('Weekly groceries'));
    await tester.pumpAndSettle();

    expect(find.text('Expense details'), findsOneWidget);
    expect(find.text('Vegetables, fruit and milk'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
  });

  testWidgets('a fast double tap opens the detail screen only once',
      (tester) async {
    await pumpSpendWise(tester, saved: [groceries]);
    await openTab(tester, 'Expenses');

    final tile = find.text('Weekly groceries');
    await tester.tap(tile);
    await tester.tap(tile, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Going back once must return to the list, not to a second copy.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Expense details'), findsNothing);
    expect(find.text('Weekly groceries'), findsOneWidget);
  });

  testWidgets('category filter shows a no-results message', (tester) async {
    await pumpSpendWise(tester, saved: [groceries]);
    await openTab(tester, 'Expenses');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Transport'));
    await tester.pumpAndSettle();

    expect(find.text('No matching expenses'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly groceries'), findsOneWidget);
  });

  testWidgets('works in landscape without layout errors', (tester) async {
    await pumpSpendWise(tester, saved: [groceries]);
    tester.view.physicalSize = const Size(2400, 1080);
    await tester.pumpAndSettle();

    for (final tab in ['Home', 'Expenses', 'Insights', 'Settings']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull);
    }
    await openTab(tester, 'Home');
    await openAddForm(tester);
    expect(tester.takeException(), isNull);
    await tapSave(tester);
    expect(tester.takeException(), isNull);
  });
}
