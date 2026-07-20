import { KMA_ENDPOINTS } from '../kma/endpoints';
import { extractItems, fetchKmaJson, KmaError } from '../kma/client';
import { cleanAlertText, nowKst, parseTmFc, ymd } from './parse';
import {
  PUSH_STN_IDS,
  provinceCode,
  provincesForStn,
  provincesInAlertBody,
  topicForProvinceCode,
} from './stnMapper';
import { sendAlertPush } from '../push/firebase';
import { getLastPushedTmFc, setLastPushedTmFc } from './stateStore';

/**
 * 중복 발송 방지는 "마지막으로 푸시한 tmFc"를 Firestore에 저장해 처리한다(stateStore).
 * tmFc(발표시각)는 특보가 활성인 동안 고정이므로, 같은 값이면 폴링이 몇 번을 더 보든
 * 건너뛴다 — 폴링이 지연·누락돼도 누락 없이 정확히 한 번만 발송된다.
 *
 * 아래 백스톱은 콜드 스타트(상태 유실)나 장시간 장애 뒤 한참 지난 발표까지 거슬러
 * 올라가 푸시하는 것만 막는다. 중복은 상태가 막아주므로 윈도우는 cron 지연을 넉넉히
 * 흡수하도록 크게 잡는다.
 */
const MAX_ALERT_AGE_MINUTES = 180;

export type PollResult = {
  stnId: string;
  pushed: boolean;
  reason: string;
};

/**
 * 9개 관서를 모두 확인하고, 최근 발표된 발효 특보가 있는 관서에만 토픽 푸시를 보낸다.
 * 관서를 병렬로 확인한다 — 순차로 돌리면 관서별 재시도(최대 ~46초)가 누적돼 트리거
 * curl의 --max-time 60초를 넘길 수 있다. 병렬이면 총 시간이 가장 느린 한 관서의
 * 체인으로 묶여 예산 안에 들어온다. 관서별 상태(stateStore)는 서로 독립이라 안전하다.
 */
export async function pollAndPushAlerts(): Promise<PollResult[]> {
  return Promise.all(PUSH_STN_IDS.map((stnId) => checkOne(stnId)));
}

async function checkOne(stnId: string): Promise<PollResult> {
  const now = nowKst();
  const from = ymd(new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000));
  const to = ymd(now);

  let items: Record<string, unknown>[];
  try {
    const json = await fetchKmaJson(KMA_ENDPOINTS.wthrWrnMsg, {
      stnId,
      fromTmFc: from,
      toTmFc: to,
      numOfRows: 1,
    });
    items = extractItems(json);
  } catch (err) {
    // resultCode 03(NO_DATA)은 "최근 5일간 통보문 없음"이라는 정상 응답이지,
    // 조회 실패가 아니다 — 특보가 드문 관서에서 매 폴링마다 흔히 발생한다.
    if (err instanceof KmaError && err.resultCode === '03') {
      return { stnId, pushed: false, reason: '통보문 없음(NO_DATA)' };
    }
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[poller] ${stnId} 조회 실패: ${message}`);
    return { stnId, pushed: false, reason: `조회 실패: ${message}` };
  }

  if (items.length === 0) {
    return { stnId, pushed: false, reason: '통보문 없음' };
  }

  const item = items[0];
  const currentAlerts = cleanAlertText(item.t6 as string | undefined);
  if (!currentAlerts) {
    return { stnId, pushed: false, reason: '발효 중인 특보 없음' };
  }

  const tmFc = item.tmFc as number | undefined;
  const announcedAt = parseTmFc(tmFc);
  if (tmFc == null || !announcedAt) {
    return { stnId, pushed: false, reason: 'tmFc 파싱 실패' };
  }

  // 같은 발표(tmFc)는 한 번만 푸시 — 이미 보낸 발표면 폴링이 다시 봐도 건너뛴다.
  const lastPushed = await getLastPushedTmFc(stnId);
  if (lastPushed === tmFc) {
    return { stnId, pushed: false, reason: '이미 푸시한 발표(동일 tmFc)' };
  }

  // 한참 지난 발표는 푸시하지 않되, 다음 폴링이 또 후보로 보지 않게 기록만 해둔다.
  const ageMinutes = (Date.now() - announcedAt.getTime()) / 60_000;
  if (ageMinutes > MAX_ALERT_AGE_MINUTES) {
    await setLastPushedTmFc(stnId, tmFc);
    return { stnId, pushed: false, reason: `오래된 발표(${Math.round(ageMinutes)}분 전) — 백스톱 초과, 기록만` };
  }

  // 관서(133=대전·세종·충남)는 여러 시/도를 묶어 다루므로, 본문에 실제로 이름이
  // 있는 시/도의 토픽에만 보낸다 — 세종 폭염이 대전 사용자에게 가지 않도록.
  let provinces = provincesInAlertBody(currentAlerts, provincesForStn(stnId));
  let matched = true;
  if (provinces.length === 0) {
    // 본문에서 담당 시/도를 하나도 못 잡았다(예상 못 한 포맷 등). 실특보 누락이 최악이라
    // 예전처럼 담당 전 시/도에 보낸다(fail-open). Render 로그로 파싱 공백을 관찰한다.
    provinces = provincesForStn(stnId);
    matched = false;
    console.warn(
      `[poller] ${stnId} 본문에서 시/도 미검출 — 담당 전역 발송(fail-open). 본문=${currentAlerts.slice(0, 80)}`,
    );
  }

  for (const province of provinces) {
    const code = provinceCode(province);
    if (!code) continue;
    await sendAlertPush(topicForProvinceCode(code), `[${province}] 기상특보 발효`, currentAlerts);
  }
  await setLastPushedTmFc(stnId, tmFc);
  const how = matched ? '본문매칭' : 'fail-open';
  return {
    stnId,
    pushed: true,
    reason: `발표 ${Math.round(ageMinutes)}분 전 — ${provinces.length}개 시/도 발송(${how}): ${provinces.join(',')}`,
  };
}
