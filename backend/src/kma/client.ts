import { config } from '../config';

export type KmaJson = {
  response?: {
    header?: { resultCode?: string; resultMsg?: string };
    body?: { items?: { item?: unknown } };
  };
};

/** KMA 호출이 비정상 resultCode를 반환했을 때 던지는 에러. */
export class KmaError extends Error {
  constructor(public resultCode: string, public resultMsg: string) {
    super(`KMA ${resultCode}: ${resultMsg}`);
    this.name = 'KmaError';
  }
}

/** 한 번 호출의 타임아웃. KMA가 가끔 10초를 살짝 넘겨 응답해 여유를 뒀다. */
const KMA_TIMEOUT_MS = 15_000;
/** 타임아웃/네트워크 오류 시 총 시도 횟수(첫 시도 + 재시도). */
const KMA_MAX_ATTEMPTS = 3;

const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/**
 * KMA 엔드포인트를 호출해 응답 JSON 전체를 그대로 반환한다(가공 없음).
 * serviceKey/dataType/pageNo는 서버에서 주입하므로 호출부는 비즈니스 파라미터만 넘긴다.
 * 프록시 라우트가 이 결과를 앱에 그대로 전달하면, 앱의 기존 파싱 로직이 변경 없이 동작한다.
 *
 * 타임아웃·네트워크 오류는 짧은 백오프로 재시도한다(앱의 KmaApiClient와 동일한 방침).
 * HTTP 상태 오류(4xx/5xx)와 JSON 파싱 실패는 재시도하지 않는다 — 429를 두드리거나
 * 잘못된 키 같은 지속 오류에 시간을 낭비하지 않기 위해서.
 */
export async function fetchKmaJson(
  endpoint: string,
  params: Record<string, string | number>,
): Promise<KmaJson> {
  const query = new URLSearchParams({
    serviceKey: config.kmaServiceKey,
    dataType: 'JSON',
    pageNo: '1',
  });
  for (const [key, value] of Object.entries(params)) {
    query.set(key, String(value));
  }
  const url = `${endpoint}?${query.toString()}`;

  for (let attempt = 1; attempt <= KMA_MAX_ATTEMPTS; attempt++) {
    let res: Response;
    try {
      res = await fetch(url, { signal: AbortSignal.timeout(KMA_TIMEOUT_MS) });
    } catch (err) {
      // fetch가 던지는 건 타임아웃/네트워크 오류뿐 — 재시도 대상.
      if (attempt >= KMA_MAX_ATTEMPTS) throw err;
      await delay(attempt * 500);
      continue;
    }

    // fetch 성공 이후의 오류는 재시도하지 않고 즉시 던진다.
    if (!res.ok) {
      throw new Error(`KMA HTTP ${res.status}`);
    }
    // KMA는 키 오류 등에서 XML 에러를 반환하기도 하므로 방어적으로 파싱.
    const text = await res.text();
    try {
      return JSON.parse(text) as KmaJson;
    } catch {
      throw new Error(`KMA가 JSON이 아닌 응답을 반환했습니다: ${text.slice(0, 200)}`);
    }
  }

  // 루프는 항상 return하거나 throw하므로 여기 도달하지 않는다(타입 상 필요).
  throw new Error('unreachable');
}

/**
 * 응답 JSON에서 item 배열을 추출한다(lib/data/kma/kma_api_client.dart의 _getItems와 동일).
 * resultCode가 '00'이 아니면 KmaError를 던지고, item이 없으면 빈 배열을 반환한다.
 */
export function extractItems(json: KmaJson): Record<string, unknown>[] {
  const header = json.response?.header;
  const resultCode = header?.resultCode;
  if (resultCode !== '00') {
    throw new KmaError(resultCode ?? 'UNKNOWN', header?.resultMsg ?? '');
  }

  const item = json.response?.body?.items?.item;
  if (Array.isArray(item)) {
    return item as Record<string, unknown>[];
  }
  if (item && typeof item === 'object') {
    return [item as Record<string, unknown>];
  }
  return [];
}
