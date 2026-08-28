/**
 * 업스트림(KMA·에어코리아) 응답을 키별로 잠깐 재사용하는 메모리 캐시.
 *
 * 레이트 리밋은 한 IP가 분당 몇 번 부를 수 있는지만 제한할 뿐, 그 요청이 그대로
 * 업스트림 호출로 이어지는 걸 막지 못한다. 프록시 응답은 같은 파라미터면 같은
 * 값이므로, 짧게 캐시하는 것만으로 "요청 1건 = KMA 호출 1건" 증폭이 사라지고
 * data.go.kr 일일 쿼터가 소진되지 않는다.
 *
 * 값이 아니라 Promise를 담는다 — 첫 호출이 아직 진행 중일 때 같은 키로 몰려온
 * 요청들이 각자 업스트림을 두드리는 것(동시 폭주)까지 한 번으로 접기 위해서다.
 */
type Entry = { promise: Promise<unknown>; expiresAt: number };

/** 엔트리가 이만큼 쌓이면 만료된 것들을 청소한다(메모리 무한증가 방지). */
const SWEEP_THRESHOLD = 1000;

const entries = new Map<string, Entry>();

/**
 * key에 유효한 캐시가 있으면 그걸 돌려주고, 없으면 fetcher를 호출해 ttlMs 동안 담아둔다.
 * 실패한 호출은 캐시하지 않는다 — 일시 장애가 TTL 동안 굳어버리는 걸 막는다.
 */
export function cached<T>(key: string, ttlMs: number, now: number, fetcher: () => Promise<T>): Promise<T> {
  const hit = entries.get(key);
  if (hit && hit.expiresAt > now) return hit.promise as Promise<T>;

  if (entries.size >= SWEEP_THRESHOLD) sweep(now);

  const promise = fetcher();
  entries.set(key, { promise, expiresAt: now + ttlMs });
  promise.catch(() => {
    if (entries.get(key)?.promise === promise) entries.delete(key);
  });
  return promise;
}

/** 테스트에서 상태를 비우기 위한 훅. */
export function resetCache(): void {
  entries.clear();
}

function sweep(now: number): void {
  for (const [key, entry] of entries) {
    if (entry.expiresAt <= now) entries.delete(key);
  }
}
