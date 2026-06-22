import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// regions.json의 중기예보 코드 무결성 회귀 방지. 코드 정밀화(시군별
/// midTaCode) 작업이 깨지지 않도록 데이터 자체를 검증한다.
void main() {
  final regions = (jsonDecode(File('assets/data/regions.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  final midTaPattern = RegExp(r'^\d{2}[A-Z]\d{5}$');
  const metroProvinces = {
    '서울특별시', '부산광역시', '대구광역시', '인천광역시',
    '광주광역시', '대전광역시', '울산광역시', '세종특별자치시',
  };

  test('모든 지역이 형식에 맞는 midTaCode를 가진다', () {
    for (final r in regions) {
      final code = r['midTaCode'];
      expect(code, isA<String>(), reason: '${r['id']} midTaCode 누락');
      expect(midTaPattern.hasMatch(code as String), isTrue, reason: '${r['id']} 잘못된 형식: $code');
    }
  });

  test('광역시/특별시는 자치구가 모두 같은 midTaCode를 공유한다', () {
    final byProvince = <String, Set<String>>{};
    for (final r in regions) {
      byProvince.putIfAbsent(r['province'] as String, () => {}).add(r['midTaCode'] as String);
    }
    for (final p in metroProvinces) {
      expect(byProvince[p], hasLength(1), reason: '$p 자치구 코드 불일치: ${byProvince[p]}');
    }
  });

  test('도(道)는 시군별로 midTaCode가 세분화되어 있다(도 전체 단일 코드 아님)', () {
    final byProvince = <String, Set<String>>{};
    for (final r in regions) {
      byProvince.putIfAbsent(r['province'] as String, () => {}).add(r['midTaCode'] as String);
    }
    // 시군이 여러 개인 도는 midTaCode도 2개 이상이어야 정밀화된 것.
    for (final p in ['경기도', '경상남도', '경상북도', '전라남도', '충청남도']) {
      expect(byProvince[p]!.length, greaterThan(1), reason: '$p 정밀화 안 됨(단일 코드)');
    }
  });
}
