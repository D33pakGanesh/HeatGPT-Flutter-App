class LstTrendPoint {
  final String date;
  final double lst;
  const LstTrendPoint({required this.date, required this.lst});
  factory LstTrendPoint.fromJson(Map<String, dynamic> j) =>
      LstTrendPoint(date: j['date'] as String, lst: (j['lst'] as num).toDouble());
}

class NdviTrendPoint {
  final String date;
  final double ndvi;
  const NdviTrendPoint({required this.date, required this.ndvi});
  factory NdviTrendPoint.fromJson(Map<String, dynamic> j) =>
      NdviTrendPoint(date: j['date'] as String, ndvi: (j['ndvi'] as num).toDouble());
}

class LstTrendResponse {
  final List<LstTrendPoint> trend;
  const LstTrendResponse({required this.trend});
  factory LstTrendResponse.fromJson(Map<String, dynamic> j) => LstTrendResponse(
        trend: (j['trend'] as List).map((e) => LstTrendPoint.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class NdviTrendResponse {
  final List<NdviTrendPoint> trend;
  const NdviTrendResponse({required this.trend});
  factory NdviTrendResponse.fromJson(Map<String, dynamic> j) => NdviTrendResponse(
        trend: (j['trend'] as List).map((e) => NdviTrendPoint.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Merged point for scatter chart
class ScatterPoint {
  final String date;
  final double lst;
  final double ndvi;
  const ScatterPoint({required this.date, required this.lst, required this.ndvi});
}

List<ScatterPoint> mergeForScatter(List<LstTrendPoint> lstList, List<NdviTrendPoint> ndviList) {
  final ndviMap = {for (final p in ndviList) p.date: p.ndvi};
  return lstList
      .where((p) => ndviMap.containsKey(p.date))
      .map((p) => ScatterPoint(date: p.date, lst: p.lst, ndvi: ndviMap[p.date]!))
      .toList();
}
