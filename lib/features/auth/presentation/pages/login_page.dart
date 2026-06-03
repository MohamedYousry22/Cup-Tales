import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/localization/language_state.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/antigravity_loader.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF2D3194);
const _kLogoNavy = Color(0xFF17185A);
const _kLogoBlue = Color(0xFF2D3194);
const _kLogoViolet = Color(0xFF4E46B4);
const _kSlate900 = Color(0xFF0F172A);
const _kSlate400 = Color(0xFF94A3B8);

// ─── Page ────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _backgroundController;
  bool _obscure = true;

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
    // Safety: ensure global loader is hidden if we leave the page abruptly
    CustomLoadingOverlay.hide();
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    context.read<AuthCubit>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPrimary,
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            CustomLoadingOverlay.show(context);
          } else {
            CustomLoadingOverlay.hide();
          }

          if (state is AuthAuthenticated) {
            // Explicit navigation fallback to bypass any reactive lag in AuthGate.
            Navigator.pushReplacementNamed(context, AppRouter.home);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AuthBackdropPainter(
                      progress: _backgroundController.value,
                    ),
                  );
                },
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ── Top: Language toggle ──────────────────────
                        // ── Language toggle ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: BlocBuilder<LanguageCubit, LanguageState>(
                              builder: (context, langState) {
                                final isEn =
                                    langState.language == AppLanguage.en;
                                return _LangToggle(isEn: isEn);
                              },
                            ),
                          ),
                        ),

                        // ── Logo + headline ────────────────────────────
                        Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
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
                            const SizedBox(height: 28),
                            Text(
                              context.tr('Welcome Back', 'مرحباً بعودتك'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                'Please sign in to your account',
                                'من فضلك سجّل دخولك',
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // ── Form ──────────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context.loc.email),
                            const SizedBox(height: 8),
                            _InputField(
                              controller: _emailController,
                              hint: context.tr(
                                'Enter your email',
                                'أدخل بريدك الإلكتروني',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              isArabic: context.isArabic,
                            ),
                            const SizedBox(height: 22),
                            _label(context.loc.password),
                            const SizedBox(height: 8),
                            _InputField(
                              controller: _passwordController,
                              hint: context.tr(
                                'Enter your password',
                                'أدخل كلمة المرور',
                              ),
                              obscure: _obscure,
                              isArabic: context.isArabic,
                              suffix: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _kSlate400,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  if (_emailController.text.isNotEmpty) {
                                    context.read<AuthCubit>().forgotPassword(
                                          _emailController.text,
                                        );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr(
                                            'Please enter your email first',
                                            'يرجى إدخال البريد الإلكتروني أولاً',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  context.loc.forgotPassword,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ── Buttons ───────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            children: [
                              // Sign In
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  if (state is AuthLoading) {
                                    return const SizedBox(
                                      height: 64,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }
                                  return _TappableButton(
                                    onTap: _login,
                                    child: Container(
                                      width: double.infinity,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(51),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        context.loc.login,
                                        style: const TextStyle(
                                          color: _kPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),
                              // Sign up link
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: context.tr(
                                        "Don't have an account? ",
                                        'ليس لديك حساب؟ ',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRouter.register,
                                        ),
                                        child: Text(
                                          context.loc.signUp,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ─── Input Field ─────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool isArabic;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.isArabic = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      style: const TextStyle(color: _kSlate900, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSlate400, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white54, width: 2),
        ),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
}

// ─── Tappable Button ─────────────────────────────────────────────────────────

class _TappableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _TappableButton({required this.onTap, required this.child});

  @override
  State<_TappableButton> createState() => _TappableButtonState();
}

class _TappableButtonState extends State<_TappableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  final double progress;

  _AuthBackdropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF080B2A),
          _kLogoNavy,
          _kLogoBlue,
        ],
        stops: [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, gradientPaint);

    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;
    final wave = Path();
    final base = size.height * 0.18;
    wave.moveTo(0, base);
    for (double x = 0; x <= size.width; x += 28) {
      wave.lineTo(
        x,
        base +
            math.sin((x / size.width * math.pi * 2) + progress * math.pi * 2) *
                18,
      );
    }
    wave
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
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
      0.22,
    );
    glow(
      Offset(size.width * (0.86 + 0.03 * math.cos(progress * math.pi * 2)),
          size.height * 0.68),
      size.width * 0.5,
      _kLogoViolet,
      0.22,
    );
    glow(
      Offset(size.width * 0.52, size.height * 0.94),
      size.width * 0.56,
      const Color(0xFF05071F),
      0.4,
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

    for (int i = 0; i < beanPositions.length; i++) {
      final bean = beanPositions[i];
      final phase = progress * math.pi * 2 + i * 0.73;
      final x = size.width * bean.dx + math.sin(phase) * 4;
      final y = size.height * bean.dy + math.cos(phase * 0.9) * 6;
      final beanScale = 0.72 + (i % 4) * 0.1;
      final beanPaint = Paint()
        ..color =
            const Color(0xFFD2A06C).withValues(alpha: 0.24 + (i % 3) * 0.04);
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
      canvas.drawPath(
        Path()
          ..moveTo(0, -6)
          ..cubicTo(-4, -2, 4, 2, 0, 6),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─── Language Toggle ──────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  final bool isEn;
  const _LangToggle({required this.isEn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: 'EN',
            active: isEn,
            onTap: () =>
                context.read<LanguageCubit>().setLanguage(AppLanguage.en),
          ),
          _Pill(
            label: 'AR',
            active: !isEn,
            onTap: () =>
                context.read<LanguageCubit>().setLanguage(AppLanguage.ar),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? _kPrimary : Colors.white70,
          ),
        ),
      ),
    );
  }
}
