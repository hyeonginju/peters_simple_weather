import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';

import { REGIONS, isKnownCell, isKnownMidLandCode, isKnownMidTaCode, isKnownRegion } from './regions';

test('regions.json이 앱 자산 원본과 동일하다', () => {
  // 사본이 어긋나면 백엔드가 앱이 실제로 조회하는 지역을 400으로 막게 된다.
  const original = fs.readFileSync(path.resolve(__dirname, '..', '..', 'assets', 'data', 'regions.json'), 'utf8');
  const copy = fs.readFileSync(path.resolve(__dirname, 'regions.json'), 'utf8');
  assert.equal(copy, original);
});

test('실제 지역의 좌표·코드·이름은 모두 통과한다', () => {
  for (const region of REGIONS) {
    assert.ok(isKnownCell(String(region.nx), String(region.ny)), `셀 누락: ${region.id}`);
    assert.ok(isKnownRegion(region.province, region.name), `지역 누락: ${region.id}`);
    assert.ok(isKnownMidLandCode(region.midLandCode), `중기육상 코드 누락: ${region.id}`);
    assert.ok(isKnownMidTaCode(region.midTaCode), `중기기온 코드 누락: ${region.id}`);
  }
});

test('격자 밖 좌표는 막는다', () => {
  assert.equal(isKnownCell('0', '0'), false);
  assert.equal(isKnownCell('999999', '999999'), false);
  assert.equal(isKnownCell('-61', '-125'), false);
});

test('같은 수의 다른 표기는 별개 문서 ID가 되므로 막는다', () => {
  assert.ok(isKnownCell('61', '125'));
  assert.equal(isKnownCell('61.0', '125'), false);
  assert.equal(isKnownCell('0061', '125'), false);
  assert.equal(isKnownCell(' 61', '125'), false);
});

test('누락·비문자열 파라미터는 막는다', () => {
  assert.equal(isKnownCell(undefined, undefined), false);
  assert.equal(isKnownCell(['61', '62'], '125'), false);
  assert.equal(isKnownRegion(undefined, undefined), false);
});

test('실재하지 않는 지역 조합은 막는다', () => {
  assert.ok(isKnownRegion('서울특별시', '강남구'));
  // province와 name이 각각은 실재해도 조합이 없으면 통과시키지 않는다.
  assert.equal(isKnownRegion('부산광역시', '강남구'), false);
  assert.equal(isKnownRegion('서울특별시', '없는구'), false);
});
