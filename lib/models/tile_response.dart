import 'lga_feature.dart';

class TileResponse {
  final String tileUrl;
  final BBox? bbox;

  const TileResponse({required this.tileUrl, this.bbox});

  factory TileResponse.fromJson(Map<String, dynamic> j) => TileResponse(
        tileUrl: j['tileUrl'] as String,
        bbox: j['bbox'] != null ? BBox.fromJson(j['bbox'] as Map<String, dynamic>) : null,
      );
}
