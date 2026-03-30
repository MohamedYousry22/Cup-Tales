import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/auth/data/profile_service.dart';
import '../../../../core/local_storage/hive_service.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/confirm_order_button.dart';
import '../../../../core/models/branch.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfilePhone();
  }

  Future<void> _loadProfilePhone() async {
    try {
      final user = sl<AuthService>().currentUser;
      if (user != null) {
        // 1. Try reading from Hive cache first for an instant zero-lag experience
        final cachedProfile = sl<HiveService>().profileBox.get('current_user') as Map?;
        if (cachedProfile != null) {
          final phone = cachedProfile['phone'] as String?;
          if (phone != null && phone != 'NA' && phone.isNotEmpty) {
            setState(() {
              _walletController.text = phone;
            });
            return; // Cache hit, exit early
          }
        }

        // 2. Fallback to API if cache missed (e.g., cleared data or first run)
        final profile = await sl<ProfileService>().getProfile(user.id);
        final phone = profile?['phone'] as String?;
        if (phone != null && phone != 'NA' && phone.isNotEmpty) {
          setState(() {
            _walletController.text = phone;
          });
          // Update the cache so it's ready for next time
          sl<HiveService>().profileBox.put('current_user', profile);
        }
      }
    } catch (_) {
      // Handle silently (e.g., network timeout) so app doesn't crash on checkout
    }
  }

  @override
  void dispose() {
    _walletController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();

    return BlocProvider(
      create: (_) => sl<CheckoutCubit>(param1: context.read<CartCubit>()),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            context.loc.checkout,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              Navigator.pushReplacementNamed(context, AppRouter.paymentSuccess);
            } else if (state is CheckoutPaymentRedirect) {
              Navigator.pushNamed(context, AppRouter.paymobPayment, arguments: {
                'url': state.url,
                'cubit': context.read<CheckoutCubit>(),
              });
            } else if (state is CheckoutError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is CheckoutProcessing) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
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
                                total: cartState.subtotal -
                                    promoDiscountValue,
                                promoDiscount: promoDiscountValue,
                                appliedPromo: appliedPromoCode,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 24),

                        // --- 2. كود الخصم ---
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
                            if (code.isNotEmpty)
                              context
                                  .read<CheckoutCubit>()
                                  .applyPromoCode(code);
                          },
                          onRemove: () {
                            _promoController.clear();
                            context.read<CheckoutCubit>().removePromoCode();
                          },
                        ),

                        const SizedBox(height: 32),

                        // --- 3. استلام من الفرع ---
                        Text(context.loc.pickupFromBranch,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const SizedBox(height: 12),
                        _buildBranchPicker(context, state),

                        const SizedBox(height: 32),

                        // --- 4. طريقة الدفع ---
                        Text(context.tr('Payment Method', 'طريقة الدفع'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const SizedBox(height: 16),
                        _buildPaymentMethods(context, selectedMethod),

                        if (selectedMethod == 'Wallet') ...[
                          const SizedBox(height: 16),
                          _buildWalletField(context),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // زر التأكيد ثابت في الأسفل
                ConfirmOrderButton(
                  onPressed: () {
                    context.read<CheckoutCubit>().processPayment(
                          walletNumber: selectedMethod == 'Wallet'
                              ? _walletController.text
                              : null,
                        );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBranchPicker(BuildContext context, CheckoutState state) {
    final branchesList =
        state is CheckoutInitial ? state.branches : appBranches;
    final selectedBranch =
        state is CheckoutInitial ? state.selectedBranch : null;

    return Column(
      children: branchesList.map((branch) {
        final isSelected = selectedBranch?.id == branch.id;
        final isEn = Localizations.localeOf(context).languageCode == 'en';
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
            value: branch.id,
            groupValue: selectedBranch?.id,
            onChanged: (_) =>
                context.read<CheckoutCubit>().selectBranch(branch),
            activeColor: AppColors.primary,
            title: Text(isEn ? branch.nameEn : branch.nameAr,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(isEn ? branch.areaEn : branch.areaAr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
        const SizedBox(height: 12),
        PaymentMethodCard(
          title: context.tr('Visa / Mastercard', 'فيزا / ماستركارد'),
          value: 'Visa',
          groupValue: selectedMethod,
          icon: Icons.credit_card,
          onChanged: (v) =>
              context.read<CheckoutCubit>().selectPaymentMethod(v!),
        ),
        const SizedBox(height: 12),
        PaymentMethodCard(
          title: context.loc.mobileWallet,
          value: 'Wallet',
          groupValue: selectedMethod,
          icon: Icons.account_balance_wallet,
          onChanged: (v) =>
              context.read<CheckoutCubit>().selectPaymentMethod(v!),
        ),
      ],
    );
  }

  Widget _buildWalletField(BuildContext context) {
    return TextField(
      controller: _walletController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: '01xxxxxxxxx',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
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
                        ? Colors.green.withOpacity(0.05)
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
                    ? const Center(child: CircularProgressIndicator())
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
          Text('تم تطبيق الكود! وفرت ${promoDiscount.toStringAsFixed(2)} ج.م',
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
    if (error.contains('expired')) return 'الكود منتهي الصلاحية';
    if (error.contains('limit')) return 'تم الوصول للحد الأقصى للاستخدام';
    return 'الكود غير صحيح';
  }
}
