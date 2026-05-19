import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'drink_record.dart';
import 'drink_repository.dart';
import 'stats.dart';
import 'theme.dart';
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
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('SOBR.'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '記録'),
              Tab(text: '一覧'),
              Tab(text: 'グラフ'),
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
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 22,
          right: 22,
          top: 8,
        ),
        child: SingleChildScrollView(
          child: DrinkForm(
            initial: existing,
            defaultDate: defaultDate,
            onSubmitted: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    },
  );
}

class _PageHeader extends StatelessWidget {
  final String overline;
  final String title;
  final String? subtitle;

  const _PageHeader({
    required this.overline,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _PageHeader(
          overline: '記録',
          title: '日付を選んで記録',
          subtitle: 'カレンダーから日付をタップして、\nその日の状況を記録できます。',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: HeroStatsCard(
            restDayStreak: widget.streak,
            last7DaysMl: widget.last7DaysMl,
            monthlyRestDays: widget.monthlyRest,
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 10),
          child: Text(
            'カレンダーの色について',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: CalendarLegend(),
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
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _PageHeader(
          overline: '一覧',
          title: 'すべての記録',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: HeroStatsCard(
            restDayStreak: streak,
            last7DaysMl: last7DaysMl,
            monthlyRestDays: monthlyRest,
          ),
        ),
        const SizedBox(height: 22),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'まだ記録がありません',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < sorted.length; i++) ...[
                    if (i > 0)
                      const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16),
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
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _PageHeader(
          overline: 'グラフ',
          title: '直近 14 日',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: HeroStatsCard(
            restDayStreak: streak,
            last7DaysMl: last7DaysMl,
            monthlyRestDays: monthlyRest,
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '日次の飲酒量 (ml)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 240,
                  child: ChartView(aggregates: aggregates),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _LegendDot(color: AppColors.danger, label: '飲んだ'),
                    SizedBox(width: 18),
                    _LegendDot(color: AppColors.primary, label: '飲まず'),
                    SizedBox(width: 18),
                    _LegendDot(color: AppColors.surfaceAlt, label: '記録なし'),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
