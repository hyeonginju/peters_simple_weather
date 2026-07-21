import assert from 'node:assert/strict';
import { test } from 'node:test';

process.env.KMA_SERVICE_KEY ??= 'test-key';

import {
  PROVINCE_TO_SIDO,
  pickStation,
  parseAirItem,
  extractAirItems,
  type Station,
} from './airQuality';
import type { KmaJson } from '../kma/client';

test('PROVINCE_TO_SIDO covers all 17 provinces with 축약 시도명', () => {
  assert.equal(PROVINCE_TO_SIDO['서울특별시'], '서울');
  assert.equal(PROVINCE_TO_SIDO['충청북도'], '충북');
  assert.equal(PROVINCE_TO_SIDO['전북특별자치도'], '전북');
  assert.equal(PROVINCE_TO_SIDO['강원특별자치도'], '강원');
  assert.equal(Object.keys(PROVINCE_TO_SIDO).length, 17);
});

test('pickStation: addr에 시군구명이 든 측정소를 고른다', () => {
  const stations: Station[] = [
    { name: '종로구', addr: '서울 종로구 종로35가길 19' },
    { name: '강남구', addr: '서울 강남구 학동로 426' },
  ];
  assert.equal(pickStation(stations, '강남구')?.name, '강남구');
});

test('pickStation: 일치가 없으면 첫 측정소로 폴백', () => {
  const stations: Station[] = [{ name: '조치원', addr: '세종 조치원읍 군청로 93' }];
  assert.equal(pickStation(stations, '세종특별자치시')?.name, '조치원');
});

test('pickStation: 빈 목록이면 null', () => {
  assert.equal(pickStation([], '강남구'), null);
});

test('parseAirItem: 수치·등급 파싱', () => {
  const air = parseAirItem(
    { pm10Value: '42', pm10Grade: '2', pm25Value: '18', pm25Grade: '1', khaiGrade: '2', dataTime: '2026-07-21 14:00' },
    '강남구',
  );
  assert.deepEqual(air, {
    stationName: '강남구',
    pm10: 42,
    pm10Grade: 2,
    pm25: 18,
    pm25Grade: 1,
    khaiGrade: 2,
    dataTime: '2026-07-21 14:00',
  });
});

test('parseAirItem: 24h 등급이 없으면 1h 등급으로 폴백', () => {
  const air = parseAirItem({ pm10Value: '30', pm10Grade1h: '1', pm25Grade1h: '2' }, '연무동');
  assert.equal(air.pm10Grade, 1);
  assert.equal(air.pm25Grade, 2);
});

test('parseAirItem: 점검중/빈값/범위밖은 null', () => {
  const air = parseAirItem({ pm10Value: '-', pm10Grade: '', pm25Value: '점검중', pm25Grade: '9' }, '연무동');
  assert.equal(air.pm10, null);
  assert.equal(air.pm10Grade, null);
  assert.equal(air.pm25, null);
  assert.equal(air.pm25Grade, null);
  assert.equal(air.dataTime, null);
});

test('extractAirItems: body.items 배열을 그대로 꺼낸다', () => {
  const json = { response: { header: { resultCode: '00' }, body: { items: [{ stationName: 'x' }] } } } as unknown as KmaJson;
  assert.deepEqual(extractAirItems(json), [{ stationName: 'x' }]);
});

test('extractAirItems: resultCode가 00이 아니면 throw', () => {
  const json = { response: { header: { resultCode: '99', resultMsg: 'INVALID' } } } as unknown as KmaJson;
  assert.throws(() => extractAirItems(json));
});
