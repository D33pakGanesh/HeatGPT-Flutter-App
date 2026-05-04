import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class ScaleBar extends StatefulWidget {
  final MapController mapController;
  const ScaleBar({super.key, required this.mapController});

  @override
  State<ScaleBar> createState() => _ScaleBarState();
}

class _ScaleBarState extends State<ScaleBar> {
  String _label = '';
  double _width = 80;

  @override
  void initState() {
    super.initState();
    widget.mapController.mapEventStream.listen((_) => _update());
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final camera = widget.mapController.camera;
    final lat = camera.center.latitude;
    final zoom = camera.zoom;
    final metersPerPixel =
        (156543.03392 * math.cos(lat * math.pi / 180)) / math.pow(2, zoom);
    const targetPx = 80.0;
    final meters = metersPerPixel * targetPx;
    final String label;
    if (meters >= 1000) {
      final km = (meters / 100).round() / 10;
      label = '$km km';
    } else {
      label = '${meters.round()} m';
    }
    setState(() { _label = label; _width = targetPx; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_label, style: const TextStyle(fontSize: 10, color: Color(0xFF6b7280))),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 8, color: const Color(0xFF1e293b)),
              Container(width: _width, height: 3, color: const Color(0xFF1e293b)),
              Container(width: 1, height: 8, color: const Color(0xFF1e293b)),
            ],
          ),
        ],
      ),
    );
  }
}
