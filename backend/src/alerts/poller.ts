import { KMA_ENDPOINTS } from '../kma/endpoints';
import { extractItems, fetchKmaJson, KmaError } from '../kma/client';
import { cleanAlertText, nowKst, parseTmFc, ymd } from './parse';
import { labelForStnId, PUSH_STN_IDS, topicForStnId } from './stnMapper';
import { sendAlertPush } from '../push/firebase';

/**
 * 폴링 주기(GitHub Actions cron, 10분)보다 넉넉한 여유를 둔 "최근 발표" 판정 기준.
 * tmFc(발표시각)는 특보가 활성인 동안 바뀌지 않으므로, 매 폴링마다 같은 tmFc를
 * 다시 보게 된다 — 이 윈도우를 벗어나면 "이미 지난 주기에 푸시했다"고 보고 건너뛴다.
 * 즉 상태 저장 없이 자연스러운 중복 발송 방지가 된다.
 */
const ALERT_FRESHNESS_MINUTES = 15;

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

  const announcedAt = parseTmFc(item.tmFc as number | undefined);
  if (!announcedAt) {
    return { stnId, pushed: false, reason: 'tmFc 파싱 실패' };
  }

  const ageMinutes = (Date.now() - announcedAt.getTime()) / 60_000;
  if (ageMinutes > ALERT_FRESHNESS_MINUTES) {
    return { stnId, pushed: false, reason: `오래된 발표(${Math.round(ageMinutes)}분 전) — 이미 푸시했을 것으로 간주` };
  }

  const label = labelForStnId(stnId);
  await sendAlertPush(topicForStnId(stnId), `[${label}] 기상특보 발효`, currentAlerts);
  return { stnId, pushed: true, reason: `발표 ${Math.round(ageMinutes)}분 전 — 푸시 발송` };
}
