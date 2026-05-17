import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drinking_tracker/home_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP');
  });

  testWidgets('起動時にカレンダータブが表示される', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('休肝日・飲酒記録'), findsOneWidget);
    expect(find.text('カレンダー'), findsOneWidget);
    expect(find.text('一覧'), findsOneWidget);
    expect(find.text('グラフ'), findsOneWidget);
    expect(find.text('連続休肝日'), findsOneWidget);
    expect(find.text('日'), findsWidgets);
    expect(find.text('月'), findsWidgets);
  });

  testWidgets('一覧タブで空メッセージが出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('一覧'));
    await tester.pumpAndSettle();

    expect(find.text('まだ記録がありません'), findsOneWidget);
  });

  testWidgets('グラフタブに切り替えると凡例が出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('グラフ'));
    await tester.pumpAndSettle();

    expect(find.text('直近 14 日の飲酒量 (ml)'), findsOneWidget);
    expect(find.text('飲酒'), findsOneWidget);
  });
}
