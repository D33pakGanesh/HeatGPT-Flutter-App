import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/lga_feature.dart';
import '../providers/providers.dart';

/// Builds a list of [LatLng] rings from a GeoJSON geometry map.
List<List<LatLng>> _ringsFromGeometry(Map<String, dynamic> geom) {
  final type = geom['type'] as String;
  final coords = geom['coordinates'];
  final rings = <List<LatLng>>[];

  List<LatLng> toRing(List coords) =>
      coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

  if (type == 'Polygon') {
    for (final ring in coords as List) rings.add(toRing(ring as List));
  } else if (type == 'MultiPolygon') {
    for (final poly in coords as List) {
      for (final ring in poly as List) rings.add(toRing(ring as List));
    }
  }
  return rings;
}

/// A [CustomPainter] that draws a satellite PNG clipped to the LGA polygon shape.
class SatelliteOverlayPainter extends CustomPainter {
  final ui.Image image;
  final List<List<LatLng>> rings;
  final BBox bbox;
  final MapCamera camera;

  const SatelliteOverlayPainter({
    required this.image,
    required this.rings,
    required this.bbox,
    required this.camera,
  });

  Offset _project(LatLng ll) {
    final pt = camera.latLngToScreenPoint(ll);
    return Offset(pt.x, pt.y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Build clip path from polygon rings
    final clipPath = ui.Path();
    for (final ring in rings) {
      if (ring.isEmpty) continue;
      final first = _project(ring.first);
      clipPath.moveTo(first.dx, first.dy);
      for (final ll in ring.skip(1)) {
        final pt = _project(ll);
        clipPath.lineTo(pt.dx, pt.dy);
      }
      clipPath.close();
    }

    canvas.save();
    canvas.clipPath(clipPath);

    // Compute image destination rect from bbox
    final tl = _project(LatLng(bbox.north, bbox.west));
    final br = _project(LatLng(bbox.south, bbox.east));
    final dst = Rect.fromLTRB(tl.dx, tl.dy, br.dx, br.dy);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final paint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SatelliteOverlayPainter old) =>
      old.image != image || old.camera != camera;
}

/// Widget that loads the satellite tile image and renders it clipped to the LGA polygon.
class SatelliteOverlayWidget extends StatefulWidget {
  final TileLayerState tileLayer;
  final LgaFeature lgaFeature;
  final MapCamera camera;

  const SatelliteOverlayWidget({
    super.key,
    required this.tileLayer,
    required this.lgaFeature,
    required this.camera,
  });

  @override
  State<SatelliteOverlayWidget> createState() => _SatelliteOverlayWidgetState();
}

class _SatelliteOverlayWidgetState extends State<SatelliteOverlayWidget> {
  ui.Image? _image;
  String? _loadedUrl;

  @override
  void didUpdateWidget(SatelliteOverlayWidget old) {
    super.didUpdateWidget(old);
    if (widget.tileLayer.tileUrl != _loadedUrl) _loadImage();
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final url = widget.tileLayer.tileUrl;
    final provider = NetworkImage(url);
    final stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) setState(() { _image = info.image; _loadedUrl = url; });
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null || widget.tileLayer.bbox == null) return const SizedBox.shrink();
    final rings = _ringsFromGeometry(widget.lgaFeature.geometry);
    return CustomPaint(
      painter: SatelliteOverlayPainter(
        image: _image!,
        rings: rings,
        bbox: widget.tileLayer.bbox!,
        camera: widget.camera,
      ),
    );
  }
}
