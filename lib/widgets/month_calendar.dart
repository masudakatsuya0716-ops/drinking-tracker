import 'package:flutter/material.dart';

import '../drink_record.dart';

class MonthCalendar extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, DrinkRecord> recordsByDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime date, DrinkRecord? existing) onTapDay;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.recordsByDate,
    required this.onPrev,
    required this.onNext,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(month.year, month.month);
    final weekdayOfFirst = firstOfMonth.weekday % 7;

    final cells = <Widget>[];
    for (int i = 0; i < weekdayOfFirst; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final record = recordsByDate[date];
      cells.add(_DayCell(
        date: date,
        record: record,
        isToday: date == today,
        isFuture: date.isAfter(today),
        onTap: () => onTapDay(date, record),
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
              tooltip: '前の月',
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${month.year}年 ${month.month}月',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              tooltip: '次の月',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: const [
            _WeekdayHeader(label: '日', color: Color(0xFFE57373)),
            _WeekdayHeader(label: '月'),
            _WeekdayHeader(label: '火'),
            _WeekdayHeader(label: '水'),
            _WeekdayHeader(label: '木'),
            _WeekdayHeader(label: '金'),
            _WeekdayHeader(label: '土', color: Color(0xFF64B5F6)),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          children: cells,
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  final Color? color;
  const _WeekdayHeader({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final DrinkRecord? record;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.record,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    if (record != null) {
      bgColor = record!.isRestDay
          ? Colors.green.shade50
          : Colors.orange.shade50;
    }

    final weekday = date.weekday % 7;
    Color dateColor = Theme.of(context).colorScheme.onSurface;
    if (isFuture) {
      dateColor = Theme.of(context).disabledColor;
    } else if (weekday == 0) {
      dateColor = const Color(0xFFE57373);
    } else if (weekday == 6) {
      dateColor = const Color(0xFF64B5F6);
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: isFuture ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2)
                : Border.all(
                    color: Theme.of(context).dividerColor, width: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: dateColor,
                ),
              ),
              if (record != null)
                if (record!.isRestDay)
                  const Icon(Icons.local_florist,
                      size: 12, color: Colors.green)
                else
                  Text(
                    '${record!.amountMl}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
