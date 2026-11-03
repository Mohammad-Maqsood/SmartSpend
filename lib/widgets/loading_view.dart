import 'package:flutter/material.dart';

import 'centered_scroll_view.dart';

/// Screen state 1 of 4: shown while expenses are being read from the device.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading your expenses…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CenteredScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
