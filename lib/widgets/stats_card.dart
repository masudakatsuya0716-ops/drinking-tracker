import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int restDayStreak;
  final int last7DaysMl;
  final int monthlyRestDays;

  const StatsCard({
    super.key,
    required this.restDayStreak,
    required this.last7DaysMl,
    required this.monthlyRestDays,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            _Stat(label: '連続休肝日', value: '$restDayStreak', unit: '日'),
            _Divider(),
            _Stat(label: '直近 7 日', value: '$last7DaysMl', unit: 'ml'),
            _Divider(),
            _Stat(label: '今月の休肝日', value: '$monthlyRestDays', unit: '日'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _Stat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).hintColor)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).dividerColor,
    );
  }
}
