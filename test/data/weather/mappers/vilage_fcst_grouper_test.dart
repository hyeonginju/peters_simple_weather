import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/mappers/vilage_fcst_grouper.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

void main() {
  test('같은 시간대의 여러 category가 하나의 draft로 그룹핑됨', () {
    final items = [
      const KmaForecastItem(category: 'TMP', fcstDate: '20260619', fcstTime: '1400', fcstValue: '24'),
      const KmaForecastItem(category: 'SKY', fcstDate: '20260619', fcstTime: '1400', fcstValue: '1'),
      const KmaForecastItem(category: 'PTY', fcstDate: '20260619', fcstTime: '1400', fcstValue: '0'),
      const KmaForecastItem(category: 'POP', fcstDate: '20260619', fcstTime: '1400', fcstValue: '10'),
      const KmaForecastItem(category: 'PCP', fcstDate: '20260619', fcstTime: '1400', fcstValue: '강수없음'),
    ];

    final drafts = groupVilageFcstItems(items);

    expect(drafts, hasLength(1));
    expect(drafts.first.temperature, 24.0);
    expect(drafts.first.sky, SkyCondition.clear);
    expect(drafts.first.precipitationType, PrecipitationType.none);
    expect(drafts.first.precipitationProbability, 10);
    expect(drafts.first.precipitationAmount, 0.0);
  });

  test('알 수 없는 category는 무시됨', () {
    final items = [
      const KmaForecastItem(category: 'TMP', fcstDate: '20260619', fcstTime: '1400', fcstValue: '24'),
      const KmaForecastItem(category: 'REH', fcstDate: '20260619', fcstTime: '1400', fcstValue: '55'),
    ];

    final drafts = groupVilageFcstItems(items);

    expect(drafts, hasLength(1));
    expect(drafts.first.temperature, 24.0);
  });

  test('서로 다른 시간대는 각각 별도 draft로 분리되고 시간순 정렬됨', () {
    final items = [
      const KmaForecastItem(category: 'TMP', fcstDate: '20260619', fcstTime: '1600', fcstValue: '23'),
      const KmaForecastItem(category: 'TMP', fcstDate: '20260619', fcstTime: '1400', fcstValue: '24'),
    ];

    final drafts = groupVilageFcstItems(items);

    expect(drafts, hasLength(2));
    expect(drafts[0].time.hour, 14);
    expect(drafts[1].time.hour, 16);
  });
}
