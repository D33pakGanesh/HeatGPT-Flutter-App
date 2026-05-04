import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

const _strokePresets = [
  Color(0xFF666666), Color(0xFFffffff), Color(0xFF000000),
  Color(0xFFef4444), Color(0xFF3b82f6), Color(0xFF22c55e),
];

class SymbologyPanel extends ConsumerStatefulWidget {
  const SymbologyPanel({super.key});

  @override
  ConsumerState<SymbologyPanel> createState() => _SymbologyPanelState();
}

class _SymbologyPanelState extends ConsumerState<SymbologyPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final sym = ref.watch(symbologyProvider);
    final notifier = ref.read(symbologyProvider.notifier);

    return Stack(
      children: [
        // Slide-out panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _open ? 0 : -220,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('LGA Symbology', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 12),

                    // Fill colour
                    const Text('FILL COLOUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6b7280), letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showColorPickerDialog(
                          context,
                          Color(sym.fillColor),
                          title: const Text('Fill colour'),
                          pickersEnabled: const {ColorPickerType.wheel: true, ColorPickerType.primary: true},
                        );
                        notifier.update(sym.copyWith(fillColor: picked.value));
                      },
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(sym.fillColor),
                          border: Border.all(color: const Color(0xFFd1d5db)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fill opacity
                    Text('FILL OPACITY — ${(sym.fillOpacity * 100).round()}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6b7280), letterSpacing: 0.5)),
                    Slider(
                      value: sym.fillOpacity,
                      min: 0, max: 1, divisions: 20,
                      onChanged: (v) => notifier.update(sym.copyWith(fillOpacity: v)),
                    ),

                    // Border colour
                    const Text('BORDER COLOUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6b7280), letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _strokePresets.map((c) => GestureDetector(
                            onTap: () => notifier.update(sym.copyWith(strokeColor: c.value)),
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sym.strokeColor == c.value ? const Color(0xFF2563eb) : const Color(0xFFd1d5db),
                                  width: sym.strokeColor == c.value ? 3 : 2,
                                ),
                              ),
                            ),
                          )).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Border width
                    Text('BORDER WIDTH — ${sym.strokeWeight.toStringAsFixed(1)}px',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6b7280), letterSpacing: 0.5)),
                    Slider(
                      value: sym.strokeWeight,
                      min: 0, max: 4, divisions: 8,
                      onChanged: (v) => notifier.update(sym.copyWith(strokeWeight: v)),
                    ),

                    // Reset
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: notifier.reset,
                        child: const Text('Reset to defaults', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab trigger
              GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: Container(
                  width: 24,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1e293b),
                    borderRadius: BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(_open ? 'Close' : 'Symbology',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
