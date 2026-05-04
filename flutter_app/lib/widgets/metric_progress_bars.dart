import 'package:flutter/material.dart';

class MetricProgressBars extends StatelessWidget {
  final double avgLstCelsius;
  final double avgNdvi;
  const MetricProgressBars({super.key, required this.avgLstCelsius, required this.avgNdvi});

  @override
  Widget build(BuildContext context) {
    final tempFill = (avgLstCelsius / 70).clamp(0.0, 1.0);
    final vegFill = ((avgNdvi + 1) / 2).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NDVI vs LST', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 12),
          _Bar(label: 'Temperature', value: '${avgLstCelsius.toStringAsFixed(1)}°C', fill: tempFill, color: const Color(0xFFef4444)),
          const SizedBox(height: 10),
          _Bar(label: 'Vegetation', value: avgNdvi.toStringAsFixed(3), fill: vegFill, color: const Color(0xFF16a34a)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final String value;
  final double fill;
  final Color color;
  const _Bar({required this.label, required this.value, required this.fill, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
            Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (ctx, constraints) {
          return Stack(
            children: [
              Container(height: 8, width: constraints.maxWidth, decoration: BoxDecoration(color: const Color(0xFFe5e7eb), borderRadius: BorderRadius.circular(4))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 8,
                width: constraints.maxWidth * fill,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          );
        }),
      ],
    );
  }
}
