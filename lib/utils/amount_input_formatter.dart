import 'package:flutter/services.dart';

/// Lets the user type only a sensible money amount: up to 8 digits, then an
/// optional decimal point (or comma) and at most 2 decimal places.
///
/// Any keystroke that would break this pattern is ignored, so values such as
/// "1.2.3", "abc" or "12.345" can never be typed or pasted.
class AmountInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d{0,8}([.,]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
