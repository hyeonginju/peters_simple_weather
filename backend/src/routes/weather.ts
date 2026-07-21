import { Router, type Request, type Response } from 'express';

import { KMA_ENDPOINTS } from '../kma/endpoints';
import { fetchKmaJson } from '../kma/client';
import { getPrecipState, touchActiveCell } from '../precip/precipStore';
import { fetchAirQuality } from '../air/airQuality';
import { nowKst, ymd } from '../alerts/parse';

/**
 * 앱이 KMA를 직접 호출하지 않고 이 프록시를 거치게 하기 위한 라우트.
 * 응답은 KMA JSON을 그대로 전달하므로 앱의 기존 파싱 로직이 변경 없이 동작한다.
 * serviceKey는 서버 환경변수에만 존재하므로 앱 번들에서 키가 사라진다.
 */
export const weatherRouter = Router();

type ProxyDef = {
  endpoint: string;
  required: string[];
  /** 서버에서 고정으로 주입하는 파라미터(기존 Dart 클라이언트가 설정하던 값). */
  fixed: Record<string, string | number>;
};

const PROXIES: Record<string, ProxyDef> = {
  'vilage-fcst': {
    endpoint: KMA_ENDPOINTS.vilageFcst,
    required: ['nx', 'ny', 'base_date', 'base_time'],
    fixed: { numOfRows: 1000 },
  },
  'ultra-srt-ncst': {
    endpoint: KMA_ENDPOINTS.ultraSrtNcst,
    required: ['nx', 'ny', 'base_date', 'base_time'],
    fixed: { numOfRows: 100 },
  },
  'mid-land-fcst': {
    endpoint: KMA_ENDPOINTS.midLandFcst,
    required: ['regId', 'tmFc'],
    fixed: { numOfRows: 10 },
  },
  'mid-ta': {
    endpoint: KMA_ENDPOINTS.midTa,
    required: ['regId', 'tmFc'],
    fixed: { numOfRows: 10 },
  },
  'wthr-wrn-msg': {
    endpoint: KMA_ENDPOINTS.wthrWrnMsg,
    required: ['stnId', 'fromTmFc', 'toTmFc'],
    fixed: { numOfRows: 1 },
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
 */
weatherRouter.get('/precip-today', async (req, res) => {
  const nx = Number(req.query.nx);
  const ny = Number(req.query.ny);
  if (!Number.isFinite(nx) || !Number.isFinite(ny)) {
    res.status(400).json({ error: '필수 파라미터 누락: nx, ny' });
    return;
  }

  try {
    const dateKey = ymd(nowKst());
    const [state, firstActiveDate] = await Promise.all([
      getPrecipState(nx, ny, dateKey),
      touchActiveCell(nx, ny, dateKey),
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
 */
weatherRouter.get('/air-quality', async (req, res) => {
  const province = typeof req.query.province === 'string' ? req.query.province : '';
  const name = typeof req.query.name === 'string' ? req.query.name : '';
  if (!province || !name) {
    res.status(400).json({ error: '필수 파라미터 누락: province, name' });
    return;
  }

  try {
    res.json(await fetchAirQuality(province, name));
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[air-quality] ${province} ${name} 실패: ${message}`);
    res.status(502).json({ error: '대기질 정보 조회에 실패했습니다.', detail: message });
  }
});

async function handleProxy(req: Request, res: Response, def: ProxyDef): Promise<void> {
  const params: Record<string, string | number> = { ...def.fixed };
  for (const key of def.required) {
    const value = req.query[key];
    if (typeof value !== 'string' || value === '') {
      res.status(400).json({ error: `필수 파라미터 누락: ${key}` });
      return;
    }
    params[key] = value;
  }

  try {
    const json = await fetchKmaJson(def.endpoint, params);
    res.json(json);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[proxy] ${def.endpoint} 실패: ${message}`);
    res.status(502).json({ error: '기상청 API 호출에 실패했습니다.', detail: message });
  }
}
