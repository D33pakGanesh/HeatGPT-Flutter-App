import 'package:flutter/material.dart';

class NorthArrow extends StatelessWidget {
  const NorthArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: const Size(24, 32), painter: _ArrowPainter()),
          const SizedBox(height: 2),
          const Text('N', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1e293b), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF1e293b);
    final light = Paint()..color = const Color(0xFF94a3b8);
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF1e293b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // North half (dark)
    final north = Path()
      ..moveTo(cx, 2)
      ..lineTo(size.width - 2, cy + 4)
      ..lineTo(cx, cy - 2)
      ..close();
    canvas.drawPath(north, dark);

    // South half (light)
    final south = Path()
      ..moveTo(cx, size.height - 2)
      ..lineTo(size.width - 2, cy - 4)
      ..lineTo(cx, cy + 2)
      ..close();
    canvas.drawPath(south, light);

    // Centre circle
    canvas.drawCircle(Offset(cx, cy), 3, white);
    canvas.drawCircle(Offset(cx, cy), 3, outline);
  }

  @override
  bool shouldRepaint(_) => false;
}
