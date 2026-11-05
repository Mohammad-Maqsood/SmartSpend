import 'package:flutter/material.dart';

/// The Smart Spend mark: a wallet on a gradient tile, drawn from theme colours.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: scheme.onPrimary,
        size: size * 0.55,
      ),
    );
  }
}
