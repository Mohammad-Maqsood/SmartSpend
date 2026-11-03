import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/payment_method.dart';
import '../providers/expense_provider.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../utils/validators.dart';
import '../widgets/category_selector.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/date_form_field.dart';
import '../widgets/payment_method_selector.dart';

/// Form screen for adding a new expense or editing an existing one.
///
/// Every field is validated before saving. Pops with `true` when saved.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  /// The expense to edit, or null to add a new one.
  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  ExpenseCategory? _category;
  late DateTime _date;
  late PaymentMethod _paymentMethod;

  bool _saving = false;
  bool _hasChanges = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense == null ? '' : _amountToText(expense.amount),
    );
    _titleController = TextEditingController(text: expense?.title ?? '');
    _noteController = TextEditingController(text: expense?.note ?? '');
    _category = expense?.category;
    _date = expense?.date ?? DateUtils.dateOnly(DateTime.now());
    _paymentMethod = expense?.paymentMethod ?? PaymentMethod.upi;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 250.0 -> "250", 99.5 -> "99.50"
  static String _amountToText(double amount) =>
      amount == amount.roundToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _save() async {
    if (_saving) return; // ignore repeated taps while saving

    final form = _formKey.currentState!;
    if (!form.validate()) {
      // From now on, re-check each field as soon as the user edits it.
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Please fix the highlighted fields'),
        ));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final provider = context.read<ExpenseProvider>();
    final amount = Formatters.parseAmount(_amountController.text)!;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final bool saved;

    if (_isEditing) {
      saved = await provider.updateExpense(widget.expense!.copyWith(
        title: title,
        amount: amount,
        category: _category,
        date: _date,
        paymentMethod: _paymentMethod,
        note: note,
      ));
    } else {
      final now = DateTime.now();
      saved = await provider.addExpense(Expense(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        category: _category!,
        date: _date,
        createdAt: now,
        paymentMethod: _paymentMethod,
        note: note,
      ));
    }

    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save this expense. Please try again.'),
      ));
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await ConfirmDialog.show(
      context,
      title: 'Discard changes?',
      message: 'The details you entered will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget label(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
          child: Text(text, style: theme.textTheme.titleSmall),
        );

    return PopScope(
      canPop: !_hasChanges || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          onChanged: _markChanged,
          child: ListView(
            padding: Layout.pagePadding(context, bottom: 32),
            children: [
              label('How much did you spend?'),
              TextFormField(
                controller: _amountController,
                autofocus: !_isEditing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                textInputAction: TextInputAction.next,
                style: theme.textTheme.headlineSmall,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: Validators.amount,
              ),
              label('What was it for?'),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: Validators.titleMaxLength,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Lunch with friends',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: Validators.title,
              ),
              label('Category'),
              CategorySelector(
                initialValue: _category,
                validator: Validators.category,
                onChanged: (category) => _category = category,
              ),
              label('Date'),
              DateFormField(
                initialValue: _date,
                validator: (date) => Validators.date(date),
                onChanged: (date) => _date = date,
              ),
              label('Paid with'),
              PaymentMethodSelector(
                value: _paymentMethod,
                onChanged: (method) {
                  setState(() => _paymentMethod = method);
                  _markChanged();
                },
              ),
              label('Note (optional)'),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                maxLength: Validators.noteMaxLength,
                decoration: const InputDecoration(
                  hintText: 'Anything to remember about this expense',
                  alignLabelWithHint: true,
                ),
                validator: Validators.note,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving
                    ? 'Saving…'
                    : _isEditing
                        ? 'Save changes'
                        : 'Save expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
