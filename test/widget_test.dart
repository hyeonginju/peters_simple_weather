import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:peters_simple_weather/app.dart';

void main() {
  testWidgets('App boots and shows the empty-state home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(ProviderScope(child: CleanWeatherApp()));
    await tester.pumpAndSettle();

    expect(find.text('아직 추가한 지역이 없어요.'), findsOneWidget);
  });
}
