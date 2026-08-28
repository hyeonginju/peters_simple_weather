import { Router, type Request, type Response } from 'express';

import { KMA_ENDPOINTS } from '../kma/endpoints';
import { fetchKmaJson } from '../kma/client';
import { cached } from '../kma/cache';
import { isKnownCell, isKnownMidLandCode, isKnownMidTaCode, isKnownRegion } from '../regions';
import { PUSH_STN_IDS } from '../alerts/stnMapper';
import { getPrecipState, touchActiveCell } from '../precip/precipStore';
import { fetchAirQuality } from '../air/airQuality';
import { nowKst, ymd } from '../alerts/parse';

/**
 * 앱이 KMA를 직접 호출하지 않고 이 프록시를 거치게 하기 위한 라우트.
 * 응답은 KMA JSON을 그대로 전달하므로 앱의 기존 파싱 로직이 변경 없이 동작한다.
 * serviceKey는 서버 환경변수에만 존재하므로 앱 번들에서 키가 사라진다.
 *
 * 레포가 공개돼 이 주소를 누구나 알 수 있으므로, 모든 라우트는 (1) 파라미터를
 * 실제 지역 목록으로 화이트리스트 검증하고 (2) 응답을 짧게 캐시한다. 앞의 것은
 * 임의 값으로 Firestore 문서를 무한정 만드는 걸 막고, 뒤의 것은 요청 수가 그대로
 * KMA 일일 쿼터 소진으로 이어지는 걸 막는다.
 */
export const weatherRouter = Router();

/**
 * 예보/실황 응답 캐시 TTL. 이 엔드포인트들은 발표시각(base_time·tmFc)이 요청
 * 파라미터에 들어 있어 같은 키의 응답이 바뀌지 않는다 — 캐시를 길게 잡아도
 * 신선도가 떨어지지 않고, 앱은 새 발표시각을 요청하면 그만이다.
 */
const FORECAST_CACHE_MS = 10 * 60_000;

/**
 * 특보는 fromTmFc/toTmFc가 날짜라 키가 하루 종일 같은데 내용은 수시로 바뀐다 →
 * 짧게 잡는다. 1분이어도 레이트 리밋 한도(분당 120회)가 KMA 1회로 접힌다.
 */
const ALERT_CACHE_MS = 60_000;

/** 대기질 측정값은 1시간 단위로 갱신된다. */
const AIR_CACHE_MS = 10 * 60_000;

/** 강수 누적치는 폴러가 매시 한 번만 갱신하므로 그 사이 다시 읽을 필요가 없다. */
const PRECIP_CACHE_MS = 10 * 60_000;

/**
 * 활성 셀 등록(lastRequestedAt 갱신)을 억제하는 주기. 폴러는 48시간 이내 조회된
 * 셀을 대상으로 하므로 시간당 한 번만 갱신해도 판정이 달라지지 않는다 — 요청마다
 * 쓰면 Firestore 쓰기가 요청 수만큼 발생해 무료 한도를 훌쩍 넘긴다.
 */
const CELL_TOUCH_MS = 60 * 60_000;

/** 앱이 조회하는 관서: 9개 권역 + 전국(108). 그 밖의 stnId는 통과시키지 않는다. */
const ALLOWED_STN_IDS = new Set([...PUSH_STN_IDS, '108']);

type ProxyDef = {
  endpoint: string;
  required: string[];
  /** 서버에서 고정으로 주입하는 파라미터(기존 Dart 클라이언트가 설정하던 값). */
  fixed: Record<string, string | number>;
  /** 화이트리스트 검사. 허용되지 않는 값이면 사유 문자열, 통과하면 null. */
  validate: (params: Record<string, string>) => string | null;
  cacheTtlMs: number;
};

const validateCell = (p: Record<string, string>): string | null =>
  isKnownCell(p.nx, p.ny) ? null : `지원하지 않는 격자 좌표: ${p.nx},${p.ny}`;

const PROXIES: Record<string, ProxyDef> = {
  'vilage-fcst': {
    endpoint: KMA_ENDPOINTS.vilageFcst,
    required: ['nx', 'ny', 'base_date', 'base_time'],
    fixed: { numOfRows: 1000 },
    validate: validateCell,
    cacheTtlMs: FORECAST_CACHE_MS,
  },
  'ultra-srt-ncst': {
    endpoint: KMA_ENDPOINTS.ultraSrtNcst,
    required: ['nx', 'ny', 'base_date', 'base_time'],
    fixed: { numOfRows: 100 },
    validate: validateCell,
    cacheTtlMs: FORECAST_CACHE_MS,
  },
  'mid-land-fcst': {
    endpoint: KMA_ENDPOINTS.midLandFcst,
    required: ['regId', 'tmFc'],
    fixed: { numOfRows: 10 },
    validate: (p) => (isKnownMidLandCode(p.regId) ? null : `지원하지 않는 구역 코드: ${p.regId}`),
    cacheTtlMs: FORECAST_CACHE_MS,
  },
  'mid-ta': {
    endpoint: KMA_ENDPOINTS.midTa,
    required: ['regId', 'tmFc'],
    fixed: { numOfRows: 10 },
    validate: (p) => (isKnownMidTaCode(p.regId) ? null : `지원하지 않는 구역 코드: ${p.regId}`),
    cacheTtlMs: FORECAST_CACHE_MS,
  },
  'wthr-wrn-msg': {
    endpoint: KMA_ENDPOINTS.wthrWrnMsg,
    required: ['stnId', 'fromTmFc', 'toTmFc'],
    fixed: { numOfRows: 1 },
    validate: (p) => (ALLOWED_STN_IDS.has(p.stnId) ? null : `지원하지 않는 관서: ${p.stnId}`),
    cacheTtlMs: ALERT_CACHE_MS,
  },
};

for (const [name, def] of Object.entries(PROXIES)) {
  weatherRouter.get(`/${name}`, (req, res) => handleProxy(req, res, def));
}

/**
 * 백그라운드 RN1 폴러(precip/poller.ts)가 Firestore에 쌓아둔 "오늘 00시~마지막
 * 관측 시간대까지 누적 강수량"을 읽어서 돌려준다. KMA를 직접 호출하지 않는다.
 *
 * 호출과 동시에 이 셀을 활성으로 등록한다(touchActiveCell) — 폴러가 전국 셀이
 * 아니라 실제로 조회되는 셀만 돌게 하기 위함. firstActiveDate가 오늘이면(=이
 * 셀이 처음 쓰이기 시작한 날) isFirstDay=true를 내려줘서, 앱이 아직 실측 데이터가
 * 없는 첫날은 예보값만 보여주도록 한다.
 *
 * 등록은 폴러의 조회 대상을 늘리는 행위이므로 반드시 실제 지역 좌표여야 하고,
 * Firestore 접근은 둘 다 캐시를 거친다(위 TTL 주석 참고).
 */
weatherRouter.get('/precip-today', async (req, res) => {
  const { nx: rawNx, ny: rawNy } = req.query;
  if (!isKnownCell(rawNx, rawNy)) {
    res.status(400).json({ error: `지원하지 않는 격자 좌표: ${String(rawNx)},${String(rawNy)}` });
    return;
  }
  const nx = Number(rawNx);
  const ny = Number(rawNy);

  try {
    const now = Date.now();
    const dateKey = ymd(nowKst());
    const [state, firstActiveDate] = await Promise.all([
      cached(`precip:${nx}_${ny}:${dateKey}`, PRECIP_CACHE_MS, now, () => getPrecipState(nx, ny, dateKey)),
      cached(`cell:${nx}_${ny}:${dateKey}`, CELL_TOUCH_MS, now, () => touchActiveCell(nx, ny, dateKey)),
    ]);
    res.json({
      accumulatedRn: state.accumulatedRn,
      lastSlot: state.lastSlot,
      isFirstDay: firstActiveDate === dateKey,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[precip-today] 조회 실패: ${message}`);
    res.status(502).json({ error: '강수량 누적치 조회에 실패했습니다.', detail: message });
  }
});

/**
 * 지역(province/name)의 현재 미세먼지/초미세먼지 수준을 에어코리아에서 조회해
 * 앱 친화적 평면 JSON으로 돌려준다. KMA와 동일한 serviceKey를 서버에서 주입하므로
 * 앱 번들엔 키가 없다. 대기질은 부가 정보라 실패해도 앱은 배지만 숨기면 된다.
 *
 * province/name을 지역 목록으로 검증한다 — airQuality.ts가 조회 결과를 이 조합으로
 * 캐시하는데(측정소는 위치가 안 바뀌므로 상한 없는 Map), 임의 문자열을 받으면
 * 그 Map이 무한히 커져 인스턴스가 메모리로 죽는다.
 */
weatherRouter.get('/air-quality', async (req, res) => {
  const province = typeof req.query.province === 'string' ? req.query.province : '';
  const name = typeof req.query.name === 'string' ? req.query.name : '';
  if (!isKnownRegion(province, name)) {
    res.status(400).json({ error: `지원하지 않는 지역: ${province}/${name}` });
    return;
  }

  try {
    res.json(
      await cached(`air:${province}/${name}`, AIR_CACHE_MS, Date.now(), () => fetchAirQuality(province, name)),
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[air-quality] ${province} ${name} 실패: ${message}`);
    res.status(502).json({ error: '대기질 정보 조회에 실패했습니다.', detail: message });
  }
});

async function handleProxy(req: Request, res: Response, def: ProxyDef): Promise<void> {
  const params: Record<string, string | number> = { ...def.fixed };
  const given: Record<string, string> = {};
  for (const key of def.required) {
    const value = req.query[key];
    if (typeof value !== 'string' || value === '') {
      res.status(400).json({ error: `필수 파라미터 누락: ${key}` });
      return;
    }
    params[key] = value;
    given[key] = value;
  }

  const rejection = def.validate(given);
  if (rejection !== null) {
    res.status(400).json({ error: rejection });
    return;
  }

  try {
    const key = `${def.endpoint}?${new URLSearchParams(Object.entries(params).map(([k, v]) => [k, String(v)])).toString()}`;
    const json = await cached(key, def.cacheTtlMs, Date.now(), () => fetchKmaJson(def.endpoint, params));
    res.json(json);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[proxy] ${def.endpoint} 실패: ${message}`);
    res.status(502).json({ error: '기상청 API 호출에 실패했습니다.', detail: message });
  }
}
