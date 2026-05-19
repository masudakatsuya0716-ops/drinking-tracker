import 'package:flutter/material.dart';

import '../drink_record.dart';
import '../theme.dart';

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
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _MonthNavButton(
                label: '← 前月',
                onPressed: onPrev,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${month.year}年 ${month.month}月',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                ),
              ),
              _MonthNavButton(
                label: '次月 →',
                onPressed: onNext,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                child: Row(
                  children: const [
                    _WeekdayLabel(label: '日', color: AppColors.danger),
                    _WeekdayLabel(label: '月'),
                    _WeekdayLabel(label: '火'),
                    _WeekdayLabel(label: '水'),
                    _WeekdayLabel(label: '木'),
                    _WeekdayLabel(label: '金'),
                    _WeekdayLabel(label: '土', color: AppColors.primary),
                  ],
                ),
              ),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1 / 1.1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                children: cells,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _MonthNavButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _WeekdayLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.inkSoft,
          ),
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
    Color bg;
    Color textColor;

    if (isFuture) {
      bg = Colors.transparent;
      textColor = AppColors.inkMuted;
    } else if (record == null) {
      bg = AppColors.surfaceAlt;
      final weekday = date.weekday % 7;
      if (weekday == 0) {
        textColor = AppColors.danger;
      } else if (weekday == 6) {
        textColor = AppColors.primary;
      } else {
        textColor = AppColors.ink;
      }
    } else if (record!.isRestDay) {
      bg = AppColors.primary;
      textColor = AppColors.primaryInk;
    } else {
      bg = AppColors.danger;
      textColor = Colors.white;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isFuture ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                  height: 1,
                ),
              ),
              if (isToday && record == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '今日',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _LegendRow(
        bg: AppColors.primary,
        ink: AppColors.primaryInk,
        title: '飲まなかった日',
        sub: '休肝を守れた日',
      ),
      _LegendRow(
        bg: AppColors.danger,
        ink: Colors.white,
        title: '飲んだ日',
        sub: '正直に記録した日',
      ),
      _LegendRow(
        bg: AppColors.surfaceAlt,
        ink: AppColors.inkSoft,
        title: '未記入',
        sub: 'タップして記録できます',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  color: AppColors.border,
                  thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: rows[i].bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '17',
                      style: TextStyle(
                        color: rows[i].ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].sub,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow {
  final Color bg;
  final Color ink;
  final String title;
  final String sub;
  const _LegendRow({
    required this.bg,
    required this.ink,
    required this.title,
    required this.sub,
  });
}
