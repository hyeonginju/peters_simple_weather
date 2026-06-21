import '../../data/weather/models/kma_forecast_item.dart';
import '../widgets/weather_icon.dart';

/// Picks the shape-composition [WeatherIconType] for a given sky/precipitation
/// combination. Precipitation always wins over the sky condition.
WeatherIconType weatherIconTypeFor(SkyCondition sky, PrecipitationType precipitationType) {
  switch (precipitationType) {
    case PrecipitationType.rain:
    case PrecipitationType.shower:
      return WeatherIconType.rain;
    case PrecipitationType.rainAndSnow:
    case PrecipitationType.snow:
      return WeatherIconType.snow;
    case PrecipitationType.none:
      switch (sky) {
        case SkyCondition.clear:
          return WeatherIconType.sun;
        case SkyCondition.partlyCloudy:
          return WeatherIconType.partly;
        case SkyCondition.cloudy:
          return WeatherIconType.cloud;
      }
  }
}

String weatherConditionLabel(SkyCondition sky, PrecipitationType precipitationType) {
  switch (precipitationType) {
    case PrecipitationType.rain:
      return '비';
    case PrecipitationType.rainAndSnow:
      return '비/눈';
    case PrecipitationType.snow:
      return '눈';
    case PrecipitationType.shower:
      return '소나기';
    case PrecipitationType.none:
      switch (sky) {
        case SkyCondition.clear:
          return '맑음';
        case SkyCondition.partlyCloudy:
          return '구름많음';
        case SkyCondition.cloudy:
          return '흐림';
      }
  }
}
