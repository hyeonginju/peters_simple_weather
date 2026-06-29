import { KMA_ENDPOINTS } from '../kma/endpoints';
import { extractItems, fetchKmaJson, KmaError } from '../kma/client';
import { cleanAlertText, nowKst, parseTmFc, ymd } from './parse';
import { labelForStnId, PUSH_STN_IDS, topicForStnId } from './stnMapper';
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

/** 9개 관서를 모두 확인하고, 최근 발표된 발효 특보가 있는 관서에만 토픽 푸시를 보낸다. */
export async function pollAndPushAlerts(): Promise<PollResult[]> {
  const results: PollResult[] = [];
  for (const stnId of PUSH_STN_IDS) {
    results.push(await checkOne(stnId));
  }
  return results;
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

  const label = labelForStnId(stnId);
  await sendAlertPush(topicForStnId(stnId), `[${label}] 기상특보 발효`, currentAlerts);
  await setLastPushedTmFc(stnId, tmFc);
  return { stnId, pushed: true, reason: `발표 ${Math.round(ageMinutes)}분 전 — 푸시 발송` };
}
