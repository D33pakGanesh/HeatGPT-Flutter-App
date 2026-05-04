import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/lga_feature.dart';
import '../models/heat_stats.dart';
import '../models/tile_response.dart';
import '../models/chat_message.dart';

// ─── API Service ────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─── Timespan ───────────────────────────────────────────────────────────────

enum Timespan { d30, d90, d180, yr1 }

extension TimespanExt on Timespan {
  String get label => switch (this) {
        Timespan.d30 => '30d',
        Timespan.d90 => '90d',
        Timespan.d180 => '180d',
        Timespan.yr1 => '1yr',
      };

  int get days => switch (this) {
        Timespan.d30 => 30,
        Timespan.d90 => 90,
        Timespan.d180 => 180,
        Timespan.yr1 => 365,
      };
}

final timespanProvider = StateProvider<Timespan>((ref) => Timespan.d30);

class DateRange {
  final String start;
  final String end;
  const DateRange({required this.start, required this.end});
}

final dateRangeProvider = Provider<DateRange>((ref) {
  final ts = ref.watch(timespanProvider);
  final now = DateTime.now();
  final start = now.subtract(Duration(days: ts.days));
  String fmt(DateTime d) => d.toIso8601String().substring(0, 10);
  return DateRange(start: fmt(start), end: fmt(now));
});

// ─── LGAs ───────────────────────────────────────────────────────────────────

final lgasProvider = FutureProvider<FeatureCollection>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getLgas();
});

// ─── Selected LGA ───────────────────────────────────────────────────────────

final selectedLgaIdProvider = StateProvider<String?>((ref) => null);

final selectedLgaFeatureProvider = Provider<LgaFeature?>((ref) {
  final id = ref.watch(selectedLgaIdProvider);
  if (id == null) return null;
  final lgas = ref.watch(lgasProvider).valueOrNull;
  return lgas?.features.where((f) => f.lgaId == id).firstOrNull;
});

// ─── Heat Stats ─────────────────────────────────────────────────────────────

final heatStatsProvider = FutureProvider<HeatStats?>((ref) async {
  final id = ref.watch(selectedLgaIdProvider);
  if (id == null) return null;
  final dr = ref.watch(dateRangeProvider);
  final api = ref.read(apiServiceProvider);
  return api.getHeatStats(id, dr.start, dr.end);
});

// ─── Active Tile Layer ───────────────────────────────────────────────────────

class TileLayerState {
  final String type; // 'lst' | 'ndvi'
  final String tileUrl;
  final BBox? bbox;
  final String dateRangeStart;
  final String dateRangeEnd;

  const TileLayerState({
    required this.type,
    required this.tileUrl,
    this.bbox,
    required this.dateRangeStart,
    required this.dateRangeEnd,
  });
}

final activeTileLayerProvider = StateProvider<TileLayerState?>((ref) => null);

// ─── Symbology ───────────────────────────────────────────────────────────────

class SymbologySettings {
  final int fillColor;       // ARGB int
  final double fillOpacity;
  final int strokeColor;     // ARGB int
  final double strokeWeight;

  const SymbologySettings({
    this.fillColor = 0xFF3b82f6,
    this.fillOpacity = 0.7,
    this.strokeColor = 0xFF666666,
    this.strokeWeight = 1.0,
  });

  SymbologySettings copyWith({
    int? fillColor,
    double? fillOpacity,
    int? strokeColor,
    double? strokeWeight,
  }) =>
      SymbologySettings(
        fillColor: fillColor ?? this.fillColor,
        fillOpacity: fillOpacity ?? this.fillOpacity,
        strokeColor: strokeColor ?? this.strokeColor,
        strokeWeight: strokeWeight ?? this.strokeWeight,
      );
}

class SymbologyNotifier extends StateNotifier<SymbologySettings> {
  SymbologyNotifier() : super(const SymbologySettings());
  void update(SymbologySettings s) => state = s;
  void reset() => state = const SymbologySettings();
}

final symbologyProvider = StateNotifierProvider<SymbologyNotifier, SymbologySettings>(
  (ref) => SymbologyNotifier(),
);

// ─── Chat ────────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);
  void add(ChatMessage msg) => state = [...state, msg];
  void clear() => state = [];
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) {
    final notifier = ChatNotifier();
    // Reset chat when selected LGA changes
    ref.listen(selectedLgaIdProvider, (_, __) => notifier.clear());
    return notifier;
  },
);

// ─── Panel open state ────────────────────────────────────────────────────────

final sidePanelOpenProvider = StateProvider<bool>((ref) => false);
