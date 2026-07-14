import { KMA_ENDPOINTS } from '../kma/endpoints';
import { extractItems, fetchKmaJson, KmaError } from '../kma/client';
import { nowKst, ymd } from '../alerts/parse';
import { addObservedRn, getActiveCells } from './precipStore';

/**
 * 셀 사이 호출 간격. 셀을 한꺼번에 쏘지 않고 이 간격만큼 띄워서 호출한다.
 */
const POLL_DELAY_MS = 400;

/**
 * 이 시간 내에 /precip-today로 조회된 적 있는 셀만 폴링 대상으로 삼는다 — 위젯
 * 30분 자동 새로고침이나 하루 걸러 앱을 여는 사용 패턴에도 계속 활성 유지되고,
 * 실제로 안 쓰는 지역은 이 시간이 지나면 자연히 폴링에서 빠진다(별도 삭제 로직 불필요).
 */
const ACTIVE_CELL_MAX_AGE_MS = 48 * 60 * 60 * 1000;

/**
 * 초단기실황(getUltraSrtNcst)은 매시 정각 발표, 관측 후 약 10분 뒤부터 조회 가능.
 * lib/core/utils/kma_time_scheduler.dart의 resolveUltraSrtNcstBaseTime과 동일 로직 —
 * 한쪽을 고치면 반드시 다른 쪽도 맞출 것.
 */
function resolveUltraSrtNcstSlot(kst: Date): { baseDate: string; baseTime: string; slot: string } {
  const minute = kst.getUTCMinutes();
  let hour = kst.getUTCHours();
  let dateForBase = kst;

  if (minute < 10) {
    hour -= 1;
    if (hour < 0) {
      hour = 23;
      dateForBase = new Date(kst.getTime() - 24 * 60 * 60 * 1000);
    }
  }

  const baseDate = ymd(dateForBase);
  const baseTime = `${String(hour).padStart(2, '0')}00`;
  return { baseDate, baseTime, slot: `${baseDate}${baseTime}` };
}

function parseRn(raw: unknown): number {
  if (typeof raw !== 'string') return 0;
  const trimmed = raw.trim();
  if (trimmed === '') return 0;
  const value = Number(trimmed);
  return Number.isFinite(value) ? value : 0;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export type PrecipPollResult = { polled: number; failed: number };

/**
 * 마지막으로 전 셀을 다 돈 slot. RN1은 매시 정각에 한 번만 갱신되는데 트리거는
 * 10분마다 오므로(같은 slot에 시간당 최대 6번 트리거됨), 이미 이 slot을 돌았다면
 * KMA를 호출조차 하지 않고 건너뛴다 — addObservedRn의 slot 중복 가드는 Firestore
 * 반영 단계에서만 걸러줄 뿐 KMA 호출 자체(하루 유일 쿼터)는 막아주지 않는다.
 */
let lastPolledSlot: string | null = null;

/**
 * 최근에 실제로 조회된 셀만 순회하며 이번 시간대(slot)의 RN1(직전 1시간 실측
 * 강수량)을 조회해 Firestore에 누적한다. 전국 셀을 도는 게 아니라 활성 셀만
 * 도므로([[kma-429-precip-poller]] 참고), 아직 한 번도 조회된 적 없는 셀은
 * 애초에 이 목록에 없다 — 그런 지역은 accumulatedRn=0으로 남아 앱이 예보값만
 * 보여준다(isFirstDay).
 */
export async function pollAndAccumulatePrecip(): Promise<PrecipPollResult> {
  const kst = nowKst();
  const dateKey = ymd(kst);
  const { baseDate, baseTime, slot } = resolveUltraSrtNcstSlot(kst);

  if (slot === lastPolledSlot) {
    return { polled: 0, failed: 0 };
  }
  lastPolledSlot = slot;

  const activeCells = await getActiveCells(ACTIVE_CELL_MAX_AGE_MS);

  let polled = 0;
  let failed = 0;

  for (const cell of activeCells) {
    try {
      const json = await fetchKmaJson(KMA_ENDPOINTS.ultraSrtNcst, {
        nx: cell.nx,
        ny: cell.ny,
        base_date: baseDate,
        base_time: baseTime,
      });
      const items = extractItems(json);
      const rn1Item = items.find((item) => item.category === 'RN1');
      const rn = parseRn(rn1Item?.obsrValue);
      await addObservedRn(cell.nx, cell.ny, dateKey, slot, rn);
      polled += 1;
    } catch (err) {
      failed += 1;
      const message = err instanceof KmaError ? `${err.resultCode}: ${err.resultMsg}` : String(err);
      console.error(`[precip-poller] (${cell.nx},${cell.ny}) 실패: ${message}`);
    }
    await sleep(POLL_DELAY_MS);
  }

  return { polled, failed };
}

let inFlight = false;

/**
 * 활성 셀 수가 많으면 GitHub Actions 트리거(.github/workflows/poll-alerts.yml, 10분
 * 간격)의 60초 curl 타임아웃 안에 못 끝날 수 있다. 그래서 이 함수는 결과를 기다리지
 * 않고 백그라운드로 던지기만 한다 — 호출부(HTTP 핸들러)는 즉시 응답할 수 있고,
 * 폴링은 같은 Node 프로세스에서 계속 실행된다. 이전 실행이 아직 안 끝났으면(10분
 * 트리거가 겹칠 만큼 느려진 경우) 새로 시작하지 않고 건너뛴다.
 */
export function schedulePrecipPoll(): void {
  if (inFlight) return;
  inFlight = true;
  pollAndAccumulatePrecip()
    .catch((err) => {
      console.error(`[precip-poller] 전체 실패: ${err instanceof Error ? err.message : String(err)}`);
    })
    .finally(() => {
      inFlight = false;
    });
}
