/// A time window used to filter expenses on the list and insights screens.
enum SummaryPeriod {
  thisMonth('This month'),
  lastMonth('Last month'),
  thisYear('This year'),
  allTime('All time');

  const SummaryPeriod(this.label);

  final String label;

  /// Whether [date] falls inside this period, measured from [now].
  bool includes(DateTime date, DateTime now) {
    switch (this) {
      case SummaryPeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case SummaryPeriod.lastMonth:
        // DateTime normalises month 0 to December of the previous year.
        final lastMonth = DateTime(now.year, now.month - 1);
        return date.year == lastMonth.year && date.month == lastMonth.month;
      case SummaryPeriod.thisYear:
        return date.year == now.year;
      case SummaryPeriod.allTime:
        return true;
    }
  }
}
