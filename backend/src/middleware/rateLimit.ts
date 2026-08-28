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

export function rateLimit(req: Request, res: Response, next: NextFunction): void {
  const now = Date.now();
  // req.ip는 index.ts의 trust proxy 설정에 따라 실제 클라이언트 IP가 된다.
  const result = consume(req.ip ?? 'unknown', now);

  res.setHeader('RateLimit-Limit', String(MAX_REQUESTS));
  res.setHeader('RateLimit-Remaining', String(result.remaining));

  if (!result.allowed) {
    const retryAfterSeconds = Math.max(1, Math.ceil((result.resetAt - now) / 1000));
    res.setHeader('Retry-After', String(retryAfterSeconds));
    res.status(429).json({ error: 'too_many_requests', retryAfterSeconds });
    return;
  }

  next();
}
