class BBox {
  final double west, south, east, north;
  const BBox({required this.west, required this.south, required this.east, required this.north});

  factory BBox.fromJson(Map<String, dynamic> j) => BBox(
        west: (j['west'] as num).toDouble(),
        south: (j['south'] as num).toDouble(),
        east: (j['east'] as num).toDouble(),
        north: (j['north'] as num).toDouble(),
      );

  bool get isValid => west < east && south < north;
}

class LgaFeature {
  final String lgaId;
  final String lgaName;
  final String state;
  final Map<String, dynamic> geometry; // raw GeoJSON geometry

  const LgaFeature({
    required this.lgaId,
    required this.lgaName,
    required this.state,
    required this.geometry,
  });

  factory LgaFeature.fromJson(Map<String, dynamic> j) {
    final props = j['properties'] as Map<String, dynamic>;
    return LgaFeature(
      lgaId: props['lga_id'] as String,
      lgaName: props['lga_name'] as String,
      state: props['state'] as String,
      geometry: j['geometry'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'Feature',
        'properties': {'lga_id': lgaId, 'lga_name': lgaName, 'state': state},
        'geometry': geometry,
      };
}

class FeatureCollection {
  final List<LgaFeature> features;
  const FeatureCollection({required this.features});

  factory FeatureCollection.fromJson(Map<String, dynamic> j) => FeatureCollection(
        features: (j['features'] as List)
            .map((f) => LgaFeature.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
}
