import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/lga_feature.dart';
import '../providers/providers.dart';
import '../widgets/layer_legend.dart';
import '../widgets/north_arrow.dart';
import '../widgets/pdf_export_button.dart';
import '../widgets/satellite_overlay.dart';
import '../widgets/scale_bar.dart';
import '../widgets/side_panel.dart';
import '../widgets/symbology_panel.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _mapKey = GlobalKey();

  // Not const — LatLngBounds constructor is not const
  static final _australiaBounds = LatLngBounds(
    const LatLng(-44.0, 112.0),
    const LatLng(-10.0, 154.0),
  );

  void _onLgaTap(LgaFeature feature) {
    ref.read(selectedLgaIdProvider.notifier).state = feature.lgaId;
    ref.read(activeTileLayerProvider.notifier).state = null;

    final bounds = _boundsFromGeometry(feature.geometry);
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
          maxZoom: 13,
        ),
      );
    }
  }

  LatLngBounds? _boundsFromGeometry(Map<String, dynamic> geom) {
    final type = geom['type'] as String;
    final coords = geom['coordinates'];
    final points = <LatLng>[];

    void addCoords(List c) {
      for (final pt in c) {
        if (pt is List && pt.length >= 2) {
          points.add(LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble()));
        }
      }
    }

    if (type == 'Polygon') {
      for (final ring in coords as List) addCoords(ring as List);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords as List) {
        for (final ring in poly as List) addCoords(ring as List);
      }
    }

    if (points.isEmpty) return null;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  @override
  Widget build(BuildContext context) {
    final lgasAsync = ref.watch(lgasProvider);
    final selectedFeature = ref.watch(selectedLgaFeatureProvider);
    final tileLayer = ref.watch(activeTileLayerProvider);
    final sym = ref.watch(symbologyProvider);
    final panelOpen = ref.watch(sidePanelOpenProvider);

    final effectiveFillOpacity = tileLayer != null ? 0.05 : sym.fillOpacity;
    final effectiveStrokeWeight = tileLayer != null ? 0.3 : sym.strokeWeight;
    final rightOffset = panelOpen ? 376.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          RepaintBoundary(
            key: _mapKey,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(bounds: _australiaBounds),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPos, latLng) {
                  // Handle polygon tap via coordinate check
                  final fc = lgasAsync.valueOrNull;
                  if (fc == null) return;
                  for (final f in fc.features) {
                    if (_containsPoint(f.geometry, latLng)) {
                      _onLgaTap(f);
                      return;
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.heatgpt.heatgpt',
                ),

                // LGA polygon layer
                lgasAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (fc) => PolygonLayer(
                    polygons: fc.features.map((f) {
                      final rings = _ringsFromGeometry(f.geometry);
                      if (rings.isEmpty) return null;
                      return Polygon(
                        points: rings.first,
                        holePointsList: rings.length > 1 ? rings.sublist(1) : [],
                        color: Color(sym.fillColor).withOpacity(effectiveFillOpacity),
                        borderColor: Color(sym.strokeColor),
                        borderStrokeWidth: effectiveStrokeWeight,
                      );
                    }).whereType<Polygon>().toList(),
                    polygonCulling: true,
                  ),
                ),

                // Satellite overlay
                if (tileLayer != null && selectedFeature != null)
                  _SatelliteLayer(tileLayer: tileLayer, feature: selectedFeature),
              ],
            ),
          ),

          // ── Map controls ─────────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 16, right: rightOffset,
            child: const NorthArrow(),
          ),
          Positioned(
            bottom: 28, left: 16,
            child: ScaleBar(mapController: _mapController),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: 28, right: rightOffset,
            child: LayerLegend(layerType: tileLayer?.type),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: 90, right: rightOffset,
            child: PdfExportButton(
              mapKey: _mapKey,
              lgaName: ref.watch(selectedLgaFeatureProvider)?.lgaName,
            ),
          ),

          // ── Symbology panel ───────────────────────────────────────────────
          const SymbologyPanel(),

          // ── Side panel ────────────────────────────────────────────────────
          const SidePanel(),

          // ── Error banner ──────────────────────────────────────────────────
          if (lgasAsync.hasError)
            Positioned(
              top: 16, left: 60, right: 60,
              child: Material(
                color: const Color(0xFFfee2e2),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Failed to load LGA boundaries',
                    style: TextStyle(color: Color(0xFFdc2626), fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _containsPoint(Map<String, dynamic> geom, LatLng point) {
    final type = geom['type'] as String;
    final coords = geom['coordinates'];
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    void scan(List ring) {
      for (final c in ring) {
        if (c is List && c.length >= 2) {
          final lat = (c[1] as num).toDouble();
          final lng = (c[0] as num).toDouble();
          if (lat < minLat) minLat = lat;
          if (lat > maxLat) maxLat = lat;
          if (lng < minLng) minLng = lng;
          if (lng > maxLng) maxLng = lng;
        }
      }
    }

    if (type == 'Polygon') {
      for (final ring in coords as List) scan(ring as List);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords as List) {
        for (final ring in poly as List) scan(ring as List);
      }
    }

    return point.latitude >= minLat && point.latitude <= maxLat &&
        point.longitude >= minLng && point.longitude <= maxLng;
  }
}

// ─── Satellite overlay layer wrapper ─────────────────────────────────────────

class _SatelliteLayer extends StatelessWidget {
  final TileLayerState tileLayer;
  final LgaFeature feature;
  const _SatelliteLayer({required this.tileLayer, required this.feature});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return SatelliteOverlayWidget(
      tileLayer: tileLayer,
      lgaFeature: feature,
      camera: camera,
    );
  }
}

// ─── Helper ──────────────────────────────────────────────────────────────────

List<List<LatLng>> _ringsFromGeometry(Map<String, dynamic> geom) {
  final type = geom['type'] as String;
  final coords = geom['coordinates'];
  final rings = <List<LatLng>>[];

  List<LatLng> toRing(List c) =>
      c.map((pt) => LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble())).toList();

  if (type == 'Polygon') {
    for (final ring in coords as List) rings.add(toRing(ring as List));
  } else if (type == 'MultiPolygon') {
    for (final poly in coords as List) {
      for (final ring in poly as List) rings.add(toRing(ring as List));
    }
  }
  return rings;
}
