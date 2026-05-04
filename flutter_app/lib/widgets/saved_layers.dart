import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_layer.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';

class SavedLayersSection extends ConsumerStatefulWidget {
  final String lgaId;
  const SavedLayersSection({super.key, required this.lgaId});

  @override
  ConsumerState<SavedLayersSection> createState() => _SavedLayersSectionState();
}

class _SavedLayersSectionState extends ConsumerState<SavedLayersSection> {
  bool _expanded = false;
  List<SavedLayer> _layers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final layers = await api.getSavedLayers(widget.lgaId);
      if (mounted) setState(() { _layers = layers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(SavedLayer layer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete layer?'),
        content: Text('Delete ${layer.layerType.toUpperCase()} layer from ${layer.dateRangeStart} → ${layer.dateRangeEnd}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFdc2626)))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteSavedLayer(widget.lgaId, layer.id);
      setState(() => _layers.removeWhere((l) => l.id == layer.id));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete layer')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Saved Layers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            OutlinedButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text(_expanded ? 'Hide' : 'Show (${_layers.length})'),
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_loading) const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          if (!_loading && _layers.isEmpty)
            const Text('No saved layers yet.', style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
          ..._layers.map((layer) => _LayerCard(layer: layer, onLoad: () {
            ref.read(activeTileLayerProvider.notifier).state = TileLayerState(
              type: layer.layerType,
              tileUrl: layer.tileUrl,
              dateRangeStart: layer.dateRangeStart,
              dateRangeEnd: layer.dateRangeEnd,
            );
          }, onDelete: () => _delete(layer))),
        ],
      ],
    );
  }
}

class _LayerCard extends StatelessWidget {
  final SavedLayer layer;
  final VoidCallback onLoad;
  final VoidCallback onDelete;
  const _LayerCard({required this.layer, required this.onLoad, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(layer.layerType.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              Row(children: [
                _SmallButton(label: 'Load on map', color: const Color(0xFF2563eb), onTap: onLoad),
                const SizedBox(width: 4),
                _SmallButton(label: 'Delete', color: const Color(0xFFdc2626), bg: const Color(0xFFfee2e2), onTap: onDelete),
              ]),
            ],
          ),
          const SizedBox(height: 4),
          Text('${layer.dateRangeStart} → ${layer.dateRangeEnd}', style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280))),
          if (layer.avgLstCelsius != null)
            Text('LST ${layer.avgLstCelsius!.toStringAsFixed(1)}°C · NDVI ${layer.avgNdvi?.toStringAsFixed(3)} · UHI ${layer.uhiIntensity?.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280))),
          Text('Saved ${DateTime.tryParse(layer.exportedAt)?.toLocal().toString().substring(0, 10) ?? layer.exportedAt}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFd1d5db))),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bg;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.color, this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg ?? color, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(fontSize: 11, color: bg != null ? color : Colors.white)),
      ),
    );
  }
}
