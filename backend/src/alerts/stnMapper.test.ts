import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  provinceCode,
  provincesForStn,
  provincesInAlertBody,
  topicForProvinceCode,
} from './stnMapper';

// 관서 133 = 대전·세종·충남. 푸시 과다의 핵심 케이스가 여기라 집중 검증한다.
const STN_133 = provincesForStn('133');

test('관서 133은 대전·세종·충남 3개 시/도를 담당한다', () => {
  assert.deepEqual(STN_133, ['대전광역시', '세종특별자치시', '충청남도']);
});

test('본문에 3개 시/도가 모두 있으면 모두 반환', () => {
  const body = 'o 대전광역시, 세종특별자치시, 충청남도(천안, 서산) : 폭염경보';
  assert.deepEqual(provincesInAlertBody(body, STN_133), [
    '대전광역시',
    '세종특별자치시',
    '충청남도',
  ]);
});

test('세종만 언급된 특보는 세종만 반환 — 대전 사용자는 걸러진다', () => {
  const body = 'o 세종특별자치시 : 폭염주의보';
  assert.deepEqual(provincesInAlertBody(body, STN_133), ['세종특별자치시']);
});

test('충남 호우주의보(서산,태안)는 충남만 — 대전 사용자는 걸러진다', () => {
  const body = 'o 충남(서산, 태안) : 호우주의보';
  assert.deepEqual(provincesInAlertBody(body, STN_133), ['충청남도']);
});

test('축약형 "충남"과 전체 표기 "충청남도" 둘 다 매칭', () => {
  assert.deepEqual(provincesInAlertBody('o 충남 : 건조주의보', STN_133), ['충청남도']);
  assert.deepEqual(provincesInAlertBody('o 충청남도 : 건조주의보', STN_133), ['충청남도']);
});

test('대전+충남만 있고 세종 없으면 세종은 빠진다', () => {
  const body = 'o 대전광역시, 충청남도 : 호우주의보';
  assert.deepEqual(provincesInAlertBody(body, STN_133), ['대전광역시', '충청남도']);
});

test('후보를 관서 범위로 제한하므로 타 관서 지역명은 오탐되지 않는다', () => {
  // 156 = 광주·전남. 본문에 "경기"가 우연히 들어가도 후보에 없어 매칭 안 됨.
  const body = 'o 광주광역시 : 폭염경보 (경기 지역 비교 언급)';
  assert.deepEqual(provincesInAlertBody(body, provincesForStn('156')), ['광주광역시']);
});

test('provinceCode / topicForProvinceCode 규칙', () => {
  assert.equal(provinceCode('대전광역시'), 'daejeon');
  assert.equal(provinceCode('세종특별자치시'), 'sejong');
  assert.equal(provinceCode('없는도'), null);
  assert.equal(topicForProvinceCode('daejeon'), 'prov_daejeon');
});
