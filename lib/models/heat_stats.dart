class HeatStats {
  final String lgaId;
  final String lgaName;
  final double avgLstCelsius;
  final double avgNdvi;
  final double uhiIntensity;
  final String dataSource;
  final String dateRangeStart;
  final String dateRangeEnd;
  final String processedAt;
  final bool stale;

  const HeatStats({
    required this.lgaId,
    required this.lgaName,
    required this.avgLstCelsius,
    required this.avgNdvi,
    required this.uhiIntensity,
    required this.dataSource,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.processedAt,
    this.stale = false,
  });

  factory HeatStats.fromJson(Map<String, dynamic> j) => HeatStats(
        lgaId: j['lgaId'] as String,
        lgaName: j['lgaName'] as String,
        avgLstCelsius: (j['avgLstCelsius'] as num).toDouble(),
        avgNdvi: (j['avgNdvi'] as num).toDouble(),
        uhiIntensity: (j['uhiIntensity'] as num).toDouble(),
        dataSource: j['dataSource'] as String,
        dateRangeStart: j['dateRangeStart'] as String,
        dateRangeEnd: j['dateRangeEnd'] as String,
        processedAt: j['processedAt'] as String,
        stale: j['stale'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'lgaId': lgaId,
        'lgaName': lgaName,
        'avgLstCelsius': avgLstCelsius,
        'avgNdvi': avgNdvi,
        'uhiIntensity': uhiIntensity,
        'dataSource': dataSource,
        'dateRangeStart': dateRangeStart,
        'dateRangeEnd': dateRangeEnd,
        'processedAt': processedAt,
        if (stale) 'stale': true,
      };
}
