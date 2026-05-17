import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../stats.dart';

class ChartView extends StatelessWidget {
  final List<DailyAggregate> aggregates;
  const ChartView({super.key, required this.aggregates});

  @override
  Widget build(BuildContext context) {
    if (aggregates.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    final maxValue =
        aggregates.fold<int>(0, (m, d) => d.totalMl > m ? d.totalMl : m);
    final yMax = maxValue <= 0 ? 1000.0 : (maxValue * 1.25);

    return BarChart(
      BarChartData(
        maxY: yMax,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) {
              final i = group.x;
              final a = aggregates[i];
              final label = a.isRestDay
                  ? '休肝日'
                  : (a.hasRecord ? '${a.totalMl} ml' : '記録なし');
              return BarTooltipItem(
                '${a.date.month}/${a.date.day}\n$label',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        barGroups: [
          for (int i = 0; i < aggregates.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: aggregates[i].isRestDay
                      ? yMax * 0.05
                      : aggregates[i].totalMl.toDouble(),
                  color: aggregates[i].isRestDay
                      ? Colors.green
                      : (aggregates[i].hasRecord
                          ? Colors.orange
                          : Colors.grey.shade300),
                  width: 12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yMax / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > yMax) return const SizedBox();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= aggregates.length) return const SizedBox();
                final d = aggregates[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yMax / 4,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
