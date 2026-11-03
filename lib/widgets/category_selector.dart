import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_palette.dart';

/// A form field that shows every category as a tappable chip.
///
/// Because it extends [FormField], it takes part in `Form.validate()` and
/// shows its error message underneath, just like a text field.
class CategorySelector extends FormField<ExpenseCategory> {
  CategorySelector({
    super.key,
    super.initialValue,
    super.validator,
    super.autovalidateMode,
    ValueChanged<ExpenseCategory>? onChanged,
  }) : super(
         builder: (field) {
           final context = field.context;
           final theme = Theme.of(context);
           final palette = AppPalette.of(context);
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: ExpenseCategory.values.map((category) {
                   final selected = field.value == category;
                   final color = palette.categoryColor(category);
                   return ChoiceChip(
                     avatar: Icon(category.icon, size: 18, color: color),
                     label: Text(category.label),
                     selected: selected,
                     selectedColor: palette.categoryBackground(category),
                     side: BorderSide(
                       color: selected
                           ? color
                           : field.hasError
                           ? theme.colorScheme.error
                           : theme.colorScheme.outlineVariant,
                       width: selected ? 1.5 : 1,
                     ),
                     onSelected: (_) {
                       field.didChange(category);
                       onChanged?.call(category);
                     },
                   );
                 }).toList(),
               ),
               if (field.hasError)
                 Padding(
                   padding: const EdgeInsets.only(left: 12, top: 8),
                   child: Text(
                     field.errorText!,
                     style: theme.textTheme.bodySmall?.copyWith(
                       color: theme.colorScheme.error,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
