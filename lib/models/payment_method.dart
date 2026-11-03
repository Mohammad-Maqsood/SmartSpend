import 'package:flutter/material.dart';

/// How an expense was paid for.
enum PaymentMethod {
  cash('Cash', Icons.payments_rounded),
  upi('UPI', Icons.qr_code_2_rounded),
  card('Card', Icons.credit_card_rounded),
  netBanking('Net banking', Icons.account_balance_rounded);

  const PaymentMethod(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Converts a stored name back into a payment method, defaulting to [cash].
  static PaymentMethod fromName(String? name) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == name,
      orElse: () => PaymentMethod.cash,
    );
  }
}
