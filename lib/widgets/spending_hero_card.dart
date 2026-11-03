import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// The large gradient card at the top of the home screen: money spent this
/// month, the change against last month, and progress towards the budget.
class SpendingHeroCard extends StatelessWidget {
  const SpendingHeroCard({
    super.key,
    required this.month,
    required this.spent,
    required this.changePercent,
    required this.budget,
    required this.onBudgetTap,
  });

  final DateTime month;
  final double spent;

  /// Change against the same days last month, or null if not comparable.
  final double? changePercent;

  /// Monthly budget, or null when the user has not set one.
  final double? budget;
  final VoidCallback onBudgetTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onCard = scheme.onPrimary;
    final faded = onCard.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent in ${Formatters.monthName(month)}',
                  style: theme.textTheme.titleSmall?.copyWith(color: faded),
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined, color: faded),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.currency(spent),
              style: theme.textTheme.displaySmall?.copyWith(
                color: onCard,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ChangePill(changePercent: changePercent, color: onCard),
          const SizedBox(height: 18),
          if (budget != null)
            _BudgetProgress(spent: spent, budget: budget!, color: onCard)
          else
            InkWell(
              onTap: onBudgetTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: onCard, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set a monthly budget',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: onCard),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: onCard),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.changePercent, required this.color});

  final double? changePercent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final change = changePercent;
    final String text;
    final IconData icon;
    if (change == null) {
      text = 'No spending last month to compare with';
      icon = Icons.insights_rounded;
    } else if (change.abs() < 1) {
      text = 'About the same as last month so far';
      icon = Icons.trending_flat_rounded;
    } else {
      final more = change > 0;
      text = '${change.abs().toStringAsFixed(0)}% '
          '${more ? 'more' : 'less'} than this time last month';
      icon = more ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({
    required this.spent,
    required this.budget,
    required this.color,
  });

  final double spent;
  final double budget;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remaining = budget - spent;
    final over = remaining < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (spent / budget).clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (over) ...[
              Icon(Icons.warning_amber_rounded, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                over
                    ? '${Formatters.currencyWhole(-remaining)} over budget'
                    : '${Formatters.currencyWhole(remaining)} left',
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'of ${Formatters.currencyWhole(budget)}',
              style: textTheme.labelMedium
                  ?.copyWith(color: color.withValues(alpha: 0.82)),
            ),
          ],
        ),
      ],
    );
  }
}
