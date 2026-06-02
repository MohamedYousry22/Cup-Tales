import 'package:flutter/material.dart';

class RouteTracker extends NavigatorObserver {
  static final ValueNotifier<String?> currentRoute =
      ValueNotifier<String?>(null);
  static final ValueNotifier<bool> isHomeTabActive = ValueNotifier<bool>(false);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute.value = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute.value = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRoute.value = newRoute?.settings.name;
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(
          painter: _AppBackgroundPainter(),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: RouteTracker.currentRoute,
          builder: (context, currentRoute, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: RouteTracker.isHomeTabActive,
              builder: (context, isHomeTabActive, _) {
                if (currentRoute != '/home' || !isHomeTabActive) {
                  return const SizedBox.shrink();
                }
                return Center(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final logoWidth = constraints.maxWidth * 0.5;
                        return Opacity(
                          opacity: 0.28,
                          child: SizedBox(
                            width: logoWidth,
                            child: Image.asset(
                              'assets/images/logo/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        child,
      ],
    );
  }
}

class _AppBackgroundPainter extends CustomPainter {
  const _AppBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8F9FF),
            Color(0xFFE9EBFF),
            Color(0xFFDADDF7),
          ],
          stops: [0, 0.36, 0.72, 1],
        ).createShader(rect),
    );

    final topWash = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.7, -0.95),
        radius: 0.95,
        colors: [
          Color(0x082D3194),
          Color(0x032D3194),
          Color(0x002D3194),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, topWash);

    final brandWash = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.65, 0.98),
        radius: 1.16,
        colors: [
          Color(0x222D3194),
          Color(0x0D2D3194),
          Color(0x002D3194),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, brandWash);

    final curvePaint = Paint()
      ..color = const Color(0xFF2D3194).withValues(alpha: 0.026)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.22 + i * 0.26);
      final path = Path()
        ..moveTo(-32, y)
        ..cubicTo(
          size.width * 0.25,
          y - 18,
          size.width * 0.6,
          y + 20,
          size.width + 32,
          y - 8,
        );
      canvas.drawPath(path, curvePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppBackgroundPainter oldDelegate) => false;
}
