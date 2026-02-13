import 'package:flutter/material.dart';
import 'dart:math'; // For Random and sin()




// ===== Dollar Sign Scribble Custom Painter =====





class DollarScribbleBackground extends StatelessWidget {
  const DollarScribbleBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _DollarSignPainter(),
    );
  }
}

class _DollarSignPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(2025);
    final numDollars = 35;
    final colorOptions = [
      const Color.fromARGB(55, 34, 197, 94), // Greenish
      const Color.fromARGB(40, 59, 130, 246), // Blue
      const Color.fromARGB(40, 251, 191, 36), // Gold
    ];

    for (int i = 0; i < numDollars; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double scale = 0.7 + random.nextDouble() * 1.6;
      double rotate = random.nextDouble() * pi / 2 - pi / 4;

      final paint = Paint()
        ..color = colorOptions[random.nextInt(colorOptions.length)]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 + random.nextDouble() * 1.3
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotate);
      canvas.scale(scale);

      // S-curve for the dollar body
      final Path sCurve = Path();
      sCurve.moveTo(0, -22);
      sCurve.cubicTo(15, -32, 15, -2, 0, 0);
      sCurve.cubicTo(-15, 2, -15, 30, 0, 22);

      // Two vertical lines through S
      final Path vert1 = Path();
      vert1.moveTo(-8, -22);
      vert1.lineTo(-8, 22);

      final Path vert2 = Path();
      vert2.moveTo(8, -22);
      vert2.lineTo(8, 22);

      // Draw the body and strokes
      canvas.drawPath(sCurve, paint);
      canvas.drawPath(vert1, paint);
      canvas.drawPath(vert2, paint);

      // Optionally: Some sketchy scribble overlay for personality
      if (random.nextBool()) {
        final scribblePaint = Paint()
          ..color = paint.color.withOpacity(0.24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = paint.strokeWidth * 0.7;

        final scribblePath = Path();
        scribblePath.moveTo(0, -19);
        scribblePath.cubicTo(7 + random.nextDouble()*6, -25, 9, 0, 0, 0);
        scribblePath.cubicTo(-8 - random.nextDouble()*6, 10, -3, 19, 0, 17);
        canvas.drawPath(scribblePath, scribblePaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}