class PaymentDetailLine {
  const PaymentDetailLine(this.text, {this.amount});

  final String text;
  final double? amount;
}

/// Splits multi-line payment notes and extracts amounts when present.
List<PaymentDetailLine> parsePaymentDetails(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];

  final amountPattern = RegExp(r'[\$]?\s*([\d,]+(?:\.\d+)?)');

  return raw
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) {
        final match = amountPattern.firstMatch(line);
        final amount = match == null
            ? null
            : double.tryParse(match.group(1)!.replaceAll(',', ''));
        return PaymentDetailLine(line, amount: amount);
      })
      .toList();
}

String summarizePaymentDetails(String? raw) {
  final lines = parsePaymentDetails(raw);
  if (lines.isEmpty) return '';
  if (lines.length == 1) return lines.first.text;
  return lines.map((line) => line.text).join(' · ');
}
