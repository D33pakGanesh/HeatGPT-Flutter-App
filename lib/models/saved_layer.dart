class SavedLayer {
  final int id;
  final String layerType;
  final String dateRangeStart;
  final String dateRangeEnd;
  final String tileUrl;
  final double? avgLstCelsius;
  final double? avgNdvi;
  final double? uhiIntensity;
  final String exportedAt;

  const SavedLayer({
    required this.id,
    required this.layerType,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.tileUrl,
    this.avgLstCelsius,
    this.avgNdvi,
    this.uhiIntensity,
    required this.exportedAt,
  });

  factory SavedLayer.fromJson(Map<String, dynamic> j) => SavedLayer(
        id: j['id'] as int,
        layerType: j['layer_type'] as String,
        dateRangeStart: j['date_range_start'] as String,
        dateRangeEnd: j['date_range_end'] as String,
        tileUrl: j['tile_url'] as String,
        avgLstCelsius: j['avg_lst_celsius'] != null ? (j['avg_lst_celsius'] as num).toDouble() : null,
        avgNdvi: j['avg_ndvi'] != null ? (j['avg_ndvi'] as num).toDouble() : null,
        uhiIntensity: j['uhi_intensity'] != null ? (j['uhi_intensity'] as num).toDouble() : null,
        exportedAt: j['exported_at'] as String,
      );
}
