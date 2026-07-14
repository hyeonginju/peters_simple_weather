import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/kma_time_scheduler.dart';

/// 백엔드가 없는 solo 빌드에서 강수 실측(RN1)을 기기 로컬에 자체 누적한다.
/// main의 Firestore `precipToday`/`activeCells` 컬렉션과 같은 역할을
/// shared_preferences로 대신한다 — "지역별 오늘 누적치"와 "이 지역이 언제 처음
/// 조회됐는지"만 기억하면 되므로 백그라운드 폴러 없이 매 fetch에 얹어 갱신한다.
class LocalPrecipStore {
  LocalPrecipStore._();

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _stateKey(String regionId, String dateKey) => 'precip_${regionId}_$dateKey';
  static String _firstActiveKey(String regionId) => 'precip_first_active_$regionId';

  /// 오늘자 누적 강수량과, 이 지역이 오늘 처음 활성화됐는지(isFirstDay) 반환한다.
  /// 최초 호출 시 firstActiveDate를 오늘 날짜로 확정하고(이후 불변), 지난 날짜의
  /// 누적 기록은 정리한다. 매 날씨 fetch마다 호출한다.
  static Future<({double accumulatedRn, bool isFirstDay})> ensureActiveAndGetState(
    String regionId,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(now);

    final firstActiveKey = _firstActiveKey(regionId);
    final storedFirstActive = prefs.getString(firstActiveKey);
    final firstActive = storedFirstActive ?? today;
    if (storedFirstActive == null) {
      await prefs.setString(firstActiveKey, firstActive);
    }

    await _pruneOtherDates(prefs, regionId, today);

    final raw = prefs.getString(_stateKey(regionId, today));
    final accumulatedRn = raw == null ? 0.0 : ((jsonDecode(raw) as Map<String, dynamic>)['accumulatedRn'] as num).toDouble();

    return (accumulatedRn: accumulatedRn, isFirstDay: firstActive == today);
  }

  /// 이번 시간대(slot)의 RN1을 아직 반영하지 않았으면 오늘자 누적치에 더한다.
  /// RN1은 매시 정각에만 갱신되므로 같은 slot이 중복 반영되지 않게 막는다.
  static Future<void> recordRn1(String regionId, DateTime now, double rn1) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(now);
    final base = KmaTimeScheduler.resolveUltraSrtNcstBaseTime(now);
    final slot = '${base.baseDate}${base.baseTime}';

    final key = _stateKey(regionId, today);
    final raw = prefs.getString(key);
    final data = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    if (data['lastSlot'] == slot) return;

    final prevSum = (data['accumulatedRn'] as num?)?.toDouble() ?? 0.0;
    await prefs.setString(key, jsonEncode({'accumulatedRn': prevSum + rn1, 'lastSlot': slot}));
  }

  /// 오늘 날짜가 아닌 이 지역의 누적 기록은 삭제한다 — 하루가 지나면 어차피
  /// 쓸모없고, shared_preferences에 계속 쌓이는 걸 막는다.
  static Future<void> _pruneOtherDates(SharedPreferences prefs, String regionId, String today) async {
    final prefix = 'precip_${regionId}_';
    final todayKey = _stateKey(regionId, today);
    for (final key in prefs.getKeys()) {
      if (key.startsWith(prefix) && key != todayKey) {
        await prefs.remove(key);
      }
    }
  }
}
