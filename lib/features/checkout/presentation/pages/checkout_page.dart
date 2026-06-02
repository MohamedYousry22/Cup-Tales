import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/antigravity_loader.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/confirm_order_button.dart';
import '../../../../core/models/branch.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _promoController = TextEditingController();
  bool _isBranchPickerExpanded = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();

    return BlocProvider(
      create: (_) => sl<CheckoutCubit>(param1: context.read<CartCubit>()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.loc.checkout,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              Navigator.pushReplacementNamed(context, AppRouter.paymentSuccess);
            } else if (state is CheckoutError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is CheckoutProcessing) {
              return const Center(
                child: AntigravityLoaderCore(size: 80),
              );
            }

            // Logic to handle state data
            String selectedMethod = 'Cashier';
            double promoDiscountValue = 0.0;
            String? appliedPromoCode;
            String? promoErrorCode;
            final bool isValidatingPromo = state is CheckoutValidatingPromo;

            if (state is CheckoutInitial) {
              selectedMethod = state.selectedMethod;
              promoDiscountValue = state.promoDiscount;
              appliedPromoCode = state.appliedPromo;
              promoErrorCode = state.promoError;
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. ملخص الطلب التفصيلي ---
                        BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) {
                            if (cartState is CartLoaded) {
                              return OrderSummaryCard(
                                items: cartState.items,
                                subtotal: cartState.subtotal,
                                total: cartState.subtotal - promoDiscountValue,
                                promoDiscount: promoDiscountValue,
                                appliedPromo: appliedPromoCode,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 24),

                        // --- 2. استلام من الفرع ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.loc.pickupFromBranch,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                            if (!_isBranchPickerExpanded)
                              TextButton(
                                onPressed: () => setState(
                                    () => _isBranchPickerExpanded = true),
                                child: Text(context.tr('Change', 'تغيير'),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBranchPicker(context, state),

                        const SizedBox(height: 24),

                        // --- 3. كود الخصم ---
                        Text(context.tr('Promo Code', 'كود الخصم'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const SizedBox(height: 12),
                        _PromoCodeField(
                          controller: _promoController,
                          isValidating: isValidatingPromo,
                          appliedPromo: appliedPromoCode,
                          promoDiscount: promoDiscountValue,
                          promoError: promoErrorCode,
                          onApply: () {
                            final code = _promoController.text.trim();
                            if (code.isNotEmpty) {
                              context
                                  .read<CheckoutCubit>()
                                  .applyPromoCode(code);
                            }
                          },
                          onRemove: () {
                            _promoController.clear();
                            context.read<CheckoutCubit>().removePromoCode();
                          },
                        ),

                        const SizedBox(height: 32),

                        // --- 4. طريقة الدفع ---
                        Text(context.tr('Payment Method', 'طريقة الدفع'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const SizedBox(height: 16),
                        _buildPaymentMethods(context, selectedMethod),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // زر التأكيد ثابت في الأسفل
                ConfirmOrderButton(
                  onPressed: () {
                    context
                        .read<CheckoutCubit>()
                        .processPayment(isArabic: context.loc.isAr);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Branch name translation maps ─────────────────────────────────────────
  // Used when DB branches don't have a separate name_ar/name_en column.
  static const Map<String, String> _branchArMap = {
    'rehab': 'فرع الرحاب',
    'mahalla1': 'فرع المحلة 1 - طريق طنطا',
    'mahalla2': 'فرع المحلة 2 - ش رضا حافظ',
  };
  static const Map<String, String> _branchEnMap = {
    'rehab': 'Rehab Branch',
    'mahalla1': 'Mahalla Branch 1 (Tanta Road)',
    'mahalla2': 'Mahalla Branch 2 (Reda Hafez St)',
  };
  static const Map<String, String> _areaArMap = {
    'rehab': 'القاهرة الجديدة',
    'mahalla1': 'المحلة الكبرى',
    'mahalla2': 'المحلة الكبرى',
  };
  static const Map<String, String> _areaEnMap = {
    'rehab': 'New Cairo',
    'mahalla1': 'El Mahalla El Kubra',
    'mahalla2': 'El Mahalla El Kubra',
  };

  Widget _buildBranchPicker(BuildContext context, CheckoutState state) {
    if (state is CheckoutInitial && state.branches.isEmpty) {
      return const Center(child: AntigravityLoaderCore(size: 80));
    }

    final branchesList =
        state is CheckoutInitial ? state.branches : appBranches;
    final selectedBranch =
        state is CheckoutInitial ? state.selectedBranch : null;

    final isEn = Localizations.localeOf(context).languageCode == 'en';

    // If not expanded, show only the selected branch
    if (!_isBranchPickerExpanded && selectedBranch != null) {
      final String branchName = isEn
          ? (_branchEnMap[selectedBranch.id] ?? selectedBranch.nameEn)
          : (_branchArMap[selectedBranch.id] ?? selectedBranch.nameAr);

      final String areaName = isEn
          ? (_areaEnMap[selectedBranch.id] ?? selectedBranch.areaEn)
          : (_areaArMap[selectedBranch.id] ?? selectedBranch.areaAr);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          children: [
            _branchLogoIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branchName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (areaName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(areaName,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      );
    }

    // Expanded View
    return Column(
      children: branchesList.map((branch) {
        final isSelected = selectedBranch?.id == branch.id;

        // Resolve name: prefer model data, fall back to translation map
        final String branchName = isEn
            ? (_branchEnMap[branch.id] ?? branch.nameEn)
            : (_branchArMap[branch.id] ?? branch.nameAr);

        final String areaName = isEn
            ? (_areaEnMap[branch.id] ?? branch.areaEn)
            : (_areaArMap[branch.id] ?? branch.areaAr);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 2 : 1),
          ),
          child: RadioListTile<String>(
            secondary: _branchLogoIcon(size: 30),
            value: branch.id,
            groupValue: selectedBranch?.id,
            onChanged: (id) {
              if (id != null) {
                final b = branchesList.firstWhere((b) => b.id == id);
                context.read<CheckoutCubit>().selectBranch(b);
                setState(() => _isBranchPickerExpanded = false);
              }
            },
            activeColor: AppColors.primary,
            title: Text(branchName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: areaName.isNotEmpty
                ? Text(areaName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethods(BuildContext context, String selectedMethod) {
    return Column(
      children: [
        PaymentMethodCard(
          title: context.tr('Cash at Branch', 'الدفع كاش عند الفرع'),
          value: 'Cashier',
          groupValue: selectedMethod,
          icon: Icons.point_of_sale,
          onChanged: (v) =>
              context.read<CheckoutCubit>().selectPaymentMethod(v!),
        ),
      ],
    );
  }

  Widget _branchLogoIcon({double size = 32}) {
    return Container(
      width: size + 18,
      height: size + 18,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Image.asset(
        'assets/images/logo/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

// --- Widget حقل البرومو كود المصلح (تم حل مشكلة الـ Constraints) ---

class _PromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool isValidating;
  final String? appliedPromo;
  final double promoDiscount;
  final String? promoError;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _PromoCodeField({
    required this.controller,
    required this.isValidating,
    required this.appliedPromo,
    required this.promoDiscount,
    required this.promoError,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasApplied = appliedPromo != null && promoDiscount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: TextField(
                  controller: controller,
                  enabled: !hasApplied && !isValidating,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: context.tr('Enter promo code', 'أدخل كود الخصم'),
                    filled: true,
                    fillColor: hasApplied
                        ? Colors.green.withValues(alpha: 0.05)
                        : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(
                        hasApplied ? Icons.check_circle : Icons.local_offer,
                        color: hasApplied ? Colors.green : AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // استخدام ConstrainedBox لحل مشكلة الـ Infinite Width
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80),
              child: SizedBox(
                height: 52,
                child: isValidating
                    ? const Center(
                        child: AntigravityLoaderCore(size: 24),
                      )
                    : hasApplied
                        ? TextButton(
                            onPressed: onRemove,
                            style: TextButton.styleFrom(
                              minimumSize: Size
                                  .zero, // Overrides global theme if it's set to infinite
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(context.tr('Remove', 'إزالة'),
                                style: const TextStyle(color: Colors.red)))
                        : ElevatedButton(
                            onPressed: onApply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: Size
                                  .zero, // Overrides global theme if it's set to infinite
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(context.tr('Apply', 'تطبيق')),
                          ),
              ),
            ),
          ],
        ),
        if (hasApplied) ...[
          const SizedBox(height: 8),
          Text(
              context.tr(
                'Code applied! You saved ${promoDiscount.toStringAsFixed(2)} ${context.loc.egp}',
                'تم تطبيق الكود! وفرت ${promoDiscount.toStringAsFixed(2)} ${context.loc.egp}',
              ),
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
        if (promoError != null && !hasApplied) ...[
          const SizedBox(height: 8),
          Text(promoErrorCodeTranslate(context, promoError!),
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
      ],
    );
  }

  String promoErrorCodeTranslate(BuildContext context, String error) {
    if (error.contains('expired') || error.contains('صلاحية')) {
      return context.tr('Code has expired', 'الكود منتهي الصلاحية');
    }
    if (error.contains('limit') || error.contains('استنفاد')) {
      return context.tr(
        'Code usage limit has been reached',
        'تم الوصول للحد الأقصى للاستخدام',
      );
    }
    return context.tr('Invalid promo code', 'الكود غير صحيح');
  }
}
