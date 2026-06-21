import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:peters_simple_weather/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> addRegion(WidgetTester tester, String province, String district) async {
    await tester.tap(find.text('지역 추가'));
    await tester.pumpAndSettle();
    // 1단계 통합 검색: 시/군/구 바로 검색 → 결과 탭 시 즉시 추가
    await tester.enterText(find.byType(TextField), district.substring(0, 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text(district));
    await tester.pumpAndSettle();
  }

  testWidgets('지역을 추가하고(검색→선택→확정), 목록에 표시되고, 삭제할 수 있다', (tester) async {
    await tester.pumpWidget(ProviderScope(child: CleanWeatherApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('내 지역 관리'));
    await tester.pumpAndSettle();
    expect(find.text('내 지역'), findsOneWidget);

    await addRegion(tester, '서울특별시', '영등포구');
    expect(find.text('영등포구'), findsOneWidget);

    await addRegion(tester, '서울특별시', '강남구');
    expect(find.text('영등포구'), findsOneWidget);
    expect(find.text('강남구'), findsOneWidget);

    // 맨 위(첫) 지역에만 '대표 지역' 배지, 위젯 설정 버튼 노출
    expect(find.text('대표 지역'), findsOneWidget);
    expect(find.text('위젯 설정'), findsOneWidget);

    // 첫 지역 삭제
    await tester.tap(find.byKey(const ValueKey('delete_서울특별시/영등포구')));
    await tester.pumpAndSettle();

    expect(find.text('영등포구'), findsNothing);
    expect(find.text('강남구'), findsOneWidget);
    // 삭제 후 새 맨 위(강남구)가 대표 지역
    expect(find.text('대표 지역'), findsOneWidget);
  });
}
