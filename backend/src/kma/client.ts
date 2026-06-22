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

/**
 * KMA 엔드포인트를 호출해 응답 JSON 전체를 그대로 반환한다(가공 없음).
 * serviceKey/dataType/pageNo는 서버에서 주입하므로 호출부는 비즈니스 파라미터만 넘긴다.
 * 프록시 라우트가 이 결과를 앱에 그대로 전달하면, 앱의 기존 파싱 로직이 변경 없이 동작한다.
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

  const res = await fetch(`${endpoint}?${query.toString()}`, {
    signal: AbortSignal.timeout(10_000),
  });
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
