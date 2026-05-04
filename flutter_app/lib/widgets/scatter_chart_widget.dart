import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/trend_point.dart';

class LstNdviScatterChart extends StatelessWidget {
  final List<ScatterPoint> data;
  const LstNdviScatterChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();

    final spots = data
        .map((p) => ScatterSpot(p.lst, p.ndvi, dotPainter: FlDotCirclePainter(
              radius: 5,
              color: const Color(0xFFef4444).withOpacity(0.8),
              strokeWidth: 0,
            )))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LST vs NDVI Scatter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 2),
        const Text('Each point = one satellite overpass. Higher NDVI = cooler temps expected.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9ca3af))),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: spots,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('NDVI', style: TextStyle(fontSize: 11)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text('LST (°C)', style: TextStyle(fontSize: 11)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              scatterTouchData: ScatterTouchData(
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipItems: (spot) {
                    final match = data.where((p) => (p.lst - spot.x).abs() < 0.01 && (p.ndvi - spot.y).abs() < 0.001).firstOrNull;
                    return ScatterTooltipItem(
                      '${match?.date ?? ''}\nLST: ${spot.x.toStringAsFixed(1)}°C\nNDVI: ${spot.y.toStringAsFixed(3)}',
                      textStyle: const TextStyle(fontSize: 11, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
