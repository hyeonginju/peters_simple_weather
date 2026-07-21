import { AIR_ENDPOINTS } from '../kma/endpoints';
import { fetchKmaJson, KmaError, type KmaJson } from '../kma/client';

/**
 * 앱의 지역 province(정식 명칭) → 에어코리아 getMsrstnList의 addr 검색용 시도명.
 * 에어코리아는 "서울/경기/충북"처럼 축약 시도명을 쓴다. 지역 목록의 17개 시도가
 * 고정이므로 영리한 문자열 자르기 대신 명시적 매핑으로 둔다(오독 방지).
 */
export const PROVINCE_TO_SIDO: Record<string, string> = {
  서울특별시: '서울',
  부산광역시: '부산',
  대구광역시: '대구',
  인천광역시: '인천',
  광주광역시: '광주',
  대전광역시: '대전',
  울산광역시: '울산',
  세종특별자치시: '세종',
  경기도: '경기',
  강원특별자치도: '강원',
  충청북도: '충북',
  충청남도: '충남',
  전북특별자치도: '전북',
  전라남도: '전남',
  경상북도: '경북',
  경상남도: '경남',
  제주특별자치도: '제주',
};

export type Station = { name: string; addr: string };

export type AirQuality = {
  stationName: string;
  pm10: number | null;
  pm10Grade: number | null;
  pm25: number | null;
  pm25Grade: number | null;
  khaiGrade: number | null;
  dataTime: string | null;
};

/**
 * 에어코리아 응답 body.items 배열을 꺼낸다. KMA(body.items.item)와 달리 items가
 * 곧바로 배열이라 client.ts의 extractItems를 못 쓴다. resultCode '00'이 아니면
 * KMA와 동일하게 KmaError를 던진다.
 */
export function extractAirItems(json: KmaJson): Record<string, unknown>[] {
  const header = json.response?.header;
  if (header?.resultCode !== '00') {
    throw new KmaError(header?.resultCode ?? 'UNKNOWN', header?.resultMsg ?? '');
  }
  const items = (json.response?.body as { items?: unknown } | undefined)?.items;
  return Array.isArray(items) ? (items as Record<string, unknown>[]) : [];
}

/** 문자열 수치를 number로. "-"/""/"점검중" 등 비수치는 null. */
function num(raw: unknown): number | null {
  if (typeof raw !== 'string') return null;
  const trimmed = raw.trim();
  if (trimmed === '' || trimmed === '-') return null;
  const value = Number(trimmed);
  return Number.isFinite(value) ? value : null;
}

/** 등급은 1~4만 유효. 그 밖(빈값·범위밖)은 null. */
function grade(raw: unknown): number | null {
  const value = num(raw);
  return value !== null && value >= 1 && value <= 4 ? value : null;
}

/**
 * 시도 측정소 목록에서 지역(시군구 name)에 해당하는 측정소를 고른다. 측정소
 * addr에는 구/군이 들어있어("서울 강남구 …") name 부분 일치로 찾는다. 못 찾으면
 * (세종처럼 name==시도이거나 측정소 없는 군) 목록의 첫 측정소로 폴백 — 배지
 * 용도라 시도 대표값이라도 보여주는 편이 낫다.
 */
export function pickStation(stations: Station[], name: string): Station | null {
  if (stations.length === 0) return null;
  return stations.find((s) => s.addr.includes(name)) ?? stations[0];
}

/** 실시간 응답 item 하나를 앱 친화적 평면 객체로. 등급은 24h(pm10Grade)를 우선하되
 * 없으면 1h(pm10Grade1h)로 폴백해 "지금 수준"을 최대한 채운다. */
export function parseAirItem(item: Record<string, unknown>, stationName: string): AirQuality {
  return {
    stationName,
    pm10: num(item.pm10Value),
    pm10Grade: grade(item.pm10Grade) ?? grade(item.pm10Grade1h),
    pm25: num(item.pm25Value),
    pm25Grade: grade(item.pm25Grade) ?? grade(item.pm25Grade1h),
    khaiGrade: grade(item.khaiGrade),
    dataTime: typeof item.dataTime === 'string' ? item.dataTime : null,
  };
}

// 측정소는 위치가 바뀌지 않으므로 시도별 목록을 프로세스 메모리에 캐시한다.
const stationsBySido = new Map<string, Station[]>();
// province/name → 확정 측정소명 캐시(목록 조회를 매번 하지 않도록).
const resolvedStation = new Map<string, string>();

async function stationsForSido(sido: string): Promise<Station[]> {
  const cached = stationsBySido.get(sido);
  if (cached) return cached;

  const json = await fetchKmaJson(AIR_ENDPOINTS.msrstnList, {
    returnType: 'json',
    numOfRows: 700,
    addr: sido,
  });
  const stations = extractAirItems(json)
    .map((i) => ({ name: String(i.stationName ?? ''), addr: String(i.addr ?? '') }))
    .filter((s) => s.name);
  stationsBySido.set(sido, stations);
  return stations;
}

async function resolveStationName(province: string, name: string): Promise<string> {
  const key = `${province}/${name}`;
  const hit = resolvedStation.get(key);
  if (hit) return hit;

  const sido = PROVINCE_TO_SIDO[province];
  if (!sido) throw new Error(`매핑되지 않은 시도: ${province}`);

  const station = pickStation(await stationsForSido(sido), name);
  if (!station) throw new Error(`측정소를 찾지 못했습니다: ${sido}`);

  resolvedStation.set(key, station.name);
  return station.name;
}

/**
 * 지역(province/name)의 현재 대기질을 조회한다: 시도 측정소 목록에서 최근접
 * 측정소를 정한 뒤 그 측정소의 실시간 측정값을 읽는다. serviceKey는 KMA와 공용.
 */
export async function fetchAirQuality(province: string, name: string): Promise<AirQuality> {
  const stationName = await resolveStationName(province, name);

  const json = await fetchKmaJson(AIR_ENDPOINTS.realtime, {
    returnType: 'json',
    numOfRows: 1,
    dataTerm: 'DAILY',
    ver: '1.3',
    stationName,
  });
  const item = extractAirItems(json)[0];
  if (!item) throw new Error(`실시간 측정값이 없습니다: ${stationName}`);

  return parseAirItem(item, stationName);
}
