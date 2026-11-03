import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// A form field that opens the date picker when tapped.
///
/// The picker only allows dates from 1 Jan 2000 up to today, and the
/// validator double-checks the value before saving.
class DateFormField extends FormField<DateTime> {
  DateFormField({
    super.key,
    super.initialValue,
    super.validator,
    super.autovalidateMode,
    ValueChanged<DateTime>? onChanged,
  }) : super(
         builder: (field) {
           final context = field.context;
           final value = field.value;

           Future<void> pickDate() async {
             final first = DateTime(2000);
             final today = DateUtils.dateOnly(DateTime.now());
             // The picker crashes if the initial date is outside its range,
             // so clamp it (e.g. if the phone's clock was changed).
             var initial = value ?? today;
             if (initial.isAfter(today)) initial = today;
             if (initial.isBefore(first)) initial = first;

             final picked = await showDatePicker(
               context: context,
               initialDate: initial,
               firstDate: first,
               lastDate: today,
               helpText: 'When did you spend this?',
             );
             if (picked != null) {
               field.didChange(picked);
               onChanged?.call(picked);
             }
           }

           return InkWell(
             onTap: pickDate,
             borderRadius: BorderRadius.circular(16),
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: 'Date',
                 prefixIcon: const Icon(Icons.calendar_today_rounded),
                 suffixIcon: const Icon(Icons.expand_more_rounded),
                 errorText: field.errorText,
               ),
               child: Text(
                 value == null ? 'Choose a date' : Formatters.fullDate(value),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           );
         },
       );
}
