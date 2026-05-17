import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'drink_record.dart';
import 'drink_repository.dart';
import 'stats.dart';
import 'widgets/chart_view.dart';
import 'widgets/drink_form.dart';
import 'widgets/month_calendar.dart';
import 'widgets/record_tile.dart';
import 'widgets/stats_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(drinkRecordsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('休肝日・飲酒記録'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
              Tab(icon: Icon(Icons.list), text: '一覧'),
              Tab(icon: Icon(Icons.bar_chart), text: 'グラフ'),
            ],
          ),
        ),
        body: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('読み込みエラー: $e')),
          data: (records) {
            final streak = restDayStreak(records);
            final weekly = last7DaysTotalMl(records);
            final monthlyRest = monthlyRestDays(records);

            return TabBarView(
              children: [
                _CalendarTab(
                  records: records,
                  streak: streak,
                  last7DaysMl: weekly,
                  monthlyRest: monthlyRest,
                ),
                _ListTab(
                  records: records,
                  streak: streak,
                  last7DaysMl: weekly,
                  monthlyRest: monthlyRest,
                ),
                _ChartTab(
                  records: records,
                  streak: streak,
                  last7DaysMl: weekly,
                  monthlyRest: monthlyRest,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Map<DateTime, DrinkRecord> _byDateLatest(List<DrinkRecord> records) {
  final map = <DateTime, DrinkRecord>{};
  for (final r in records) {
    final d = DateTime(r.date.year, r.date.month, r.date.day);
    final existing = map[d];
    if (existing == null || r.id.compareTo(existing.id) > 0) {
      map[d] = r;
    }
  }
  return map;
}

Future<void> _showDaySheet(
  BuildContext context, {
  DrinkRecord? existing,
  DateTime? defaultDate,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 8,
        ),
        child: SingleChildScrollView(
          child: DrinkForm(
            initial: existing,
            defaultDate: defaultDate,
            showDateLabel: false,
            onSubmitted: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    },
  );
}

class _CalendarTab extends StatefulWidget {
  final List<DrinkRecord> records;
  final int streak;
  final int last7DaysMl;
  final int monthlyRest;

  const _CalendarTab({
    required this.records,
    required this.streak,
    required this.last7DaysMl,
    required this.monthlyRest,
  });

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _prev() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _next() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final byDate = _byDateLatest(widget.records);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        StatsCard(
          restDayStreak: widget.streak,
          last7DaysMl: widget.last7DaysMl,
          monthlyRestDays: widget.monthlyRest,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: MonthCalendar(
              month: _displayedMonth,
              recordsByDate: byDate,
              onPrev: _prev,
              onNext: _next,
              onTapDay: (date, existing) => _showDaySheet(
                context,
                existing: existing,
                defaultDate: existing == null ? date : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '日付をタップすると、その日の記録を追加・編集できます',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _ListTab extends StatelessWidget {
  final List<DrinkRecord> records;
  final int streak;
  final int last7DaysMl;
  final int monthlyRest;

  const _ListTab({
    required this.records,
    required this.streak,
    required this.last7DaysMl,
    required this.monthlyRest,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        StatsCard(
          restDayStreak: streak,
          last7DaysMl: last7DaysMl,
          monthlyRestDays: monthlyRest,
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('すべての記録',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('まだ記録がありません')),
          )
        else
          Card(
            child: Column(
              children: [
                for (int i = 0; i < sorted.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  RecordTile(
                    record: sorted[i],
                    onEdit: () => _showDaySheet(
                      context,
                      existing: sorted[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartTab extends StatelessWidget {
  final List<DrinkRecord> records;
  final int streak;
  final int last7DaysMl;
  final int monthlyRest;

  const _ChartTab({
    required this.records,
    required this.streak,
    required this.last7DaysMl,
    required this.monthlyRest,
  });

  @override
  Widget build(BuildContext context) {
    final aggregates = dailyAggregates(records, 14);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        StatsCard(
          restDayStreak: streak,
          last7DaysMl: last7DaysMl,
          monthlyRestDays: monthlyRest,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('直近 14 日の飲酒量 (ml)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ChartView(aggregates: aggregates),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LegendItem(color: Colors.orange, label: '飲酒'),
                    const SizedBox(width: 16),
                    const _LegendItem(color: Colors.green, label: '休肝日'),
                    const SizedBox(width: 16),
                    _LegendItem(
                        color: Colors.grey.shade400, label: '記録なし'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
