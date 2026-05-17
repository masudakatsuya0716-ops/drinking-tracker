import 'package:drinking_tracker/drink_record.dart';
import 'package:drinking_tracker/stats.dart';
import 'package:flutter_test/flutter_test.dart';

DrinkRecord _rec({
  required String id,
  required DateTime date,
  int amountMl = 0,
  DrinkType type = DrinkType.beer,
  bool isRestDay = false,
}) {
  return DrinkRecord(
    id: id,
    date: date,
    amountMl: amountMl,
    type: type,
    isRestDay: isRestDay,
  );
}

void main() {
  group('restDayStreak', () {
    test('空ならば 0', () {
      expect(restDayStreak([]), 0);
    });

    test('最新が飲酒ならば 0', () {
      final records = [
        _rec(id: '1', date: DateTime(2026, 5, 17), amountMl: 500),
        _rec(id: '2', date: DateTime(2026, 5, 16), isRestDay: true),
      ];
      expect(restDayStreak(records), 0);
    });

    test('連続休肝日を数える', () {
      final records = [
        _rec(id: '1', date: DateTime(2026, 5, 18), isRestDay: true),
        _rec(id: '2', date: DateTime(2026, 5, 17), isRestDay: true),
        _rec(id: '3', date: DateTime(2026, 5, 16), isRestDay: true),
        _rec(id: '4', date: DateTime(2026, 5, 15), amountMl: 500),
      ];
      expect(restDayStreak(records), 3);
    });

    test('日付の歯抜けで止まる', () {
      final records = [
        _rec(id: '1', date: DateTime(2026, 5, 18), isRestDay: true),
        _rec(id: '3', date: DateTime(2026, 5, 16), isRestDay: true),
      ];
      expect(restDayStreak(records), 1);
    });
  });

  group('last7DaysTotalMl', () {
    test('直近 7 日のみ合算', () {
      final now = DateTime(2026, 5, 18, 12, 0);
      final records = [
        _rec(id: '1', date: DateTime(2026, 5, 18), amountMl: 350),
        _rec(id: '2', date: DateTime(2026, 5, 17), amountMl: 500),
        _rec(id: '3', date: DateTime(2026, 5, 12), amountMl: 200),
        _rec(id: '4', date: DateTime(2026, 5, 11), amountMl: 999),
      ];
      expect(last7DaysTotalMl(records, now: now), 1050);
    });
  });

  group('monthlyRestDays', () {
    test('同月の休肝日を重複なく数える', () {
      final now = DateTime(2026, 5, 18);
      final records = [
        _rec(id: '1', date: DateTime(2026, 5, 17), isRestDay: true),
        _rec(id: '2', date: DateTime(2026, 5, 17), isRestDay: true),
        _rec(id: '3', date: DateTime(2026, 5, 10), isRestDay: true),
        _rec(id: '4', date: DateTime(2026, 4, 30), isRestDay: true),
      ];
      expect(monthlyRestDays(records, now: now), 2);
    });
  });

  group('dailyAggregates', () {
    test('14 日分の枠を埋める', () {
      final now = DateTime(2026, 5, 18);
      final records = [
        _rec(id: '1', date: DateTime(2026, 5, 18), amountMl: 350),
        _rec(id: '2', date: DateTime(2026, 5, 17), isRestDay: true),
      ];
      final result = dailyAggregates(records, 14, now: now);
      expect(result.length, 14);
      expect(result.last.totalMl, 350);
      expect(result.last.hasRecord, true);
      expect(result[12].isRestDay, true);
      expect(result.first.hasRecord, false);
    });
  });
}
