import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';

import { cached, resetCache } from './cache';

beforeEach(() => resetCache());

const T0 = 1_700_000_000_000;
const TTL = 60_000;

test('TTL 안에서는 fetcher를 한 번만 부른다', async () => {
  let calls = 0;
  const fetcher = async () => {
    calls++;
    return 'v';
  };

  assert.equal(await cached('k', TTL, T0, fetcher), 'v');
  assert.equal(await cached('k', TTL, T0 + TTL - 1, fetcher), 'v');
  assert.equal(calls, 1);
});

test('TTL이 지나면 다시 부른다', async () => {
  let calls = 0;
  const fetcher = async () => `v${++calls}`;

  assert.equal(await cached('k', TTL, T0, fetcher), 'v1');
  assert.equal(await cached('k', TTL, T0 + TTL, fetcher), 'v2');
});

test('키가 다르면 각각 부른다', async () => {
  let calls = 0;
  const fetcher = async () => `v${++calls}`;

  assert.equal(await cached('a', TTL, T0, fetcher), 'v1');
  assert.equal(await cached('b', TTL, T0, fetcher), 'v2');
});

test('진행 중인 호출에 몰려온 요청은 한 번으로 접힌다', async () => {
  let calls = 0;
  let release: (v: string) => void = () => {};
  const fetcher = () => {
    calls++;
    return new Promise<string>((resolve) => {
      release = resolve;
    });
  };

  // 첫 호출이 아직 안 끝난 상태에서 같은 키로 120번 더 들어온다(레이트 리밋 한도).
  const all = Array.from({ length: 120 }, () => cached('k', TTL, T0, fetcher));
  release('v');

  assert.deepEqual(await Promise.all(all), Array(120).fill('v'));
  assert.equal(calls, 1);
});

test('실패는 캐시하지 않는다', async () => {
  let calls = 0;
  const failing = async () => {
    calls++;
    throw new Error('업스트림 장애');
  };

  await assert.rejects(cached('k', TTL, T0, failing));
  await assert.rejects(cached('k', TTL, T0, failing));
  assert.equal(calls, 2);
});

test('실패 뒤 성공한 값은 정상적으로 캐시된다', async () => {
  await assert.rejects(cached('k', TTL, T0, async () => {
    throw new Error('일시 장애');
  }));

  let calls = 0;
  const ok = async () => `v${++calls}`;
  assert.equal(await cached('k', TTL, T0, ok), 'v1');
  assert.equal(await cached('k', TTL, T0, ok), 'v1');
});
