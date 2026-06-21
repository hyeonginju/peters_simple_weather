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

  /// 초단기실황(getUltraSrtNcst): published every hour on the hour, queryable
  /// from ~10min past the hour. (Assumption pending KMA doc confirmation.)
  static ({String baseDate, String baseTime}) resolveUltraSrtNcstBaseTime(DateTime now) {
    final effectiveHour = now.minute < 10 ? now.hour - 1 : now.hour;
    return _resolveFromHours(now, effectiveHour, const [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
    ]);
  }

  /// 중기예보(getMidLandFcst/getMidTa): published twice daily at 06:00/18:00,
  /// queryable from ~10min after. (Assumption pending KMA doc confirmation.)
  /// Returns `tmFc` in KMA's `yyyyMMddHHmm` format.
  static String resolveMidTermTmFc(DateTime now) {
    final effectiveHour = now.minute < 10 ? now.hour - 1 : now.hour;
    final result = _resolveFromHours(now, effectiveHour, const [6, 18]);
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
