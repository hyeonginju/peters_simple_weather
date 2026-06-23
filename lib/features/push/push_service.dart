import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/alert/kma_stn_mapper.dart';
import '../../data/region/models/region.dart';

const _permissionRequestedKey = 'push_permission_requested';
const _subscribedTopicKey = 'push_subscribed_topic';

/// 대표 지역(저장 지역 중 맨 위 1개)의 기상특보 FCM 토픽 구독을 관리한다.
/// 백엔드는 토큰/구독 상태를 전혀 저장하지 않으므로(무상태), 구독 상태는
/// 기기에 SharedPreferences로만 추적한다.
class PushService {
  PushService._();

  static Future<bool> hasRequestedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionRequestedKey) ?? false;
  }

  /// 알림 권한을 요청하고(최초 1회만 호출할 것) 대표 지역 토픽을 구독한다.
  static Future<void> requestPermissionAndSubscribe(Region? primaryRegion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionRequestedKey, true);
    await FirebaseMessaging.instance.requestPermission();
    await syncTopicForRegion(primaryRegion);
  }

  /// 대표 지역이 바뀔 때마다(추가/삭제/순서변경, 앱 시작 시 자기복구 포함) 호출 —
  /// 이전 토픽을 해제하고 새 토픽을 구독한다. 권한을 아직 요청하지 않았다면
  /// (특보 화면에 한 번도 들어가지 않음) 아무 것도 하지 않는다.
  static Future<void> syncTopicForRegion(Region? primaryRegion) async {
    if (!await hasRequestedPermission()) return;

    final prefs = await SharedPreferences.getInstance();
    final previousTopic = prefs.getString(_subscribedTopicKey);
    final nextTopic = primaryRegion == null
        ? null
        : KmaStnMapper.topicForStnId(KmaStnMapper.stnIdForProvince(primaryRegion.province));

    if (previousTopic == nextTopic) return;

    if (previousTopic != null) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(previousTopic);
    }
    if (nextTopic != null) {
      await FirebaseMessaging.instance.subscribeToTopic(nextTopic);
      await prefs.setString(_subscribedTopicKey, nextTopic);
    } else {
      await prefs.remove(_subscribedTopicKey);
    }
  }
}
