import { KMA_ENDPOINTS } from '../kma/endpoints';
import { extractItems, fetchKmaJson, KmaError } from '../kma/client';
import { nowKst, ymd } from '../alerts/parse';
import { PRECIP_GRID_CELLS } from './regionGrid';
import { addObservedRn } from './precipStore';

/**
 * 셀 사이 호출 간격. KMA 게이트웨이의 429는 하루 한도가 아니라 짧은 시간에 요청이
 * 몰릴 때 나는 단기 rate limit이므로([[widget-429-rate-limit]] 참고), 211개 셀을
 * 한꺼번에 쏘지 않고 이 간격만큼 띄워서 호출한다.
 */
const POLL_DELAY_MS = 400;

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
 * 격자 셀 전부를 순회하며 이번 시간대(slot)의 RN1(직전 1시간 실측 강수량)을 조회해
 * Firestore에 누적한다. addObservedRn이 slot 중복을 막아주므로, 이 함수가 하루 안에
 * 여러 번(5분 간격 cron) 불려도 같은 시간대는 한 번만 반영된다.
 */
export async function pollAndAccumulatePrecip(): Promise<PrecipPollResult> {
  const kst = nowKst();
  const dateKey = ymd(kst);
  const { baseDate, baseTime, slot } = resolveUltraSrtNcstSlot(kst);

  let polled = 0;
  let failed = 0;

  for (const cell of PRECIP_GRID_CELLS) {
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
 * 211개 셀을 도는 데 ~1분 이상 걸려 cron-job.org의 60초 타임아웃 안에 못 끝난다.
 * 그래서 이 함수는 결과를 기다리지 않고 백그라운드로 던지기만 한다 — 호출부(HTTP
 * 핸들러)는 즉시 응답할 수 있고, 폴링은 같은 Node 프로세스에서 계속 실행된다.
 * 이전 실행이 아직 안 끝났으면(5분 트리거가 겹칠 만큼 느려진 경우) 새로 시작하지
 * 않고 건너뛴다 — 어차피 addObservedRn이 같은 slot 중복 반영은 막아준다.
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
