import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/alert/alert_repository.dart';
import '../../../data/alert/models/weather_alert.dart';

part 'alert_providers.g.dart';

@Riverpod(keepAlive: true)
AlertRepository alertRepository(Ref ref) => AlertRepository();

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
@riverpod
Future<WeatherAlertStatus> alertStatus(Ref ref, String stnId) async {
  return ref.watch(alertRepositoryProvider).fetchByStnId(stnId);
}
