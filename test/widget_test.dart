import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drinking_tracker/home_screen.dart';
import 'package:drinking_tracker/theme.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP');
  });

  Widget buildApp() => ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(),
        ),
      );

  testWidgets('起動時に SOBR. タイトルとタブが出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('SOBR.'), findsOneWidget);
    expect(find.text('記録'), findsWidgets);
    expect(find.text('一覧'), findsWidgets);
    expect(find.text('グラフ'), findsWidgets);
    expect(find.text('連続して飲まなかった日'), findsOneWidget);
  });

  testWidgets('一覧タブで空メッセージが出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('一覧').first);
    await tester.pumpAndSettle();

    expect(find.text('まだ記録がありません'), findsOneWidget);
  });

  testWidgets('グラフタブに切り替えると凡例が出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('グラフ').first);
    await tester.pumpAndSettle();

    expect(find.text('日次の飲酒量 (ml)'), findsOneWidget);
    expect(find.text('飲んだ'), findsOneWidget);
    expect(find.text('飲まず'), findsOneWidget);
  });
}
