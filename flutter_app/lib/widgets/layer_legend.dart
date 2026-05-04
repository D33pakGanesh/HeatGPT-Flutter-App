import 'package:flutter/material.dart';

const _lstPalette = [
  (color: Color(0xFF313695), label: '≤20°C'),
  (color: Color(0xFF4575b4), label: '25°C'),
  (color: Color(0xFF74add1), label: '30°C'),
  (color: Color(0xFFabd9e9), label: '35°C'),
  (color: Color(0xFFfee090), label: '40°C'),
  (color: Color(0xFFfdae61), label: '45°C'),
  (color: Color(0xFFf46d43), label: '50°C'),
  (color: Color(0xFFd73027), label: '55°C'),
  (color: Color(0xFFa50026), label: '>55°C'),
];

const _ndviPalette = [
  (color: Color(0xFFd73027), label: '-0.2'),
  (color: Color(0xFFfee090), label: '0.0'),
  (color: Color(0xFFffffbf), label: '0.2'),
  (color: Color(0xFFd9ef8b), label: '0.4'),
  (color: Color(0xFF91cf60), label: '0.6'),
  (color: Color(0xFF1a9850), label: '0.8'),
];

class LayerLegend extends StatelessWidget {
  final String? layerType; // 'lst' | 'ndvi' | null
  const LayerLegend({super.key, this.layerType});

  @override
  Widget build(BuildContext context) {
    if (layerType == null) return const SizedBox.shrink();
    final palette = layerType == 'ndvi' ? _ndviPalette : _lstPalette;
    final title = layerType == 'ndvi' ? 'NDVI' : 'LST (°C)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1e293b))),
          const SizedBox(height: 6),
          ...palette.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 16, height: 12, decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(e.label, style: const TextStyle(fontSize: 10, color: Color(0xFF374151))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
