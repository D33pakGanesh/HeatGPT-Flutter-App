import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heat_stats.dart';
import '../models/trend_point.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import 'chat_interface.dart';
import 'lst_trend_chart.dart';
import 'metric_progress_bars.dart';
import 'saved_layers.dart';
import 'scatter_chart_widget.dart';

const _panelWidth = 360.0;

Color _heatRiskColor(double uhi) {
  if (uhi > 3.0) return const Color(0xFFdc2626);
  if (uhi > 1.5) return const Color(0xFFea580c);
  if (uhi > 0.0) return const Color(0xFFca8a04);
  return const Color(0xFF16a34a);
}

String _heatRiskLabel(double uhi) {
  if (uhi > 3.0) return 'Extreme Heat Risk';
  if (uhi > 1.5) return 'High Heat Risk';
  if (uhi > 0.0) return 'Moderate Heat Risk';
  return 'Low Heat Risk';
}

class SidePanel extends ConsumerStatefulWidget {
  const SidePanel({super.key});

  @override
  ConsumerState<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends ConsumerState<SidePanel> {
  bool _collapsed = true;
  String? _activeLayer; // 'lst' | 'ndvi' | null
  bool _tileLoading = false;
  String? _tileError;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _customApplied = false;

  List<LstTrendPoint> _lstTrend = [];
  List<NdviTrendPoint> _ndviTrend = [];

  @override
  void initState() {
    super.initState();
    ref.listenManual(selectedLgaIdProvider, (_, __) {
      setState(() {
        _collapsed = true;
        _activeLayer = null;
        _tileError = null;
        _customStart = null;
        _customEnd = null;
        _customApplied = false;
        _lstTrend = [];
        _ndviTrend = [];
      });
      ref.read(activeTileLayerProvider.notifier).state = null;
    });
  }

  Future<void> _fetchTile(String lgaId, String type, String start, String end) async {
    setState(() { _tileLoading = true; _tileError = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final tile = await api.getTiles(lgaId, type, start, end);
      ref.read(activeTileLayerProvider.notifier).state = TileLayerState(
        type: type,
        tileUrl: tile.tileUrl,
        bbox: tile.bbox,
        dateRangeStart: start,
        dateRangeEnd: end,
      );
    } on ApiException catch (e) {
      setState(() => _tileError = e.statusCode == 422 ? 'No satellite data found for this period' : 'Failed to load satellite layer');
      ref.read(activeTileLayerProvider.notifier).state = null;
    } finally {
      setState(() => _tileLoading = false);
    }
  }

  Future<void> _fetchTrends(String lgaId, String start, String end) async {
    try {
      final api = ref.read(apiServiceProvider);
      final lst = await api.getLstTrend(lgaId, start, end);
      final ndvi = await api.getNdviTrend(lgaId, start, end);
      if (mounted) setState(() { _lstTrend = lst.trend; _ndviTrend = ndvi.trend; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lgaId = ref.watch(selectedLgaIdProvider);
    if (lgaId == null) return const SizedBox.shrink();

    final heatAsync = ref.watch(heatStatsProvider);
    final dr = ref.watch(dateRangeProvider);
    final timespan = ref.watch(timespanProvider);

    // Fetch trends when heat stats arrive
    ref.listen(heatStatsProvider, (_, next) {
      if (next.valueOrNull != null) {
        _fetchTrends(lgaId, dr.start, dr.end);
        if (!_collapsed) return;
        setState(() => _collapsed = false);
        ref.read(sidePanelOpenProvider.notifier).state = true;
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Toggle tab
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: _collapsed ? 0 : _panelWidth,
          top: screenHeight / 2 - 28,
          child: GestureDetector(
            onTap: () {
              setState(() => _collapsed = !_collapsed);
              ref.read(sidePanelOpenProvider.notifier).state = !_collapsed;
            },
            child: Container(
              width: 20, height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF1e293b),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Center(child: Text(_collapsed ? '‹' : '›', style: const TextStyle(color: Colors.white, fontSize: 14))),
            ),
          ),
        ),

        // Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: _collapsed ? -_panelWidth : 0,
          top: 0,
          bottom: 0,
          width: _panelWidth,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFe5e7eb))),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(-4, 0))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Timespan selector
                  Row(
                    children: Timespan.values.map((ts) {
                      final active = timespan == ts;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => ref.read(timespanProvider.notifier).state = ts,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF2563eb) : const Color(0xFFf3f4f6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: active ? const Color(0xFF2563eb) : const Color(0xFFd1d5db)),
                            ),
                            child: Text(ts.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF374151))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Heat stats
                  heatAsync.when(
                    loading: () => _Skeletons(),
                    error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(heatStatsProvider)),
                    data: (stats) {
                      if (stats == null) return const SizedBox.shrink();
                      return _StatsContent(
                        stats: stats,
                        lgaId: lgaId,
                        activeLayer: _activeLayer,
                        tileLoading: _tileLoading,
                        tileError: _tileError,
                        customStart: _customStart,
                        customEnd: _customEnd,
                        customApplied: _customApplied,
                        lstTrend: _lstTrend,
                        ndviTrend: _ndviTrend,
                        onLayerToggle: (type) {
                          setState(() { _activeLayer = type; _tileError = null; });
                          if (type == null) {
                            ref.read(activeTileLayerProvider.notifier).state = null;
                          } else {
                            final start = _customApplied && _customStart != null ? _fmt(_customStart!) : dr.start;
                            final end = _customApplied && _customEnd != null ? _fmt(_customEnd!) : dr.end;
                            _fetchTile(lgaId, type, start, end);
                          }
                        },
                        onApplyDateRange: (start, end) {
                          setState(() { _customStart = start; _customEnd = end; _customApplied = true; });
                          if (_activeLayer != null) _fetchTile(lgaId, _activeLayer!, _fmt(start), _fmt(end));
                        },
                        onResetDateRange: () {
                          setState(() { _customStart = null; _customEnd = null; _customApplied = false; });
                          if (_activeLayer != null) _fetchTile(lgaId, _activeLayer!, dr.start, dr.end);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);
}

// ─── Stats content ───────────────────────────────────────────────────────────

class _StatsContent extends StatefulWidget {
  final HeatStats stats;
  final String lgaId;
  final String? activeLayer;
  final bool tileLoading;
  final String? tileError;
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool customApplied;
  final List<LstTrendPoint> lstTrend;
  final List<NdviTrendPoint> ndviTrend;
  final void Function(String?) onLayerToggle;
  final void Function(DateTime, DateTime) onApplyDateRange;
  final VoidCallback onResetDateRange;

  const _StatsContent({
    required this.stats, required this.lgaId, required this.activeLayer,
    required this.tileLoading, required this.tileError,
    required this.customStart, required this.customEnd, required this.customApplied,
    required this.lstTrend, required this.ndviTrend,
    required this.onLayerToggle, required this.onApplyDateRange, required this.onResetDateRange,
  });

  @override
  State<_StatsContent> createState() => _StatsContentState();
}

class _StatsContentState extends State<_StatsContent> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final riskColor = _heatRiskColor(s.uhiIntensity);
    final riskLabel = _heatRiskLabel(s.uhiIntensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.lgaName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 8),

        // Heat risk badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            border: Border.all(color: riskColor.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(riskLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: riskColor)),
        ),

        if (s.stale) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFfef3c7), border: Border.all(color: const Color(0xFFfcd34d)), borderRadius: BorderRadius.circular(4)),
            child: const Text('Data may be outdated', style: TextStyle(fontSize: 12, color: Color(0xFF92400e))),
          ),
        ],
        const SizedBox(height: 16),

        // Stat cards
        _StatCard(label: 'Avg Temperature', value: '${s.avgLstCelsius.toStringAsFixed(1)}°C'),
        _StatCard(label: 'NDVI (Vegetation)', value: s.avgNdvi.toStringAsFixed(3)),
        _StatCard(label: 'UHI Intensity', value: '${s.uhiIntensity.toStringAsFixed(1)}°C'),
        const SizedBox(height: 16),

        // Layer toggles
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _LayerToggle(label: 'LST Heatmap', type: 'lst', activeLayer: widget.activeLayer, loading: widget.tileLoading, onTap: widget.onLayerToggle),
            _LayerToggle(label: 'NDVI Vegetation', type: 'ndvi', activeLayer: widget.activeLayer, loading: widget.tileLoading, onTap: widget.onLayerToggle),
            _LayerToggle(label: 'None', type: null, activeLayer: widget.activeLayer, loading: false, onTap: widget.onLayerToggle),
          ],
        ),

        if (widget.tileError != null) ...[
          const SizedBox(height: 6),
          Text('⚠ ${widget.tileError}', style: const TextStyle(fontSize: 12, color: Color(0xFFdc2626))),
        ],

        // Custom date range
        if (widget.activeLayer != null) ...[
          const SizedBox(height: 12),
          _DateRangePicker(
            customStart: widget.customStart,
            customEnd: widget.customEnd,
            customApplied: widget.customApplied,
            onApply: widget.onApplyDateRange,
            onReset: widget.onResetDateRange,
          ),
        ],

        const SizedBox(height: 16),

        // Trend chart
        if (widget.lstTrend.isNotEmpty) ...[
          LstTrendChart(data: widget.lstTrend),
          const SizedBox(height: 16),
        ],

        // Scatter chart
        LstNdviScatterChart(data: mergeForScatter(widget.lstTrend, widget.ndviTrend)),
        const SizedBox(height: 16),

        // Progress bars
        MetricProgressBars(avgLstCelsius: s.avgLstCelsius, avgNdvi: s.avgNdvi),
        const SizedBox(height: 16),

        // Saved layers
        SavedLayersSection(lgaId: widget.lgaId),
        const SizedBox(height: 16),

        // Chat
        ChatInterface(lgaId: widget.lgaId, heatStats: s),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Small reusable widgets ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFf9fafb),
          border: Border.all(color: const Color(0xFFe5e7eb)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ],
        ),
      );
}

class _LayerToggle extends StatelessWidget {
  final String label;
  final String? type;
  final String? activeLayer;
  final bool loading;
  final void Function(String?) onTap;
  const _LayerToggle({required this.label, required this.type, required this.activeLayer, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = activeLayer == type;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563eb) : const Color(0xFFf3f4f6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? const Color(0xFF2563eb) : const Color(0xFFd1d5db)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF374151))),
            if (loading && active) ...[
              const SizedBox(width: 6),
              const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRangePicker extends StatefulWidget {
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool customApplied;
  final void Function(DateTime, DateTime) onApply;
  final VoidCallback onReset;
  const _DateRangePicker({required this.customStart, required this.customEnd, required this.customApplied, required this.onApply, required this.onReset});

  @override
  State<_DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<_DateRangePicker> {
  DateTime? _from;
  DateTime? _to;

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  bool get _canApply => _from != null && _to != null && _from!.isBefore(_to!);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Custom date range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6b7280))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _DateButton(label: _from != null ? _fmt(_from!) : 'From', onTap: () => _pickDate(true))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('to', style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af)))),
              Expanded(child: _DateButton(label: _to != null ? _fmt(_to!) : 'To', onTap: () => _pickDate(false))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _canApply ? () => widget.onApply(_from!, _to!) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _canApply ? const Color(0xFF2563eb) : const Color(0xFFe5e7eb),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _canApply ? Colors.white : const Color(0xFF9ca3af))),
                ),
              ),
              if (widget.customApplied) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () { setState(() { _from = null; _to = null; }); widget.onReset(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFd1d5db)), borderRadius: BorderRadius.circular(6), color: Colors.white),
                    child: const Text('Reset', style: TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
                  ),
                ),
              ],
            ],
          ),
          if (widget.customApplied && widget.customStart != null && widget.customEnd != null) ...[
            const SizedBox(height: 6),
            Text('Showing mean for ${_fmt(widget.customStart!)} → ${_fmt(widget.customEnd!)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280))),
          ],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFd1d5db)), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ),
      );
}

class _Skeletons extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(3, (_) => Container(
              height: 72, margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFFe5e7eb), borderRadius: BorderRadius.circular(8)),
            )),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Text('Failed to load heat data', style: TextStyle(color: Color(0xFFdc2626))),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
}
