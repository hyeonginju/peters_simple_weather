/// Parses KMA's PCP (precipitation amount) field, which arrives as
/// inconsistent Korean string literals instead of a plain number.
///
/// Examples: "강수없음" -> 0.0, "1mm 미만" -> 0.5, "30~50mm" -> 40.0 (avg),
/// "50mm 이상" -> 50.0 (extracted from the literal, not hardcoded).
double parsePrecipitationAmount(String raw) {
  final value = raw.trim();

  if (value == '강수없음' || value == '0' || value.isEmpty) {
    return 0.0;
  }
  if (value.contains('미만')) {
    return 0.5;
  }

  final rangeMatch = RegExp(r'(\d+(?:\.\d+)?)\s*~\s*(\d+(?:\.\d+)?)').firstMatch(value);
  if (rangeMatch != null) {
    final low = double.parse(rangeMatch.group(1)!);
    final high = double.parse(rangeMatch.group(2)!);
    return (low + high) / 2;
  }

  final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
  if (numberMatch != null) {
    return double.parse(numberMatch.group(1)!);
  }

  return 0.0;
}
