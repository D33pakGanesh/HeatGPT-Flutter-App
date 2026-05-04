import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/providers.dart';

const _lstPalette = [
  (hex: 0xFF313695, label: '≤20°C'), (hex: 0xFF4575b4, label: '25°C'),
  (hex: 0xFF74add1, label: '30°C'),  (hex: 0xFFabd9e9, label: '35°C'),
  (hex: 0xFFfee090, label: '40°C'),  (hex: 0xFFfdae61, label: '45°C'),
  (hex: 0xFFf46d43, label: '50°C'),  (hex: 0xFFd73027, label: '55°C'),
  (hex: 0xFFa50026, label: '>55°C'),
];

const _ndviPalette = [
  (hex: 0xFFd73027, label: '-0.2'), (hex: 0xFFfee090, label: '0.0'),
  (hex: 0xFFffffbf, label: '0.2'),  (hex: 0xFFd9ef8b, label: '0.4'),
  (hex: 0xFF91cf60, label: '0.6'),  (hex: 0xFF1a9850, label: '0.8'),
];

PdfColor _toPdf(int argb) {
  final r = ((argb >> 16) & 0xFF) / 255.0;
  final g = ((argb >> 8) & 0xFF) / 255.0;
  final b = (argb & 0xFF) / 255.0;
  return PdfColor(r, g, b);
}

String _kebab(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

class PdfExportButton extends ConsumerStatefulWidget {
  final GlobalKey mapKey;
  final String? lgaName;
  const PdfExportButton({super.key, required this.mapKey, this.lgaName});

  @override
  ConsumerState<PdfExportButton> createState() => _PdfExportButtonState();
}

class _PdfExportButtonState extends ConsumerState<PdfExportButton> {
  bool _exporting = false;
  String? _error;

  Future<Uint8List?> _captureMap() async {
    try {
      final boundary = widget.mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _export() async {
    final tileLayer = ref.read(activeTileLayerProvider);
    if (tileLayer == null) return;
    setState(() { _exporting = true; _error = null; });

    try {
      final imageBytes = await _captureMap();
      if (imageBytes == null) throw Exception('Map capture failed');

      final layerType = tileLayer.type;
      final lgaName = widget.lgaName ?? 'Unknown LGA';
      final layerLabel = layerType == 'lst' ? 'LST Heatmap' : 'NDVI Vegetation';
      final title = '$lgaName — $layerLabel';
      final palette = layerType == 'ndvi' ? _ndviPalette : _lstPalette;
      final dataSource = layerType == 'lst' ? 'Landsat 9 (LST)' : 'Sentinel-2 (NDVI)';
      final dateRange = '${tileLayer.dateRangeStart} – ${tileLayer.dateRangeEnd}';
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final filename = '${_kebab(lgaName)}-${layerType}-$today.pdf';

      final doc = pw.Document();
      final mapImage = pw.MemoryImage(imageBytes);

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) {
          final pageW = PdfPageFormat.a4.landscape.availableWidth;
          final pageH = PdfPageFormat.a4.landscape.availableHeight;
          const titleH = 20.0;
          const bottomH = 60.0;
          final mapH = pageH - titleH - bottomH - 8;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: pageW, height: titleH,
                color: const PdfColor(0.12, 0.16, 0.24),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ),
              const pw.SizedBox(height: 4),
              pw.Image(mapImage, width: pageW, height: mapH, fit: pw.BoxFit.cover),
              const pw.SizedBox(height: 4),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(layerType == 'lst' ? 'LST (°C)' : 'NDVI',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      const pw.SizedBox(height: 3),
                      ...palette.map((e) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(children: [
                              pw.Container(width: 12, height: 8, color: _toPdf(e.hex)),
                              const pw.SizedBox(width: 4),
                              pw.Text(e.label, style: const pw.TextStyle(fontSize: 7)),
                            ]),
                          )),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Satellite data: $dataSource', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text('Date range: $dateRange', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.Text('Generated: $today', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ));

      final pdfBytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: title),
      );
    } catch (e) {
      setState(() => _error = 'Export failed');
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileLayer = ref.watch(activeTileLayerProvider);
    if (tileLayer == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: _exporting ? null : _export,
          backgroundColor: _exporting ? Colors.grey : const Color(0xFF1e293b),
          icon: _exporting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: Text(_exporting ? 'Exporting...' : 'Export PDF', style: const TextStyle(color: Colors.white)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(6)),
            child: Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFdc2626))),
          ),
        ],
      ],
    );
  }
}
