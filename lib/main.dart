import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'services/expense_storage.dart';
import 'services/settings_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Settings are loaded before the first frame so the app opens in the
  // right theme straight away. Expenses load after, behind a loading state.
  final settings = SettingsProvider(SettingsStorage());
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(ExpenseStorage())..loadExpenses(),
        ),
      ],
      child: const SmartSpendApp(),
    ),
  );
}
