import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/core/utils/weather_icon_mapper.dart';
import 'package:peters_simple_weather/core/widgets/weather_icon.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

void main() {
  test('강수형태가 없으면(none) SKY를 기준으로 아이콘 타입/라벨을 고름', () {
    expect(weatherIconTypeFor(SkyCondition.clear, PrecipitationType.none), WeatherIconType.sun);
    expect(weatherConditionLabel(SkyCondition.clear, PrecipitationType.none), '맑음');
    expect(weatherIconTypeFor(SkyCondition.cloudy, PrecipitationType.none), WeatherIconType.cloud);
    expect(weatherIconTypeFor(SkyCondition.partlyCloudy, PrecipitationType.none), WeatherIconType.partly);
  });

  test('강수형태가 있으면 SKY와 무관하게 강수형태가 우선함', () {
    expect(weatherIconTypeFor(SkyCondition.clear, PrecipitationType.rain), WeatherIconType.rain);
    expect(weatherIconTypeFor(SkyCondition.clear, PrecipitationType.snow), WeatherIconType.snow);
    expect(weatherConditionLabel(SkyCondition.clear, PrecipitationType.snow), '눈');
  });
}
