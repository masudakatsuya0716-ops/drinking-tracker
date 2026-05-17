import 'drink_record.dart';

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

int restDayStreak(List<DrinkRecord> records) {
  if (records.isEmpty) return 0;

  final byDate = <DateTime, bool>{};
  for (final r in records) {
    final d = _midnight(r.date);
    if (byDate.containsKey(d)) {
      byDate[d] = byDate[d]! && r.isRestDay;
    } else {
      byDate[d] = r.isRestDay;
    }
  }

  final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
  int streak = 0;
  DateTime? expected;
  for (final d in dates) {
    if (expected != null && d != expected) break;
    if (!byDate[d]!) break;
    streak++;
    expected = DateTime(d.year, d.month, d.day - 1);
  }
  return streak;
}

int last7DaysTotalMl(List<DrinkRecord> records, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final start = _midnight(n).subtract(const Duration(days: 6));
  return records
      .where((r) => !r.date.isBefore(start))
      .fold<int>(0, (s, r) => s + r.amountMl);
}

int monthlyRestDays(List<DrinkRecord> records, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final restDates = <DateTime>{};
  for (final r in records) {
    if (r.isRestDay &&
        r.date.year == n.year &&
        r.date.month == n.month) {
      restDates.add(_midnight(r.date));
    }
  }
  return restDates.length;
}

class DailyAggregate {
  final DateTime date;
  final int totalMl;
  final bool isRestDay;
  final bool hasRecord;
  const DailyAggregate({
    required this.date,
    required this.totalMl,
    required this.isRestDay,
    required this.hasRecord,
  });
}

List<DailyAggregate> dailyAggregates(
  List<DrinkRecord> records,
  int days, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = _midnight(n);
  final byDate = <DateTime, List<DrinkRecord>>{};
  for (final r in records) {
    byDate.putIfAbsent(_midnight(r.date), () => []).add(r);
  }

  final result = <DailyAggregate>[];
  for (int i = days - 1; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    final rs = byDate[d] ?? const <DrinkRecord>[];
    final totalMl = rs.fold<int>(0, (s, r) => s + r.amountMl);
    final isRest = rs.isNotEmpty && rs.every((r) => r.isRestDay);
    result.add(DailyAggregate(
      date: d,
      totalMl: totalMl,
      isRestDay: isRest,
      hasRecord: rs.isNotEmpty,
    ));
  }
  return result;
}
