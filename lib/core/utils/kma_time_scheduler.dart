/// Resolves the correct KMA `base_date`/`base_time` query params, working
/// around the publish lag of each endpoint. Calling with the literal current
/// time can return NO_DATA if the server hasn't finished publishing yet.
class KmaTimeScheduler {
  KmaTimeScheduler._();

  /// 단기예보(getVilageFcst): published every 3h at 02/05/08/11/14/17/20/23,
  /// with ~40min lag before the data is queryable.
  static const vilageFcstBaseHours = [2, 5, 8, 11, 14, 17, 20, 23];

  static ({String baseDate, String baseTime}) resolveVilageFcstBaseTime(DateTime now) {
    final effectiveHour = now.minute < 45 ? now.hour - 1 : now.hour;
    return _resolveFromHours(now, effectiveHour, vilageFcstBaseHours);
  }

  /// 초단기실황(getUltraSrtNcst): base_time은 매시 정각(HH00)이고, 그 시각
  /// 실황은 약 40분 뒤부터 조회 가능하다(KMA 제공시각 기준). 발표 전 정각을
  /// 요청하면 resultCode 03(NO_DATA)로 던져져 습도(REH)가 통째로 누락되므로,
  /// 안전마진을 둬 45분 전까지는 직전 정각을 사용한다(단기예보 리졸버와 동일 컨벤션).
  static ({String baseDate, String baseTime}) resolveUltraSrtNcstBaseTime(DateTime now) {
    final effectiveHour = now.minute < 45 ? now.hour - 1 : now.hour;
    return _resolveFromHours(now, effectiveHour, const [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
    ]);
  }

  /// 중기예보(getMidLandFcst/getMidTa): published twice daily at 06:00/18:00,
  /// queryable from ~10min after. (Assumption pending KMA doc confirmation.)
  /// Returns `tmFc` in KMA's `yyyyMMddHHmm` format.
  ///
  /// 단, 18시 발표는 '4일 후'(rnSt4·taMin4 등) 필드를 아예 제공하지 않는다
  /// (실제 API 응답·날씨누리 공식 표 모두 D+5부터 시작함을 확인). 당일 저녁에
  /// 18시 발표를 쓰면 단기예보(D+0~3)와 중기예보(D+5~) 사이 D+4 하루가 비어
  /// 주간 예보에 날짜 구멍이 생기므로, 당일 06시 발표를 자정까지 유지한다.
  /// 자정~06:10 구간의 전날 18시 발표는 day5가 곧 D+4라 그대로 이어진다.
  static String resolveMidTermTmFc(DateTime now) {
    final effectiveHour = now.minute < 10 ? now.hour - 1 : now.hour;
    final result = _resolveFromHours(now, effectiveHour, const [6, 18]);
    final today = _formatDate(DateTime(now.year, now.month, now.day));
    if (result.baseTime == '1800' && result.baseDate == today) {
      return '${result.baseDate}0600';
    }
    return '${result.baseDate}${result.baseTime}';
  }

  static ({String baseDate, String baseTime}) _resolveFromHours(
    DateTime now,
    int effectiveHour,
    List<int> validHours,
  ) {
    var date = DateTime(now.year, now.month, now.day);
    var hour = effectiveHour;

    if (hour < 0) {
      date = date.subtract(const Duration(days: 1));
      hour += 24;
    }

    int? chosen;
    for (final h in validHours.reversed) {
      if (hour >= h) {
        chosen = h;
        break;
      }
    }

    if (chosen == null) {
      date = date.subtract(const Duration(days: 1));
      chosen = validHours.last;
    }

    return (baseDate: _formatDate(date), baseTime: _formatTime(chosen));
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String _formatTime(int hour) => '${hour.toString().padLeft(2, '0')}00';
}
