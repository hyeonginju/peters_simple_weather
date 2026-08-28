import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';

import { MAX_REQUESTS, WINDOW_MS, consume, resetBuckets } from './rateLimit';

beforeEach(() => resetBuckets());

const T0 = 1_700_000_000_000;

test('한도 안에서는 계속 허용하고 남은 횟수를 센다', () => {
  assert.deepEqual(consume('1.1.1.1', T0), {
    allowed: true,
    remaining: MAX_REQUESTS - 1,
    resetAt: T0 + WINDOW_MS,
  });

  for (let i = 2; i < MAX_REQUESTS; i++) consume('1.1.1.1', T0);

  const last = consume('1.1.1.1', T0);
  assert.equal(last.allowed, true);
  assert.equal(last.remaining, 0);
});

test('한도를 넘기면 차단한다', () => {
  for (let i = 0; i < MAX_REQUESTS; i++) consume('1.1.1.1', T0);
  assert.equal(consume('1.1.1.1', T0).allowed, false);
});

test('윈도가 지나면 초기화된다', () => {
  for (let i = 0; i < MAX_REQUESTS; i++) consume('1.1.1.1', T0);
  assert.equal(consume('1.1.1.1', T0).allowed, false);

  const after = consume('1.1.1.1', T0 + WINDOW_MS);
  assert.equal(after.allowed, true);
  assert.equal(after.remaining, MAX_REQUESTS - 1);
});

test('IP별로 버킷이 독립이다', () => {
  for (let i = 0; i < MAX_REQUESTS; i++) consume('1.1.1.1', T0);
  assert.equal(consume('1.1.1.1', T0).allowed, false);
  assert.equal(consume('2.2.2.2', T0).allowed, true);
});

test('앱의 최악 버스트(분당 50회)는 한도에 닿지 않는다', () => {
  // 특보 전국 토글 10관서 + 지역 새로고침 6엔드포인트, 각 3회 재시도 = 48회.
  for (let i = 0; i < 48; i++) {
    assert.equal(consume('1.1.1.1', T0 + i).allowed, true);
  }
});
