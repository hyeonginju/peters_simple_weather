import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/local_precip_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('처음 조회되는 지역은 isFirstDay=true, 누적치 0으로 시작함', () async {
    final state = await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', DateTime(2026, 6, 19, 9, 0));

    expect(state.isFirstDay, isTrue);
    expect(state.accumulatedRn, 0.0);
  });

  test('RN1을 기록하면 누적치에 반영됨', () async {
    final now = DateTime(2026, 6, 19, 14, 30);
    await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', now);
    await LocalPrecipStore.recordRn1('seoul-yeongdeungpo', now, 2.5);

    final state = await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', now);
    expect(state.accumulatedRn, 2.5);
  });

  test('같은 시간대(slot)를 두 번 기록해도 중복 누적되지 않음', () async {
    final now = DateTime(2026, 6, 19, 14, 30);
    await LocalPrecipStore.recordRn1('seoul-yeongdeungpo', now, 2.5);
    await LocalPrecipStore.recordRn1('seoul-yeongdeungpo', now.add(const Duration(minutes: 5)), 2.5);

    final state = await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', now);
    expect(state.accumulatedRn, 2.5);
  });

  test('다음 시간대(slot)에는 새로 누적됨', () async {
    final t1 = DateTime(2026, 6, 19, 14, 30);
    final t2 = DateTime(2026, 6, 19, 15, 30);
    await LocalPrecipStore.recordRn1('seoul-yeongdeungpo', t1, 2.5);
    await LocalPrecipStore.recordRn1('seoul-yeongdeungpo', t2, 1.0);

    final state = await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', t2);
    expect(state.accumulatedRn, 3.5);
  });

  test('첫 조회 다음날부터는 isFirstDay=false로 바뀜', () async {
    await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', DateTime(2026, 6, 19, 9, 0));
    final state = await LocalPrecipStore.ensureActiveAndGetState('seoul-yeongdeungpo', DateTime(2026, 6, 20, 9, 0));

    expect(state.isFirstDay, isFalse);
    expect(state.accumulatedRn, 0.0); // 새 날짜라 누적치는 0부터 다시 시작
  });

  test('다른 지역끼리는 누적치를 공유하지 않음', () async {
    final now = DateTime(2026, 6, 19, 14, 30);
    await LocalPrecipStore.recordRn1('seoul-yeongdeungpo', now, 2.5);

    final other = await LocalPrecipStore.ensureActiveAndGetState('busan-haeundae', now);
    expect(other.accumulatedRn, 0.0);
    expect(other.isFirstDay, isTrue);
  });
}
