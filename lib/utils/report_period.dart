class ReportPeriodRange {
  const ReportPeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }
}

ReportPeriodRange reportPeriodRange(String label, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final end = DateTime(today.year, today.month, today.day, 23, 59, 59);

  switch (label) {
    case 'Last Week':
      return ReportPeriodRange(end.subtract(const Duration(days: 6)), end);
    case 'This Quarter':
      final quarterStartMonth = ((today.month - 1) ~/ 3) * 3 + 1;
      return ReportPeriodRange(DateTime(today.year, quarterStartMonth), end);
    case 'This Year':
      return ReportPeriodRange(DateTime(today.year), end);
    case 'This Month':
    default:
      return ReportPeriodRange(DateTime(today.year, today.month), end);
  }
}

/// Same-length window immediately before [period].
ReportPeriodRange previousPeriodRange(ReportPeriodRange period) {
  final startDay = DateTime(
    period.start.year,
    period.start.month,
    period.start.day,
  );
  final endDay = DateTime(period.end.year, period.end.month, period.end.day);
  final length = endDay.difference(startDay);
  final prevEnd = startDay.subtract(const Duration(days: 1));
  final prevStart = prevEnd.subtract(length);
  return ReportPeriodRange(
    DateTime(prevStart.year, prevStart.month, prevStart.day),
    DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
  );
}

String formatReportPeriodRange(ReportPeriodRange period) {
  final start = period.start.toIso8601String().split('T').first;
  final end = period.end.toIso8601String().split('T').first;
  return '$start → $end';
}

DateTime? parseReportDate(String value) {
  if (value.contains('T')) return DateTime.tryParse(value);
  return DateTime.tryParse('${value.trim()}T00:00:00');
}
