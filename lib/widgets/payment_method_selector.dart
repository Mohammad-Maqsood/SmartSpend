import 'package:flutter/material.dart';

import '../models/payment_method.dart';

/// Chips for choosing how an expense was paid. One is always selected.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((method) {
        final selected = method == value;
        return ChoiceChip(
          avatar: Icon(
            method.icon,
            size: 18,
            color: selected ? scheme.onPrimaryContainer : scheme.primary,
          ),
          label: Text(method.label),
          selected: selected,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          onSelected: (_) => onChanged(method),
        );
      }).toList(),
    );
  }
}
