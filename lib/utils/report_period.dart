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

DateTime? parseReportDate(String value) {
  if (value.contains('T')) return DateTime.tryParse(value);
  return DateTime.tryParse('${value.trim()}T00:00:00');
}
