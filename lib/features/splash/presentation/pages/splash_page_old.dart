import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';
import '../../../../core/routing/app_router.dart';

// ΓöÇΓöÇ Palette ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
const Color _bg = Color(0xFF1A1D6E);
const Color _primary = Color(0xFF2D3194);
const Color _accent = Color(0xFF4A4FBF);

// =============================================================================
// CUP GEOMETRY  (built once at module level ΓÇö never re-allocated)
// =============================================================================

final Path _cachedBodyPath = _buildBodyPath();
final Path _cachedLidPath = _buildLidPath();

// Path metrics pre-computed ΓÇö never call computeMetrics() per frame
final _bodyMetrics = _cachedBodyPath.computeMetrics().toList(growable: false);
final _lidMetrics = _cachedLidPath.computeMetrics().toList(growable: false);

Path _buildBodyPath() {
  const w = 180.0, h = 220.0, lidH = 20.0, br = 18.0;
  const tl = w * 0.10, tr = w * 0.90;
  const bl = w * 0.18, br2 = w * 0.82;
  const bot = h - 2.0;
  return Path()
    ..moveTo(tl, lidH)
    ..lineTo(bl, bot - br)
    ..arcToPoint(const Offset(bl + br, bot),
        radius: const Radius.circular(br), clockwise: true)
    ..lineTo(br2 - br, bot)
    ..arcToPoint(const Offset(br2, bot - br),
        radius: const Radius.circular(br), clockwise: true)
    ..lineTo(tr, lidH)
    ..close();
}

Path _buildLidPath() {
  return Path()
    ..addRRect(RRect.fromLTRBR(
        180 * 0.06, 0, 180 * 0.94, 20, const Radius.circular(6)));
}

// =============================================================================
// SPLASH PAGE
// =============================================================================

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // ΓöÇΓöÇ Animation controllers ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  late AnimationController _masterCtrl; // full sequence 3.2 s
  late AnimationController _waveCtrl; // liquid surface ΓÇö looping
  late AnimationController _steamCtrl; // steam wisps ΓÇö looping
  late AnimationController _bgCtrl; // background drift ΓÇö looping

  late Animation<double> _bgOpacity;
  late Animation<double> _cupReveal;
  late Animation<double> _fillLevel;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _glowAmt;
  late Animation<double> _taglineT;

  // ΓöÇΓöÇ State ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  bool _animReady = false; // flips after frame 1 ΓåÆ start drawing
  bool _navReady = false; // flips after animation completes
  bool _hasNavigated = false;
  SplashState? _pendingState;

  // ΓöÇΓöÇ Cubit ΓÇö owned here to avoid BlocProvider rebuild on animation ticks ΓöÇΓöÇ
  final SplashCubit _cubit = SplashCubit();

  @override
  void initState() {
    super.initState();
    debugPrint('[Splash] initState');

    // ΓöÇΓöÇ Allocate controllers (no IO, very cheap) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _steamCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20));

    // ΓöÇΓöÇ Wire animations ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    _bgOpacity = _anim(_masterCtrl, 0.00, 0.10, Curves.easeOut);
    _cupReveal = _anim(_masterCtrl, 0.00, 0.40, Curves.easeOut);
    _fillLevel = _anim(_masterCtrl, 0.30, 0.90, Curves.easeInOut);
    _logoFade = _anim(_masterCtrl, 0.62, 0.94, Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.62, 0.94, curve: Curves.easeOutBack)));
    _glowAmt = _anim(_masterCtrl, 0.86, 1.00, Curves.easeIn);
    _taglineT = _anim(_masterCtrl, 0.76, 0.96, Curves.easeIn);

    // ΓöÇΓöÇ After frame 1: start everything ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // Frame 1 is a plain Scaffold ΓÇö trivially cheap so Android immediately
    // replaces the native launch window. Everything animated starts here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('[Splash] first frame committed ΓÇö starting animations');

      _masterCtrl.forward().then((_) {
        debugPrint('[Splash] master animation complete');
        if (!mounted || _hasNavigated) return;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted || _hasNavigated) return;
          setState(() => _navReady = true);
          _tryNav();
        });
      });
      _waveCtrl.repeat();
      _steamCtrl.repeat();
      _bgCtrl.repeat();

      // Start cubit (awaits di.appReady internally ΓÇö no blocking here)
      _cubit.initSplash();

      setState(() => _animReady = true);
    });

    // ΓöÇΓöÇ Hard safety fallback ΓÇö should NEVER fire in normal flow ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    Future.delayed(const Duration(seconds: 9), () {
      if (!mounted || _hasNavigated) return;
      debugPrint('[Splash] EMERGENCY FALLBACK ΓÇö normal nav did not fire!');
      _hasNavigated = true;
      Navigator.pushReplacementNamed(
        context,
        (_pendingState is SplashNavigateToOnboarding)
            ? AppRouter.onboarding
            : AppRouter.home,
      );
    });
  }

  /// Helper: 0ΓåÆ1 tween with interval on the master controller.
  Animation<double> _anim(
      AnimationController ctrl, double begin, double end, Curve curve) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: ctrl, curve: Interval(begin, end, curve: curve)));
  }

  void _tryNav() {
    if (_hasNavigated || !_navReady || _pendingState == null) return;
    _hasNavigated = true;
    debugPrint('[Splash] navigating ΓåÆ ${_pendingState.runtimeType}');
    final route = (_pendingState is SplashNavigateToHome)
        ? AppRouter.home
        : AppRouter.onboarding;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _waveCtrl.dispose();
    _steamCtrl.dispose();
    _bgCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    // BlocProvider + BlocListener always wrap the entire widget tree so that
    // _pendingState is captured on ANY frame ΓÇö including the cheap frame 1.
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (_, state) {
          debugPrint('[Splash] BlocListener: $state');
          _pendingState = state;
          _tryNav(); // no-op if _navReady is not yet true
        },
        child: _animReady ? _buildAnimated(context) : _buildStatic(),
      ),
    );
  }

  // ΓöÇΓöÇ Frame 1: static placeholder ΓÇö zero render cost ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildStatic() => const Scaffold(backgroundColor: _bg);

  // ΓöÇΓöÇ Frame 2+: full animated splash ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildAnimated(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const cupW = 180.0;
    const cupH = 220.0;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background: coffee beans + mini cups + radial glow
          AnimatedBuilder(
            animation: Listenable.merge([_bgCtrl, _bgOpacity]),
            builder: (_, __) => RepaintBoundary(
              child: CustomPaint(
                painter:
                    _BgPainter(t: _bgCtrl.value, opacity: _bgOpacity.value),
                size: Size(size.width, size.height),
              ),
            ),
          ),

          // Steam (shown only after liquid is 38% filled)
          AnimatedBuilder(
            animation: Listenable.merge([_steamCtrl, _fillLevel]),
            builder: (_, __) {
              final op = (_fillLevel.value - 0.38).clamp(0.0, 1.0);
              if (op == 0) return const SizedBox.shrink();
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _SteamPainter(
                    _steamCtrl.value,
                    center:
                        Offset(size.width / 2, size.height / 2 - cupH / 2 - 20),
                    opacity: op,
                  ),
                  size: Size(size.width, size.height),
                ),
              );
            },
          ),

          // Cup + liquid + logo
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_masterCtrl, _waveCtrl]),
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  // Glow halo (only near end)
                  if (_glowAmt.value > 0)
                    Container(
                      width: cupW + 60,
                      height: cupH + 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.50 * _glowAmt.value),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),

                  // Cup silhouette + liquid fill
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _CupPainter(
                        reveal: _cupReveal.value,
                        fillLevel: _fillLevel.value,
                        wavePhase: _waveCtrl.value,
                      ),
                      size: const Size(cupW, cupH),
                    ),
                  ),

                  // Logo clipped to cup body
                  ClipPath(
                    clipper: _CupBodyClipper(),
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: SizedBox(
                          width: cupW * 0.82,
                          height: cupH * 0.72,
                          child: Image.asset(
                            'assets/images/logo/logo_foreground.png',
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tagline at bottom
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _taglineT,
              builder: (_, __) => Opacity(
                opacity: _taglineT.value,
                child: const Text(
                  'CUP TALES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUP CLIPPER
// =============================================================================

class _CupBodyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size _) => _cachedBodyPath;
  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

// =============================================================================
// PAINTERS
// =============================================================================

/// Cup body + lid outline (progressive reveal) and liquid fill.
class _CupPainter extends CustomPainter {
  final double reveal;
  final double fillLevel;
  final double wavePhase;
  const _CupPainter(
      {required this.reveal, required this.fillLevel, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // Faint cup body fill ΓÇö visible from frame 2
    canvas.drawPath(
        _cachedBodyPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.09)
          ..style = PaintingStyle.fill);

    // Liquid fill
    if (fillLevel > 0) {
      canvas.save();
      canvas.clipPath(_cachedBodyPath);

      const lidH = 20.0;
      const bodyH = 220.0 - 2.0 - lidH;
      final surfaceY = lidH + bodyH * (1.0 - fillLevel);
      final waveAmp = 4.5 * sin(fillLevel * pi).clamp(0.2, 1.0);
      const w = 180.0;

      final liqPath = Path()
        ..moveTo(0, 220)
        ..lineTo(0, surfaceY);
      // Step=4 for fewer path points (45 points vs 180)
      for (double x = 0; x <= w; x += 4) {
        liqPath.lineTo(
            x, surfaceY + sin((x / w * 2 * pi) + wavePhase * 2 * pi) * waveAmp);
      }
      liqPath
        ..lineTo(w, 220)
        ..close();

      canvas.drawPath(
          liqPath,
          Paint()
            ..color = _primary.withValues(alpha: 0.90)
            ..style = PaintingStyle.fill);

      canvas.restore();
    }

    // Progressive outline using pre-cached metrics ΓÇö no computeMetrics() call
    if (reveal > 0) {
      final outlinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final m in _bodyMetrics) {
        canvas.drawPath(m.extractPath(0, m.length * reveal), outlinePaint);
      }
      for (final m in _lidMetrics) {
        canvas.drawPath(m.extractPath(0, m.length * reveal), outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CupPainter old) =>
      old.reveal != reveal ||
      old.fillLevel != fillLevel ||
      old.wavePhase != wavePhase;
}

/// Three smooth steam wisps.
class _SteamPainter extends CustomPainter {
  final double t;
  final Offset center;
  final double opacity;
  const _SteamPainter(this.t, {required this.center, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    const offsets = [-26.0, 0.0, 26.0];
    const phases = [0.0, 0.33, 0.66];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final progress = (t + phases[i]) % 1.0;
      final fade = sin(progress * pi).clamp(0.0, 1.0);
      final alpha = fade * opacity * 0.45;
      if (alpha < 0.01) continue;
      paint.color = Colors.white.withValues(alpha: alpha);

      final startY = center.dy + 8;
      final endY = center.dy - 45 - progress * 55;
      final cx = center.dx + offsets[i];

      canvas.drawPath(
          Path()
            ..moveTo(cx, startY)
            ..cubicTo(
                cx + 16 * sin(progress * pi),
                startY - (startY - endY) * 0.35,
                cx - 16 * sin(progress * pi + 1.0),
                startY - (startY - endY) * 0.70,
                cx,
                endY),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter old) =>
      old.t != t || old.opacity != opacity;
}

/// Background: radial glow + coffee beans + mini cup outlines.
class _BgPainter extends CustomPainter {
  final double t;
  final double opacity;
  const _BgPainter({required this.t, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            _accent.withValues(alpha: 0.25 * opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final rng = Random(13);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int i = 0; i < 8; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * 2 * pi;
      final dx = sin(t * 2 * pi + phase) * 4;
      final dy = cos(t * 2 * pi + phase) * 6;
      stroke.color =
          Colors.white.withValues(alpha: (0.12 + rng.nextDouble() * 0.10) * opacity);

      if (i % 2 == 0) {
        final bw = 15.0 + rng.nextDouble() * 12;
        final bh = bw * 0.60;
        canvas.save();
        canvas.translate(bx + dx, by + dy);
        canvas.rotate(rng.nextDouble() * pi);
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
            stroke);
        canvas.restore();
      } else {
        final sc = 0.12 + rng.nextDouble() * 0.08;
        canvas.save();
        canvas.translate(bx + dx, by + dy);
        canvas.scale(sc);
        canvas.translate(-90, -110);
        canvas.drawPath(_cachedBodyPath, stroke);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) =>
      old.t != t || old.opacity != opacity;
}
