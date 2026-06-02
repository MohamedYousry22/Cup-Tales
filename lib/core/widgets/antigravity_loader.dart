import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens for a premium, high-end feel
// ─────────────────────────────────────────────────────────────────────────────
class _DS {
  static const Color bg = Color(0xFF000000);
  static const Color card = Color(0xFF000000); // Pure black
  static const Color border = Color(0xFF1A1A1A);
  static const Color glowBase = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF6B6B6B);

  static const double cardW      = 148.0;
  static const double cardH      = 175.0; 
  static const double cardRadius = 28.0;
  static const double logoSize   = 36.0; // Optimized size with internal padding
}

/// A global utility to show and hide the CustomLoadingOverlay.
class CustomLoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// Shows the loading overlay. Safe to call multiple times.
  static void show(BuildContext context) {
    if (_overlayEntry != null) return;

    try {
      final overlay = Overlay.of(context);
      _overlayEntry = OverlayEntry(
        builder: (context) => const _CustomLoadingOverlayWidget(),
      );
      overlay.insert(_overlayEntry!);
    } catch (e) {
      debugPrint('[CustomLoadingOverlay] Error showing overlay: $e');
      _overlayEntry = null;
    }
  }

  /// Hides the loader if currently showing. Safe to call even if not showing.
  static void hide() {
    try {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    } catch (e) {
      debugPrint('[CustomLoadingOverlay] Error hiding overlay: $e');
      _overlayEntry = null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root overlay widget
// ─────────────────────────────────────────────────────────────────────────────
class _CustomLoadingOverlayWidget extends StatelessWidget {
  const _CustomLoadingOverlayWidget();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: _PremiumCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 24),
              _GlowingLogoArea(),
              SizedBox(height: 20),
              _InlineDotsText(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium card with animated hairline border
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumCard extends StatefulWidget {
  final Widget child;
  const _PremiumCard({required this.child});

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final angle = _shimmer.value * 2 * pi;
        return CustomPaint(
          painter: _BorderShimmerPainter(angle: angle),
          child: child,
        );
      },
      child: Container(
        width: _DS.cardW,
        height: _DS.cardH,
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(_DS.cardRadius),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Paints a single-pixel rotating shimmer border around the card.
class _BorderShimmerPainter extends CustomPainter {
  final double angle;
  _BorderShimmerPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(_DS.cardRadius),
    );

    // Solid dark border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _DS.border;
    canvas.drawRRect(rRect, basePaint);

    // Rotating highlight arc
    final center = Offset(size.width / 2, size.height / 2);
    final shimmerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle,
        endAngle: angle + pi * 0.6,
        colors: const [
          Colors.transparent,
          Color(0x22FFFFFF),
          Color(0x99FFFFFF),
          Color(0x22FFFFFF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
          center: center, width: size.width, height: size.height));

    canvas.drawRRect(rRect, shimmerPaint);
  }

  @override
  bool shouldRepaint(_BorderShimmerPainter old) => old.angle != angle;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing glow behind the logo
// ─────────────────────────────────────────────────────────────────────────────
class _GlowingLogoArea extends StatefulWidget {
  const _GlowingLogoArea();

  @override
  State<_GlowingLogoArea> createState() => _GlowingLogoAreaState();
}

class _GlowingLogoAreaState extends State<_GlowingLogoArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glow = _pulseAnim.value;
        return SizedBox(
          // Extra space for glow to breathe
          width: _DS.logoSize + 36,
          height: _DS.logoSize + 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer soft glow ring
              Container(
                width: _DS.logoSize + 22 * glow,
                height: _DS.logoSize + 22 * glow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _DS.glowBase.withValues(alpha: 0.04 + 0.05 * glow),
                      blurRadius: 18 + 10 * glow,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),

              // Inner tight glow ring
              Container(
                width: _DS.logoSize + 6,
                height: _DS.logoSize + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _DS.glowBase.withValues(alpha: 0.08 + 0.10 * glow),
                      blurRadius: 8 + 4 * glow,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: AntigravityLoaderCore(size: _DS.logoSize),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Antigravity loader core
// ─────────────────────────────────────────────────────────────────────────────
class AntigravityLoaderCore extends StatefulWidget {
  final double size;
  final double rotationDurationSeconds;
  final double flipDurationSeconds;

  const AntigravityLoaderCore({
    super.key,
    this.size = 32.0,
    this.rotationDurationSeconds = 4.0,
    this.flipDurationSeconds = 4.0,
  });

  @override
  State<AntigravityLoaderCore> createState() => _AntigravityLoaderCoreState();
}

class _AntigravityLoaderCoreState extends State<AntigravityLoaderCore>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _flipCtrl;

  late final Animation<double> _spin;
  late final Animation<double> _flipY1;
  late final Animation<double> _flipX1;
  late final Animation<double> _flipY2;
  late final Animation<double> _flipX2;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: (widget.rotationDurationSeconds * 1000).toInt()),
    )..repeat();

    _flipCtrl = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: (widget.flipDurationSeconds * 1000).toInt()),
    )..repeat();

    _spin = Tween<double>(begin: 0, end: 2 * pi).animate(_spinCtrl);

    const curve = Curves.easeInOutSine;
    _flipY1 = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(
        parent: _flipCtrl, curve: const Interval(0.0, 0.25, curve: curve)));
    _flipX1 = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(
        parent: _flipCtrl, curve: const Interval(0.25, 0.5, curve: curve)));
    _flipY2 = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(
        parent: _flipCtrl, curve: const Interval(0.5, 0.75, curve: curve)));
    _flipX2 = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(
        parent: _flipCtrl, curve: const Interval(0.75, 1.0, curve: curve)));
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinCtrl, _flipCtrl]),
      builder: (context, child) {
        final currentFlipY = _flipY1.value + _flipY2.value;
        final currentFlipX = _flipX1.value + _flipX2.value;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateZ(_spin.value)
          ..rotateY(currentFlipY)
          ..rotateX(currentFlipX);

        return Container(
          width: widget.size,
          height: widget.size,
          // Added internal padding so the logo doesn't touch the edges
          padding: EdgeInsets.all(widget.size * 0.18), 
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(widget.size * 0.22),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/logo/outlined.png',
        fit: BoxFit.contain,
        color: Colors.white,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline animating dots text
// ─────────────────────────────────────────────────────────────────────────────
class _InlineDotsText extends StatefulWidget {
  const _InlineDotsText();

  @override
  State<_InlineDotsText> createState() => _InlineDotsTextState();
}

class _InlineDotsTextState extends State<_InlineDotsText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const _frameDuration = 500;
  static const _frameCount = 4;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _frameDuration * _frameCount),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = lang == 'ar';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final frame = (_ctrl.value * _frameCount).floor() % _frameCount;
        final dots = '.' * frame;
        final baseWord = isArabic ? 'جاري التحميل' : 'Loading';
        final fullText = '$baseWord$dots';
        final maxText = '$baseWord...';

        return Stack(
          alignment: Alignment.center, // Center for both
          children: [
            Opacity(
              opacity: 0,
              child: _label(maxText),
            ),
            _label(fullText),
          ],
        );
      },
    );
  }

  Widget _label(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _DS.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          height: 1.2,
        ),
      );
}
