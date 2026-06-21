import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/core/utils/date_formatter.dart';

void main() {
  group('formatWeeklyDayLabel', () {
    test('오늘 날짜면 "오늘"을 반환함', () {
      final today = DateTime(2026, 6, 19);
      expect(formatWeeklyDayLabel(today, today: today), '오늘');
    });

    test('다른 날짜면 "요일 M월D일" 형식을 반환함 (2026-06-20은 토요일)', () {
      final today = DateTime(2026, 6, 19);
      expect(formatWeeklyDayLabel(DateTime(2026, 6, 20), today: today), '토 6월20일');
    });
  });

  group('formatHourLabel', () {
    test('"H시" 형식을 반환함', () {
      expect(formatHourLabel(DateTime(2026, 6, 19, 16)), '16시');
    });
  });
}
