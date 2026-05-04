import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/trend_point.dart';

class LstTrendChart extends StatelessWidget {
  final List<LstTrendPoint> data;
  const LstTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.lst))
        .toList();

    final minY = data.map((p) => p.lst).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = data.map((p) => p.lst).reduce((a, b) => a > b ? a : b) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Temperature Trend — per Landsat pass',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 2),
        const Text('Each point = mean LST for one satellite overpass (cloud < 20%)',
            style: TextStyle(fontSize: 11, color: Color(0xFF9ca3af))),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (data.length / 4).ceilToDouble().clamp(1, double.infinity),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return Text(data[i].date.substring(5), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFFef4444),
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFFef4444),
                      strokeWidth: 0,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final i = s.x.toInt();
                    final date = i < data.length ? data[i].date : '';
                    return LineTooltipItem('$date\n${s.y.toStringAsFixed(1)}°C',
                        const TextStyle(fontSize: 11, color: Colors.white));
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
