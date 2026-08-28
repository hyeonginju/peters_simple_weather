import type { Request, Response, NextFunction } from 'express';

/**
 * IP당 고정 윈도 레이트 리밋. 레포가 공개되면 프록시 주소도 함께 공개되므로,
 * 무단 사용으로 KMA 일일 한도가 소진되는 것을 막는 최소 장치다.
 *
 * 한도는 앱의 최악 사용량보다 넉넉히 위에 둔다. 앱이 한 번에 가장 많이 부르는
 * 경우는 "특보 전국 토글(관서 10곳) + 지역 새로고침(6개 엔드포인트)"이고 각각
 * 최대 3회까지 재시도하므로 분당 50회 안쪽이다 — 그 두 배가 조금 넘는 값.
 */
export const WINDOW_MS = 60_000;
export const MAX_REQUESTS = 120;

/** 버킷이 이만큼 쌓이면 만료된 것들을 청소한다(메모리 무한증가 방지). */
const SWEEP_THRESHOLD = 1000;

type Bucket = { count: number; resetAt: number };

const buckets = new Map<string, Bucket>();

export type ConsumeResult = { allowed: boolean; remaining: number; resetAt: number };

/** 키 하나의 요청을 1 소비하고 허용 여부를 돌려준다(미들웨어와 테스트 공용). */
export function consume(key: string, now: number): ConsumeResult {
  if (buckets.size >= SWEEP_THRESHOLD) sweep(now);

  const bucket = buckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    const fresh = { count: 1, resetAt: now + WINDOW_MS };
    buckets.set(key, fresh);
    return { allowed: true, remaining: MAX_REQUESTS - 1, resetAt: fresh.resetAt };
  }

  bucket.count++;
  return {
    allowed: bucket.count <= MAX_REQUESTS,
    remaining: Math.max(0, MAX_REQUESTS - bucket.count),
    resetAt: bucket.resetAt,
  };
}

/** 테스트에서 상태를 비우기 위한 훅. */
export function resetBuckets(): void {
  buckets.clear();
}

function sweep(now: number): void {
  for (const [key, bucket] of buckets) {
    if (bucket.resetAt <= now) buckets.delete(key);
  }
}

/**
 * 버킷 키로 쓸 클라이언트 IP를 고른다.
 *
 * Render는 Cloudflare 뒤에 있어 프록시 홉이 2단이다. req.ip만 믿으면 한 홉만
 * 되돌려 회전하는 중간 프록시 주소가 잡히고, 그러면 서로 다른 사용자가 한
 * 버킷을 공유해(= 남의 대량 호출에 우리 앱이 대신 막힘) 리밋이 부정확해진다.
 *
 * Cloudflare가 넣는 CF-Connecting-IP는 엣지에서 항상 덮어쓰므로 클라이언트가
 * 위조해도 소용이 없다 — 이걸 우선 쓰고, 없을 때만 req.ip로 물러난다.
 */
export function clientKey(req: Request): { key: string; source: 'cf' | 'req-ip' | 'unknown' } {
  const cf = req.headers['cf-connecting-ip'];
  if (typeof cf === 'string' && cf !== '') return { key: cf, source: 'cf' };

  const ip = req.ip;
  if (typeof ip === 'string' && ip !== '') return { key: ip, source: 'req-ip' };

  return { key: 'unknown', source: 'unknown' };
}

export function rateLimit(req: Request, res: Response, next: NextFunction): void {
  const now = Date.now();
  const { key, source } = clientKey(req);
  const result = consume(key, now);

  res.setHeader('RateLimit-Limit', String(MAX_REQUESTS));
  res.setHeader('RateLimit-Remaining', String(result.remaining));
  // 어떤 출처로 키를 잡았는지 확인용(IP 자체는 노출하지 않는다).
  res.setHeader('RateLimit-Key-Source', source);

  if (!result.allowed) {
    const retryAfterSeconds = Math.max(1, Math.ceil((result.resetAt - now) / 1000));
    res.setHeader('Retry-After', String(retryAfterSeconds));
    res.status(429).json({ error: 'too_many_requests', retryAfterSeconds });
    return;
  }

  next();
}
