import 'package:dio/dio.dart';
import '../models/lga_feature.dart';
import '../models/heat_stats.dart';
import '../models/tile_response.dart';
import '../models/trend_point.dart';
import '../models/saved_layer.dart';
import '../models/chat_message.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  const ApiException({this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:3001';

  late final Dio _dio;

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
  }

  Future<T> _get<T>(String path, T Function(dynamic) parser, {Map<String, dynamic>? params}) async {
    try {
      final res = await _dio.get(path, queryParameters: params);
      return parser(res.data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?['error'] ?? e.message ?? 'Request failed';
      throw ApiException(statusCode: code, message: msg.toString());
    }
  }

  Future<FeatureCollection> getLgas() =>
      _get('/api/lgas', (d) => FeatureCollection.fromJson(d as Map<String, dynamic>));

  Future<HeatStats> getHeatStats(String lgaId, String start, String end) =>
      _get('/api/lga/$lgaId/heat', (d) => HeatStats.fromJson(d as Map<String, dynamic>),
          params: {'start': start, 'end': end});

  Future<TileResponse> getTiles(String lgaId, String type, String start, String end) =>
      _get('/api/lga/$lgaId/tiles', (d) => TileResponse.fromJson(d as Map<String, dynamic>),
          params: {'type': type, 'start': start, 'end': end});

  Future<LstTrendResponse> getLstTrend(String lgaId, String start, String end) =>
      _get('/api/lga/$lgaId/lst-trend', (d) => LstTrendResponse.fromJson(d as Map<String, dynamic>),
          params: {'start': start, 'end': end});

  Future<NdviTrendResponse> getNdviTrend(String lgaId, String start, String end) =>
      _get('/api/lga/$lgaId/ndvi-trend', (d) => NdviTrendResponse.fromJson(d as Map<String, dynamic>),
          params: {'start': start, 'end': end});

  Future<List<SavedLayer>> getSavedLayers(String lgaId) =>
      _get('/api/lga/$lgaId/saved-layers',
          (d) => ((d as Map<String, dynamic>)['layers'] as List)
              .map((e) => SavedLayer.fromJson(e as Map<String, dynamic>))
              .toList());

  Future<void> deleteSavedLayer(String lgaId, int layerId) async {
    try {
      await _dio.delete('/api/lga/$lgaId/saved-layers/$layerId');
    } on DioException catch (e) {
      throw ApiException(statusCode: e.response?.statusCode, message: 'Delete failed');
    }
  }

  Future<String> postChat(
    String lgaId,
    String question,
    HeatStats heatStats,
    List<ChatMessage> history,
  ) async {
    try {
      final res = await _dio.post('/api/chat', data: {
        'lgaId': lgaId,
        'question': question,
        'heatStats': heatStats.toJson(),
        'history': history.map((m) => m.toJson()).toList(),
      });
      return (res.data as Map<String, dynamic>)['answer'] as String;
    } on DioException catch (e) {
      throw ApiException(statusCode: e.response?.statusCode, message: 'Chat request failed');
    }
  }
}
