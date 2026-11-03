import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

/// A small validated form in a dialog for setting the monthly budget.
class BudgetDialog extends StatefulWidget {
  const BudgetDialog({super.key, this.currentBudget});

  final double? currentBudget;

  /// Returned when the user taps "Remove budget".
  static const double removeBudget = -1;

  /// Opens the dialog, saves the result in [SettingsProvider] and confirms
  /// with a snackbar. Used by both the home and settings screens.
  static Future<void> edit(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<double>(
      context: context,
      builder: (_) => BudgetDialog(currentBudget: settings.monthlyBudget),
    );
    if (result == null) return;

    final removing = result == removeBudget;
    final saved = await settings.setMonthlyBudget(removing ? null : result);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(!saved
            ? 'Could not save your budget. Please try again.'
            : removing
                ? 'Monthly budget removed'
                : 'Monthly budget set to ${Formatters.currencyWhole(result)}'),
      ));
  }

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = widget.currentBudget;
    _controller = TextEditingController(
      text: current == null ? '' : current.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, Formatters.parseAmount(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How much do you want to spend at most each month?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Budget',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
                hintText: 'e.g. 15000',
              ),
              validator: Validators.budget,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentBudget != null)
          TextButton(
            onPressed: () => Navigator.pop(context, BudgetDialog.removeBudget),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
