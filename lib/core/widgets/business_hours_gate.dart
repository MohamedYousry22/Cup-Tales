import 'dart:async';

import 'package:flutter/material.dart';

import '../services/business_hours_service.dart';
import '../theme/app_colors.dart';

class BusinessHoursGate extends StatefulWidget {
  final Widget child;

  const BusinessHoursGate({super.key, required this.child});

  @override
  State<BusinessHoursGate> createState() => _BusinessHoursGateState();
}

class _BusinessHoursGateState extends State<BusinessHoursGate>
    with WidgetsBindingObserver {
  Timer? _timer;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isOpen = BusinessHoursService.isOpen();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _refresh() {
    final isOpen = BusinessHoursService.isOpen();
    if (mounted && isOpen != _isOpen) {
      setState(() => _isOpen = isOpen);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOpen) return widget.child;
    return const _ClosedForBusinessView();
  }
}

class _ClosedForBusinessView extends StatelessWidget {
  const _ClosedForBusinessView();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFF7F7FC),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 184,
                      height: 184,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 34,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      isArabic ? 'نستناكم قريبًا ☕' : 'See you soon ☕',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'كاب تيلز مغلق الآن'
                          : 'Cup Tales is currently closed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isArabic ? 'مواعيد العمل يوميًا' : 'Daily hours',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            isArabic
                                ? 'من 7:30 صباحًا حتى 12:30 بعد منتصف الليل'
                                : '7:30 AM – 12:30 AM',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      isArabic
                          ? 'يرجى الانتظار قليلًا حتى تبدأ مواعيد العمل، وسنكون سعداء بتحضير طلبك فور فتح التطبيق.'
                          : 'Please wait until business hours begin. We will be happy to prepare your order as soon as the app opens.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.55,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
