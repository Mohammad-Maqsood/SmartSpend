import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/load_state.dart';
import '../models/summary_period.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../widgets/app_logo.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/section_header.dart';

/// Preferences (theme, monthly budget), data management and app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const appVersion = '1.0.0';

  Future<void> _confirmClearAll(BuildContext context, int count) async {
    final provider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete all expenses?',
      message:
          'This permanently removes all $count '
          '${count == 1 ? 'expense' : 'expenses'} from this phone. '
          'This cannot be undone.',
      confirmLabel: 'Delete all',
      destructive: true,
    );
    if (!confirmed) return;
    final cleared = await provider.clearAll();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            cleared
                ? 'All expenses deleted'
                : 'Could not delete expenses. Please try again.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = expenses.expenses.length;
    final canClear = expenses.loadState == LoadState.loaded && count > 0;
    final budget = settings.monthlyBudget;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: Layout.pagePadding(context, top: 0, bottom: 32),
        children: [
          const SectionHeader(title: 'Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) =>
                          settings.setThemeMode(selection.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Budget'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
              leading: CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: const Icon(Icons.savings_outlined),
              ),
              title: const Text('Monthly budget'),
              subtitle: Text(
                budget == null
                    ? 'Not set. Tap to add one.'
                    : '${Formatters.currencyWhole(budget)} per month',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => BudgetDialog.edit(context),
            ),
          ),
          const SectionHeader(title: 'Your data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    child: const Icon(Icons.phone_android_rounded),
                  ),
                  title: const Text('Saved on this phone'),
                  subtitle: Text(
                    '$count ${count == 1 ? 'expense' : 'expenses'} · '
                    '${Formatters.currency(expenses.totalFor(SummaryPeriod.allTime))} in total',
                  ),
                ),
                const Divider(indent: 72),
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                  enabled: canClear,
                  leading: CircleAvatar(
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    child: const Icon(Icons.delete_forever_rounded),
                  ),
                  title: Text(
                    'Delete all expenses',
                    style: TextStyle(color: canClear ? scheme.error : null),
                  ),
                  subtitle: const Text('Start again with an empty list'),
                  onTap: () => _confirmClearAll(context, count),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SpendWise', style: theme.textTheme.titleMedium),
                        Text(
                          'Version $appVersion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A simple expense tracker. Your data is saved only '
                          'on this phone. No account or internet connection '
                          'is needed.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
