import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/kma/dto/mid_land_fcst_dto.dart';
import 'package:peters_simple_weather/data/kma/dto/mid_ta_dto.dart';
import 'package:peters_simple_weather/data/weather/mappers/mid_term_converter.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

void main() {
  test('day 4~10을 발표일 기준 날짜로 변환하고, day3은 제외함', () {
    const land = MidLandFcstDto(
      regId: '11B10101',
      rnSt4Am: 70,
      rnSt4Pm: 50,
      rnSt8: 20,
      rnSt9: 10,
      rnSt10: 0,
    );
    const ta = MidTaDto(
      regId: '11B10101',
      taMin4: 18,
      taMax4: 27,
      taMin8: 15,
      taMax8: 24,
      taMin9: 14,
      taMax9: 23,
      taMin10: 13,
      taMax10: 22,
    );

    final result = convertMidTermForecast(
      land: land,
      ta: ta,
      announcementDate: DateTime(2026, 6, 19),
    );

    // day4, day8, day9, day10만 ta 값이 채워져 있으므로 4개만 산출됨.
    expect(result, hasLength(4));
    expect(result[0].date, DateTime(2026, 6, 23)); // day4
    expect(result[0].amPopPercent, 70);
    expect(result[0].pmPopPercent, 50);
    expect(result[0].minTemp, 18);
    expect(result[0].maxTemp, 27);
  });

  test('day 8~10은 AM/PM 구분 없는 단일 강수확률을 양쪽에 사용함', () {
    const land = MidLandFcstDto(regId: '11B10101', rnSt8: 30);
    const ta = MidTaDto(regId: '11B10101', taMin8: 10, taMax8: 20);

    final result = convertMidTermForecast(
      land: land,
      ta: ta,
      announcementDate: DateTime(2026, 6, 19),
    );

    expect(result.single.amPopPercent, 30);
    expect(result.single.pmPopPercent, 30);
  });

  test('wf 텍스트("비", "구름많음" 등)를 SkyCondition/PrecipitationType으로 추론함', () {
    const land = MidLandFcstDto(regId: '11B10101', wf4Am: '비', wf8: '구름많음');
    const ta = MidTaDto(regId: '11B10101', taMin4: 18, taMax4: 27, taMin8: 15, taMax8: 24);

    final result = convertMidTermForecast(land: land, ta: ta, announcementDate: DateTime(2026, 6, 19));

    expect(result[0].precipitationType, PrecipitationType.rain);
    expect(result[1].sky, SkyCondition.partlyCloudy);
    expect(result[1].precipitationType, PrecipitationType.none);
  });

  test('해당 일자의 기온 데이터가 없으면 그 날은 건너뜀', () {
    const land = MidLandFcstDto(regId: '11B10101', rnSt4Am: 10, rnSt4Pm: 10);
    const ta = MidTaDto(regId: '11B10101'); // 기온 데이터 전부 없음

    final result = convertMidTermForecast(
      land: land,
      ta: ta,
      announcementDate: DateTime(2026, 6, 19),
    );

    expect(result, isEmpty);
  });
}
