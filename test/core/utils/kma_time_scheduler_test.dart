import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/core/utils/kma_time_scheduler.dart';

void main() {
  group('resolveVilageFcstBaseTime', () {
    test('14시 15분(45분 미만) → 11시 발표 데이터로 보정 (기획서 예시)', () {
      final result = KmaTimeScheduler.resolveVilageFcstBaseTime(DateTime(2026, 6, 19, 14, 15));
      expect(result.baseDate, '20260619');
      expect(result.baseTime, '1100');
    });

    test('16시 50분(45분 이상) → 그대로 14시 슬롯 사용', () {
      final result = KmaTimeScheduler.resolveVilageFcstBaseTime(DateTime(2026, 6, 19, 16, 50));
      expect(result.baseTime, '1400');
    });

    test('16시 20분(45분 미만이지만 직전 슬롯과는 무관) → 여전히 14시 슬롯', () {
      final result = KmaTimeScheduler.resolveVilageFcstBaseTime(DateTime(2026, 6, 19, 16, 20));
      expect(result.baseTime, '1400');
    });

    test('02시 20분 → 전날 23시 슬롯으로 롤오버', () {
      final result = KmaTimeScheduler.resolveVilageFcstBaseTime(DateTime(2026, 6, 19, 2, 20));
      expect(result.baseDate, '20260618');
      expect(result.baseTime, '2300');
    });

    test('02시 50분 → 02시 슬롯 그대로 사용', () {
      final result = KmaTimeScheduler.resolveVilageFcstBaseTime(DateTime(2026, 6, 19, 2, 50));
      expect(result.baseDate, '20260619');
      expect(result.baseTime, '0200');
    });

    test('23시 50분 → 23시 슬롯 그대로 사용', () {
      final result = KmaTimeScheduler.resolveVilageFcstBaseTime(DateTime(2026, 6, 19, 23, 50));
      expect(result.baseTime, '2300');
    });
  });

  group('resolveUltraSrtNcstBaseTime', () {
    test('분 < 10 → 이전 시간 슬롯 사용', () {
      final result = KmaTimeScheduler.resolveUltraSrtNcstBaseTime(DateTime(2026, 6, 19, 14, 5));
      expect(result.baseTime, '1300');
    });

    test('분 >= 10 → 현재 시간 슬롯 사용', () {
      final result = KmaTimeScheduler.resolveUltraSrtNcstBaseTime(DateTime(2026, 6, 19, 14, 30));
      expect(result.baseTime, '1400');
    });

    test('00시 5분 → 전날 23시 슬롯으로 롤오버', () {
      final result = KmaTimeScheduler.resolveUltraSrtNcstBaseTime(DateTime(2026, 6, 19, 0, 5));
      expect(result.baseDate, '20260618');
      expect(result.baseTime, '2300');
    });
  });

  group('resolveMidTermTmFc', () {
    test('06시 15분(10분 이상) → 당일 06시 발표', () {
      expect(KmaTimeScheduler.resolveMidTermTmFc(DateTime(2026, 6, 19, 6, 15)), '202606190600');
    });

    test('06시 5분(10분 미만) → 전날 18시 발표', () {
      expect(KmaTimeScheduler.resolveMidTermTmFc(DateTime(2026, 6, 19, 6, 5)), '202606181800');
    });

    test('17시 59분 → 당일 06시 발표', () {
      expect(KmaTimeScheduler.resolveMidTermTmFc(DateTime(2026, 6, 19, 17, 59)), '202606190600');
    });

    test('18시 30분 → 당일 18시 발표', () {
      expect(KmaTimeScheduler.resolveMidTermTmFc(DateTime(2026, 6, 19, 18, 30)), '202606191800');
    });

    test('00시 5분 → 전날 18시 발표로 롤오버', () {
      expect(KmaTimeScheduler.resolveMidTermTmFc(DateTime(2026, 6, 19, 0, 5)), '202606181800');
    });
  });
}
