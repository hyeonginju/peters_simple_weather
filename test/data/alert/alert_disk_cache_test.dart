import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/alert/alert_disk_cache.dart';
import 'package:peters_simple_weather/data/alert/models/weather_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _status = WeatherAlertStatus(
  regionLabel: '대전·세종·충남',
  announcedAt: null,
  latestTitle: '호우주의보 발표',
  currentAlerts: 'o 호우주의보 : 대전(동구, 중구)',
  preliminaryAlerts: 'o 07월 24일 새벽 : 충남',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime(2026, 7, 23, 15, 0);

  test('저장한 현황을 모든 필드 그대로 복원함 (announcedAt null 포함)', () async {
    final cache = AlertDiskCache();
    final fetchedAt = now.subtract(const Duration(minutes: 30));
    await cache.save('133', _status, fetchedAt);

    final loaded = await cache.load('133', now);

    expect(loaded, isNotNull);
    expect(loaded!.fetchedAt, fetchedAt);
    expect(loaded.status.regionLabel, '대전·세종·충남');
    expect(loaded.status.announcedAt, isNull);
    expect(loaded.status.latestTitle, '호우주의보 발표');
    expect(loaded.status.currentAlerts, contains('호우주의보'));
    expect(loaded.status.preliminaryAlerts, contains('충남'));
    expect(loaded.status.hasActiveAlert, isTrue);
  });

  test('announcedAt이 있으면 시각까지 그대로 복원함', () async {
    final cache = AlertDiskCache();
    final announced = DateTime(2026, 7, 23, 5, 30);
    await cache.save(
      '108',
      WeatherAlertStatus(
        regionLabel: '전국',
        announcedAt: announced,
        latestTitle: '',
        currentAlerts: '',
        preliminaryAlerts: '',
      ),
      now,
    );

    final loaded = await cache.load('108', now);

    expect(loaded!.status.announcedAt, announced);
  });

  test('maxAge(12시간)를 넘긴 캐시는 null', () async {
    final cache = AlertDiskCache();
    await cache.save('133', _status, now.subtract(const Duration(hours: 13)));

    expect(await cache.load('133', now), isNull);
  });

  test('저장된 것이 없으면 null', () async {
    expect(await AlertDiskCache().load('133', now), isNull);
  });

  test('형식이 깨진 캐시는 null (옛 버전 캐시 등)', () async {
    SharedPreferences.setMockInitialValues({'alert_cache_133': '{broken'});

    expect(await AlertDiskCache().load('133', now), isNull);
  });

  test('관서별로 따로 저장됨', () async {
    final cache = AlertDiskCache();
    await cache.save('133', _status, now);

    expect(await cache.load('108', now), isNull);
    expect(await cache.load('133', now), isNotNull);
  });
}
