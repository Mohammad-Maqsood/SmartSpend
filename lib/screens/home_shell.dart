import 'package:flutter/material.dart';

import '../utils/safe_navigation.dart';
import 'dashboard_screen.dart';
import 'expense_form_screen.dart';
import 'expense_list_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';

/// The app's main frame: a bottom navigation bar with four tabs and an
/// "Add expense" button.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _settingsTab = 3;
  int _tab = 0;

  void _selectTab(int index) => setState(() => _tab = index);

  Future<void> _addExpense() async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await context.pushScreen<bool>(const ExpenseFormScreen());
    if (saved == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Expense saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // On Android, "back" from another tab returns to Home before leaving.
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(0);
      },
      child: Scaffold(
        // IndexedStack keeps each tab's scroll position and filters.
        body: IndexedStack(
          index: _tab,
          children: [
            DashboardScreen(
              onSeeAll: () => _selectTab(1),
              onAddExpense: _addExpense,
            ),
            ExpenseListScreen(onAddExpense: _addExpense),
            const SummaryScreen(),
            const SettingsScreen(),
          ],
        ),
        floatingActionButton: _tab == _settingsTab
            ? null
            : FloatingActionButton.extended(
                onPressed: _addExpense,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add expense'),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
