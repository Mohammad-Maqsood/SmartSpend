import 'package:flutter/material.dart';

/// Centres [child] on the page but lets it scroll when space is short,
/// for example when the phone is turned sideways. This prevents overflow
/// errors on the loading, error and empty screens.
class CenteredScrollView extends StatelessWidget {
  const CenteredScrollView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
