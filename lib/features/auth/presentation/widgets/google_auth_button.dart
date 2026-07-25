import 'package:flutter/material.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const CustomPaint(
          size: Size.square(24),
          painter: _GoogleLogoPainter(),
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          disabledBackgroundColor: Colors.white70,
          disabledForegroundColor: const Color(0xFF6B7280),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(22.56 * scale, 12.25 * scale)
        ..cubicTo(
          22.56 * scale,
          11.47 * scale,
          22.49 * scale,
          10.72 * scale,
          22.36 * scale,
          10 * scale,
        )
        ..lineTo(12 * scale, 10 * scale)
        ..lineTo(12 * scale, 14.26 * scale)
        ..lineTo(17.92 * scale, 14.26 * scale)
        ..cubicTo(
          17.66 * scale,
          15.63 * scale,
          16.88 * scale,
          16.79 * scale,
          15.71 * scale,
          17.57 * scale,
        )
        ..lineTo(15.71 * scale, 20.34 * scale)
        ..lineTo(19.28 * scale, 20.34 * scale)
        ..cubicTo(
          21.36 * scale,
          18.42 * scale,
          22.56 * scale,
          15.60 * scale,
          22.56 * scale,
          12.25 * scale,
        )
        ..close(),
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(12 * scale, 23 * scale)
        ..cubicTo(
          14.97 * scale,
          23 * scale,
          17.46 * scale,
          22.02 * scale,
          19.28 * scale,
          20.34 * scale,
        )
        ..lineTo(15.71 * scale, 17.57 * scale)
        ..cubicTo(
          14.73 * scale,
          18.23 * scale,
          13.48 * scale,
          18.63 * scale,
          12 * scale,
          18.63 * scale,
        )
        ..cubicTo(
          9.14 * scale,
          18.63 * scale,
          6.71 * scale,
          16.70 * scale,
          5.84 * scale,
          14.10 * scale,
        )
        ..lineTo(2.18 * scale, 14.10 * scale)
        ..lineTo(2.18 * scale, 16.94 * scale)
        ..cubicTo(
          3.99 * scale,
          20.53 * scale,
          7.70 * scale,
          23 * scale,
          12 * scale,
          23 * scale,
        )
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(5.84 * scale, 14.09 * scale)
        ..cubicTo(
          5.62 * scale,
          13.43 * scale,
          5.49 * scale,
          12.73 * scale,
          5.49 * scale,
          12 * scale,
        )
        ..cubicTo(
          5.49 * scale,
          11.27 * scale,
          5.62 * scale,
          10.57 * scale,
          5.84 * scale,
          9.91 * scale,
        )
        ..lineTo(5.84 * scale, 7.07 * scale)
        ..lineTo(2.18 * scale, 7.07 * scale)
        ..cubicTo(
          1.43 * scale,
          8.55 * scale,
          1 * scale,
          10.22 * scale,
          1 * scale,
          12 * scale,
        )
        ..cubicTo(
          1 * scale,
          13.78 * scale,
          1.43 * scale,
          15.45 * scale,
          2.18 * scale,
          16.93 * scale,
        )
        ..lineTo(5.84 * scale, 14.09 * scale)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(12 * scale, 5.38 * scale)
        ..cubicTo(
          13.62 * scale,
          5.38 * scale,
          15.06 * scale,
          5.94 * scale,
          16.21 * scale,
          7.02 * scale,
        )
        ..lineTo(19.36 * scale, 3.87 * scale)
        ..cubicTo(
          17.45 * scale,
          2.09 * scale,
          14.97 * scale,
          1 * scale,
          12 * scale,
          1 * scale,
        )
        ..cubicTo(
          7.70 * scale,
          1 * scale,
          3.99 * scale,
          3.47 * scale,
          2.18 * scale,
          7.07 * scale,
        )
        ..lineTo(5.84 * scale, 9.91 * scale)
        ..cubicTo(
          6.71 * scale,
          7.31 * scale,
          9.14 * scale,
          5.38 * scale,
          12 * scale,
          5.38 * scale,
        )
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
