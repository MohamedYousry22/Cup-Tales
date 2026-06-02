import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const kPrimary = Color(0xFF2D3194);
const kCoffee = Color(0xFF6F4E37);
const kCream = Color(0xFFFFF4DE);
const kCaramel = Color(0xFFE5A85C);
const kMint = Color(0xFF8DE6D0);
const kLogoNavy = Color(0xFF17185A);
const kLogoBlue = Color(0xFF2D3194);
const kLogoViolet = Color(0xFF4E46B4);
const kPhoneBg = Color(0xFF1A1C5E);
const kSlate800 = Color(0xFF1E293B);
const kSlate500 = Color(0xFF64748B);
const kSlate300 = Color(0xFFCBD5E1);
const kSlate100 = Color(0xFFF1F5F9);
const kSlate50 = Color(0xFFF8FAFC);

// ─── Onboarding Data ────────────────────────────────────────────────────────

class OnboardingPageData {
  final String title;
  final String description;
  const OnboardingPageData({required this.title, required this.description});
}

const _pages = [
  OnboardingPageData(
    title: 'Discover Your Coffee',
    description:
        'Explore a world of premium blends tailored to your unique palate.',
  ),
  OnboardingPageData(
    title: 'Order Easily',
    description:
        'Choose from our specialty blends and customize your perfect cup in seconds.',
  ),
  OnboardingPageData(
    title: 'Your Daily Ritual',
    description:
        'Track your brews, discover new favourites, and share your story.',
  ),
];

// ─── Onboarding Page ────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _backgroundController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding(BuildContext context) {
    context.read<OnboardingCubit>().finishOnboarding();
  }

  void _next(BuildContext context) {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding(context);
    }
  }

  void _skip(BuildContext context) {
    _finishOnboarding(context);
  }

  Widget _getIllustrationForPage(int page) {
    switch (page) {
      case 0:
        return Image.asset(
          'assets/images/logo/logo.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        );
      case 1:
        return const _PhoneMockup(key: ValueKey(1));
      case 2:
        return const _CoffeeHero(key: ValueKey(2));
      default:
        return Image.asset(
          'assets/images/logo/logo.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(sl()),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            Navigator.pushReplacementNamed(context, AppRouter.login);
          }
        },
        child: Builder(builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF11164A),
            body: Stack(
              children: [
                Positioned.fill(
                  child: _AnimatedCoffeeBackdrop(
                    animation: _backgroundController,
                    page: _currentPage,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // ── Status-bar spacer + Skip ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _skip(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── PageView for Swiping ──────────────────────────────────────
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                // Illustration
                                Expanded(
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      switchInCurve: Curves.easeOutBack,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.92,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _getIllustrationForPage(index),
                                    ),
                                  ),
                                ),
                                // Text
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Column(
                                    children: [
                                      Text(
                                        _pages[index].title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0,
                                          height: 1.16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _pages[index].description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.76),
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w500,
                                          height: 1.55,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 38),

                      // ── Page Indicators ───────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? kCaramel
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: kCaramel.withValues(alpha: 0.45),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 30),

                      // ── Next Button ───────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _next(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kCream,
                                foregroundColor: const Color(0xFF2B2142),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == _pages.length - 1
                                        ? 'Get Started'
                                        : 'Next',
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedCoffeeBackdrop extends StatelessWidget {
  final Animation<double> animation;
  final int page;

  const _AnimatedCoffeeBackdrop({
    required this.animation,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = [
      const [Color(0xFF090B2C), kLogoNavy, kLogoBlue],
      const [Color(0xFF070A27), Color(0xFF20246F), kLogoViolet],
      const [Color(0xFF080B2A), kLogoNavy, Color(0xFF3840B8)],
    ];
    final colors = gradients[page.clamp(0, gradients.length - 1)];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _CoffeeBackdropPainter(
            progress: animation.value,
            colors: colors,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _CoffeeBackdropPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _CoffeeBackdropPainter({
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, gradientPaint);

    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final wave = Path();
    final base = size.height * 0.18;
    wave.moveTo(0, base);
    for (double x = 0; x <= size.width; x += 28) {
      final y = base +
          math.sin((x / size.width * math.pi * 2) + progress * math.pi * 2) *
              18;
      wave.lineTo(x, y);
    }
    wave.lineTo(size.width, 0);
    wave.lineTo(0, 0);
    wave.close();
    canvas.drawPath(wave, wavePaint);

    void glow(Offset center, double radius, Color color, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    glow(
      Offset(size.width * (0.18 + 0.04 * math.sin(progress * math.pi * 2)),
          size.height * 0.22),
      size.width * 0.42,
      const Color(0xFF4E6CFF),
      0.24,
    );
    glow(
      Offset(size.width * (0.86 + 0.03 * math.cos(progress * math.pi * 2)),
          size.height * 0.62),
      size.width * 0.5,
      kLogoViolet,
      0.24,
    );
    glow(
      Offset(size.width * 0.52, size.height * 0.92),
      size.width * 0.56,
      const Color(0xFF05071F),
      0.38,
    );

    final beanPositions = const [
      Offset(0.08, 0.12),
      Offset(0.24, 0.19),
      Offset(0.79, 0.13),
      Offset(0.92, 0.25),
      Offset(0.14, 0.35),
      Offset(0.35, 0.31),
      Offset(0.84, 0.39),
      Offset(0.06, 0.53),
      Offset(0.22, 0.61),
      Offset(0.73, 0.58),
      Offset(0.94, 0.66),
      Offset(0.12, 0.78),
      Offset(0.43, 0.82),
      Offset(0.64, 0.76),
      Offset(0.86, 0.88),
    ];
    final beanPaint = Paint();
    for (int i = 0; i < beanPositions.length; i++) {
      final bean = beanPositions[i];
      final phase = progress * math.pi * 2 + i * 0.73;
      final x = size.width * bean.dx + math.sin(phase) * 4;
      final y = size.height * bean.dy + math.cos(phase * 0.9) * 6;
      final beanScale = 0.72 + (i % 4) * 0.1;
      beanPaint.color =
          const Color(0xFFD2A06C).withValues(alpha: 0.13 + (i % 3) * 0.025);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.9 + i * 0.47 + math.sin(phase) * 0.08);
      canvas.scale(beanScale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -9, 10, 18),
          const Radius.circular(8),
        ),
        beanPaint,
      );
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(0, -6)
        ..cubicTo(-4, -2, 4, 2, 0, 6);
      canvas.drawPath(path, linePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CoffeeBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}

// ─── Coffee Hero (Page 3) ─────────────────────────────────────────────────────────────

class _CoffeeHero extends StatefulWidget {
  const _CoffeeHero({super.key});

  @override
  State<_CoffeeHero> createState() => _CoffeeHeroState();
}

class _CoffeeHeroState extends State<_CoffeeHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _breathe = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -_controller.value * math.pi * 2,
                child: CustomPaint(
                  size: const Size(306, 306),
                  painter: _CoffeeHeroAuraPainter(progress: _controller.value),
                ),
              ),
              Transform.rotate(
                angle: math.sin(_controller.value * math.pi * 2) * 0.045,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    math.sin(_controller.value * math.pi * 2) * 10,
                  ),
                  child: ScaleTransition(
                    scale: _breathe,
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(250, 250),
                            painter:
                                _CoffeeHeroCupPainter(controller: _controller),
                          ),
                          Positioned(
                            top: 137,
                            child: Container(
                              width: 50,
                              height: 50,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kLogoNavy,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kLogoNavy.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoffeeHeroAuraPainter extends CustomPainter {
  final double progress;

  _CoffeeHeroAuraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6E7BFF).withValues(alpha: 0.32),
          kLogoViolet.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0, 0.45, 0.72, 1],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, size.width * 0.45, glowPaint);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, size.width * 0.41, ringPaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final colors = [
      Colors.white,
      const Color(0xFF8EA0FF),
      const Color(0xFF4E6CFF),
      kLogoViolet,
    ];
    for (int i = 0; i < 12; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 2 / 12;
      final radius = size.width * (0.32 + (i.isEven ? 0.08 : 0.02));
      dotPaint.color = colors[i % colors.length].withValues(alpha: 0.72);
      final orbitCenter =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i % 3 == 0) {
        canvas.save();
        canvas.translate(orbitCenter.dx, orbitCenter.dy);
        canvas.rotate(angle + math.pi / 6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -8, 8, 16),
            const Radius.circular(7),
          ),
          dotPaint,
        );
        final beanLine = Paint()
          ..color = Colors.white.withValues(alpha: 0.24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(0, -5)
            ..cubicTo(-3, -1, 3, 1, 0, 5),
          beanLine,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(orbitCenter, i.isEven ? 4.4 : 2.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoffeeHeroAuraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CoffeeHeroCupPainter extends CustomPainter {
  final AnimationController controller;

  _CoffeeHeroCupPainter({required this.controller})
      : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final t = controller.value;
    final w = size.width;
    final h = size.height;

    final shadowPaint = Paint()
      ..color = const Color(0xFF2B1742).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.83),
        width: w * 0.52,
        height: h * 0.08,
      ),
      shadowPaint,
    );

    final cupPath = Path()
      ..moveTo(w * 0.28, h * 0.37)
      ..lineTo(w * 0.72, h * 0.37)
      ..lineTo(w * 0.64, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.84, w * 0.36, h * 0.78)
      ..close();

    final cupPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          kCream,
          const Color(0xFFFFDCA4),
          const Color(0xFFE9B974),
        ],
      ).createShader(Rect.fromLTWH(w * 0.28, h * 0.37, w * 0.44, h * 0.48));
    canvas.drawPath(cupPath, cupPaint);

    final bodyStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(cupPath, bodyStroke);

    final lidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9EC), Color(0xFFFFC671)],
      ).createShader(Rect.fromLTWH(w * 0.2, h * 0.25, w * 0.6, h * 0.14));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.23, h * 0.29, w * 0.54, h * 0.09),
        Radius.circular(w * 0.035),
      ),
      lidPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.35, w * 0.6, h * 0.045),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );

    final sipPaint = Paint()
      ..color = const Color(0xFF3A1F18).withValues(alpha: 0.84);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.31, w * 0.24, h * 0.035),
        Radius.circular(w * 0.02),
      ),
      sipPaint,
    );

    final sleeveRect = Rect.fromLTWH(w * 0.31, h * 0.52, w * 0.38, h * 0.16);
    final sleevePath = Path()
      ..moveTo(sleeveRect.left, sleeveRect.top)
      ..lineTo(sleeveRect.right, sleeveRect.top)
      ..lineTo(sleeveRect.right - w * 0.025, sleeveRect.bottom)
      ..lineTo(sleeveRect.left + w * 0.025, sleeveRect.bottom)
      ..close();
    final sleevePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [kLogoNavy, kLogoBlue, kLogoViolet],
      ).createShader(sleeveRect);
    canvas.drawPath(sleevePath, sleevePaint);
    canvas.drawPath(
      sleevePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.36, h * 0.42),
      Offset(w * 0.34, h * 0.73),
      shinePaint,
    );

    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final wave = Path()..moveTo(w * 0.35, h * 0.49);
    for (double x = w * 0.35; x <= w * 0.65; x += w * 0.04) {
      wave.lineTo(
        x,
        h * 0.49 + math.sin(t * math.pi * 2 + x * 0.08) * 4,
      );
    }
    canvas.drawPath(wave, wavePaint);

    final steamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final phase = ((t + i * 0.2) % 1.0);
      final rise = math.sin(phase * math.pi);
      steamPaint.color = Colors.white.withValues(alpha: 0.24 + rise * 0.56);
      final x = w * (0.39 + i * 0.11);
      final y = h * (0.12 - rise * 0.06);
      final steam = Path()
        ..moveTo(x, y + h * 0.16)
        ..cubicTo(
          x + (i.isEven ? -w * 0.055 : w * 0.055),
          y + h * 0.11,
          x + (i.isEven ? w * 0.055 : -w * 0.055),
          y + h * 0.055,
          x,
          y,
        );
      canvas.drawPath(steam, steamPaint);
    }

    final sparklePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final phase = ((t + i * 0.18) % 1.0);
      final pulse = 0.45 + 0.55 * math.sin(phase * math.pi);
      sparklePaint.color = [
        const Color(0xFF8EA0FF),
        kCream,
        Colors.white,
        kLogoViolet
      ][i]
          .withValues(alpha: 0.42 + pulse * 0.34);
      final center = Offset(
        w * (0.16 + i * 0.2),
        h * (0.2 + (i.isEven ? 0.08 : 0.0)) - pulse * 11,
      );
      canvas.drawCircle(center, 3.5 + pulse * 2, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_CoffeeHeroCupPainter old) => true;
}

// ─── Coffee Illustration (Page 1) ────────────────────────────────────────────────────

class _CoffeeIllustration extends StatefulWidget {
  final int page;
  const _CoffeeIllustration({required this.page});

  @override
  State<_CoffeeIllustration> createState() => _CoffeeIllustrationState();
}

class _CoffeeIllustrationState extends State<_CoffeeIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _steam;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _steam = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scattered grain dots
          Positioned(
            top: 24,
            left: 48,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: const Icon(Icons.grain, color: Colors.white38, size: 22),
            ),
          ),
          Positioned(
            bottom: 52,
            right: 16,
            child: Transform.rotate(
              angle: -math.pi / 15,
              child: const Icon(Icons.grain, color: Colors.white24, size: 28),
            ),
          ),
          Positioned(
            top: 80,
            right: 4,
            child: Transform.rotate(
              angle: math.pi / 2,
              child: const Icon(Icons.grain, color: Colors.white54, size: 18),
            ),
          ),

          // Cup SVG via CustomPainter
          AnimatedBuilder(
            animation: _steam,
            builder: (context, _) => CustomPaint(
              size: const Size(190, 190),
              painter: _CupPainter(steamOpacity: _steam.value),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cup Painter ─────────────────────────────────────────────────────────────

class _CupPainter extends CustomPainter {
  final double steamOpacity;
  _CupPainter({required this.steamOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // ── Steam paths ──────────────────────────────────────────────────────
    final steamPaths = [
      _steamPath(w * 0.33, h * 0.06, h * 0.28),
      _steamPath(w * 0.50, h * 0.04, h * 0.28),
      _steamPath(w * 0.67, h * 0.06, h * 0.28),
    ];

    final delays = [0.0, 0.2, 0.4];
    for (int i = 0; i < steamPaths.length; i++) {
      final opacity = ((steamOpacity - delays[i]).clamp(0.0, 0.8)) / 0.8;
      paint.color = Colors.white.withValues(alpha: opacity * 0.85);
      canvas.drawPath(steamPaths[i], paint);
    }

    paint.color = Colors.white;

    // ── Cup body ─────────────────────────────────────────────────────────
    final bodyLeft = w * 0.12;
    final bodyRight = w * 0.88;
    final bodyTop = h * 0.375;
    final bodyBottom = h * 0.95;
    final radius = w * 0.1;

    final bodyPath = Path()
      ..moveTo(bodyLeft + radius, bodyTop)
      ..lineTo(bodyRight - radius, bodyTop)
      ..arcToPoint(Offset(bodyRight, bodyTop + radius),
          radius: Radius.circular(radius))
      ..lineTo(bodyRight, bodyBottom - radius)
      ..arcToPoint(Offset(bodyRight - radius, bodyBottom),
          radius: Radius.circular(radius))
      ..lineTo(bodyLeft + radius, bodyBottom)
      ..arcToPoint(Offset(bodyLeft, bodyBottom - radius),
          radius: Radius.circular(radius))
      ..lineTo(bodyLeft, bodyTop + radius)
      ..arcToPoint(Offset(bodyLeft + radius, bodyTop),
          radius: Radius.circular(radius))
      ..close();

    canvas.drawPath(bodyPath, paint..style = PaintingStyle.stroke);

    // ── Handle ────────────────────────────────────────────────────────────
    final handleLeft = bodyRight;
    final handleTop = h * 0.44;
    final handleBottom = h * 0.70;
    final handleRight = w * 1.05;

    final handlePath = Path()
      ..moveTo(handleLeft, handleTop)
      ..lineTo(handleRight - w * 0.06, handleTop)
      ..arcToPoint(Offset(handleRight, handleTop + w * 0.07),
          radius: Radius.circular(w * 0.07))
      ..lineTo(handleRight, handleBottom - w * 0.07)
      ..arcToPoint(Offset(handleRight - w * 0.06, handleBottom),
          radius: Radius.circular(w * 0.07))
      ..lineTo(handleLeft, handleBottom);

    canvas.drawPath(handlePath, paint);
  }

  Path _steamPath(double x, double startY, double height) {
    final path = Path();
    path.moveTo(x, startY + height);
    path.cubicTo(
      x - 8,
      startY + height * 0.66,
      x + 8,
      startY + height * 0.33,
      x,
      startY,
    );
    return path;
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.steamOpacity != steamOpacity;
}

// ─── Phone Mockup (Page 2) ─────────────────────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 360,
      decoration: BoxDecoration(
        color: kPhoneBg,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF0F172A), width: 7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            // White inner content
            Positioned.fill(
              top: 0,
              child: Column(
                children: [
                  // Dynamic island notch
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 72,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  // App content
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: Row(
                              children: [
                                // Logo
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            kPrimary.withValues(alpha: 0.15)),
                                    color: kSlate50,
                                  ),
                                  child: const Icon(Icons.coffee,
                                      size: 16, color: kPrimary),
                                ),
                                const Spacer(),
                                const Icon(Icons.shopping_bag_outlined,
                                    size: 18, color: kPrimary),
                              ],
                            ),
                          ),
                          // Section title
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MORNING FUEL',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w600,
                                      color: kSlate500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    'Special Menu',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Menu items
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                _MenuItem(
                                  icon: Icons.coffee,
                                  label: 'Latte',
                                  price: '4.50 EGP',
                                  selected: false,
                                ),
                                SizedBox(height: 6),
                                _MenuItem(
                                  icon: Icons.local_drink,
                                  label: 'Mango Smoothie',
                                  price: '5.25 EGP',
                                  selected: true,
                                ),
                                SizedBox(height: 6),
                                Opacity(
                                  opacity: 0.55,
                                  child: _MenuItem(
                                    icon: Icons.icecream,
                                    label: 'Chocolate Milkshake',
                                    price: '3.75 EGP',
                                    selected: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Bottom nav
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: kSlate100),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Icon(Icons.home, color: kPrimary, size: 18),
                                Icon(Icons.favorite_border,
                                    color: kSlate300, size: 18),
                                Icon(Icons.person_outline,
                                    color: kSlate300, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  final bool selected;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.price,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? kPrimary : kSlate50,
        borderRadius: BorderRadius.circular(12),
        border: selected ? null : Border.all(color: kSlate100),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.2)
                  : kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(icon, size: 16, color: selected ? Colors.white : kPrimary),
          ),
          const SizedBox(width: 8),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : kSlate800,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 8,
                    color: selected ? Colors.white70 : kSlate500,
                  ),
                ),
              ],
            ),
          ),
          // Action icon
          Icon(
            selected ? Icons.check_circle : Icons.add_circle_outline,
            size: 16,
            color: selected ? Colors.white : kPrimary,
          ),
        ],
      ),
    );
  }
}
