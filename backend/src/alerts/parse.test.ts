import assert from 'node:assert/strict';
import { test } from 'node:test';

import { cleanAlertText, parseTmFc } from './parse';

test('"o 없음"류는 빈 문자열로 처리(발효 특보 없음)', () => {
  assert.equal(cleanAlertText('o 없음'), '');
  assert.equal(cleanAlertText('ㅇ 없음'), '');
  assert.equal(cleanAlertText('  o  없 음  '), '');
  assert.equal(cleanAlertText(null), '');
  assert.equal(cleanAlertText(undefined), '');
});

test('실제 특보 본문은 불릿 유지한 채 트림만 해서 반환', () => {
  assert.equal(cleanAlertText('  o 대전광역시 : 폭염경보  '), 'o 대전광역시 : 폭염경보');
});

test('parseTmFc는 yyyyMMddHHmm(KST)을 UTC Date로 변환', () => {
  const d = parseTmFc(202607201200);
  assert.ok(d);
  // 2026-07-20 12:00 KST == 2026-07-20 03:00 UTC
  assert.equal(d!.toISOString(), '2026-07-20T03:00:00.000Z');
  assert.equal(parseTmFc(null), null);
  assert.equal(parseTmFc(12345), null);
});
