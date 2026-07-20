import assert from 'node:assert/strict';
import { before, test } from 'node:test';

// config가 import 시점에 이 env들을 요구하므로 동적 import 전에 채워 둔다.
process.env.KMA_SERVICE_KEY ??= 'test-key';
process.env.POLL_SECRET ??= 'test-secret';

let fetchKmaJson: typeof import('./client').fetchKmaJson;
before(async () => {
  fetchKmaJson = (await import('./client')).fetchKmaJson;
});

const OK_BODY = { response: { header: { resultCode: '00' }, body: { items: { item: [] } } } };
const okResponse = () => new Response(JSON.stringify(OK_BODY), { status: 200 });
const timeout = () => new DOMException('The operation was aborted due to timeout', 'TimeoutError');

/** globalThis.fetch를 임시 교체하고 호출 횟수를 세는 헬퍼(끝나면 원복). */
async function withFetch(
  impl: () => Promise<Response>,
  body: (calls: () => number) => Promise<void>,
): Promise<void> {
  const original = globalThis.fetch;
  let calls = 0;
  globalThis.fetch = (async () => {
    calls++;
    return impl();
  }) as typeof fetch;
  try {
    await body(() => calls);
  } finally {
    globalThis.fetch = original;
  }
}

test('타임아웃으로 던지면 재시도해서 성공한다', async () => {
  let n = 0;
  await withFetch(
    async () => {
      n++;
      if (n === 1) throw timeout();
      return okResponse();
    },
    async (calls) => {
      const json = await fetchKmaJson('https://example.com/x', {});
      assert.equal(calls(), 2);
      assert.equal(json.response?.header?.resultCode, '00');
    },
  );
});

test('모든 시도가 타임아웃이면 3번 시도 후 마지막 에러를 던진다', async () => {
  await withFetch(
    async () => {
      throw timeout();
    },
    async (calls) => {
      await assert.rejects(() => fetchKmaJson('https://example.com/x', {}));
      assert.equal(calls(), 3);
    },
  );
});

test('HTTP 상태 오류(5xx)는 재시도하지 않고 즉시 실패한다', async () => {
  await withFetch(
    async () => new Response('nope', { status: 500 }),
    async (calls) => {
      await assert.rejects(() => fetchKmaJson('https://example.com/x', {}), /HTTP 500/);
      assert.equal(calls(), 1);
    },
  );
});
