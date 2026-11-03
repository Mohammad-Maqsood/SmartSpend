import 'package:flutter/material.dart';

import 'centered_scroll_view.dart';

/// Screen state 2 of 4: something went wrong, with a button to try again.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CenteredScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
            child: const Icon(Icons.error_outline_rounded, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
