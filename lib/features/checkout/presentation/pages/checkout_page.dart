import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../../../core/utils/phone_validator.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _driveThruNoteController =
      TextEditingController();
  bool _isBranchPickerExpanded = false;
  bool _isAddingAddress = false;

  @override
  void dispose() {
    _promoController.dispose();
    _addressController.dispose();
    _driveThruNoteController.dispose();
    super.dispose();
  }

  Future<bool> _ensureCustomerPhone() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    String currentPhone = '';
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('phone')
          .eq('id', user.id)
          .maybeSingle();
      currentPhone = profile?['phone']?.toString().trim() ?? '';
      if (EgyptianPhoneValidator.isValid(currentPhone)) return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Could not check your phone number. Please try again.',
              'تعذر التحقق من رقم الهاتف، يرجى المحاولة مرة أخرى.',
            ),
          ),
        ),
      );
      return false;
    }

    if (!mounted) return false;
    var phoneValue = currentPhone;
    var isSaving = false;
    String? validationError;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            context.tr(
              'Add your phone number',
              'أضف رقم هاتفك',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'A valid phone number is required for every order so the branch can contact you.',
                  'لازم تضيف رقم هاتف صحيح لكل الطلبات حتى يقدر الفرع يتواصل معك.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: currentPhone,
                enabled: !isSaving,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (value) {
                  phoneValue = value.trim();
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: context.tr('Phone number', 'رقم الهاتف'),
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  errorText: validationError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSaving ? null : () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!EgyptianPhoneValidator.isValid(phoneValue)) {
                        setDialogState(() {
                          validationError = context.tr(
                            'Enter a valid 11-digit Egyptian phone number.',
                            'اكتب رقم موبايل مصري صحيح مكوّن من 11 رقمًا.',
                          );
                        });
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await Supabase.instance.client.from('profiles').upsert({
                          'id': user.id,
                          'email': user.email ?? '',
                          'phone': phoneValue,
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSaving = false;
                            validationError = context.tr(
                              'Could not save the phone number.',
                              'تعذر حفظ رقم الهاتف.',
                            );
                          });
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.tr('Save changes', 'حفظ التغييرات')),
            ),
          ],
        ),
      ),
    );

    return saved == true;
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

            final checkoutData = state is CheckoutInitial
                ? state
                : state is CheckoutValidatingPromo
                    ? state.data
                    : null;
            if (checkoutData == null) {
              return const Center(child: AntigravityLoaderCore(size: 80));
            }

            final bool isValidatingPromo = state is CheckoutValidatingPromo;
            final promoDiscountValue = checkoutData.promoDiscount;

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
                                appliedPromo: checkoutData.appliedPromo,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 24),

                        _sectionTitle(
                          context.tr('Fulfillment Method', 'طريقة الاستلام'),
                        ),
                        const SizedBox(height: 12),
                        _buildFulfillmentOptions(context, checkoutData),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _buildFulfillmentDetails(
                            context,
                            checkoutData,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- 3. كود الخصم ---
                        _sectionTitle(context.tr('Promo Code', 'كود الخصم')),
                        const SizedBox(height: 12),
                        _PromoCodeField(
                          controller: _promoController,
                          isValidating: isValidatingPromo,
                          appliedPromo: checkoutData.appliedPromo,
                          promoDiscount: promoDiscountValue,
                          promoError: checkoutData.promoError,
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
                        _sectionTitle(
                            context.tr('Payment Method', 'طريقة الدفع')),
                        const SizedBox(height: 16),
                        _buildPaymentMethods(
                          context,
                          checkoutData.selectedMethod,
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // زر التأكيد ثابت في الأسفل
                ConfirmOrderButton(
                  onPressed: () async {
                    final hasPhone = await _ensureCustomerPhone();
                    if (!hasPhone || !context.mounted) return;
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildFulfillmentOptions(
    BuildContext context,
    CheckoutInitial state,
  ) {
    return Column(
      children: [
        _FulfillmentOptionCard(
          title: context.tr('Pickup from branch', 'استلام من الفرع'),
          subtitle: context.tr(
            'Collect your order inside the selected branch',
            'استلم طلبك من داخل الفرع المختار',
          ),
          icon: Icons.storefront_rounded,
          value: 'pickup',
          selectedValue: state.fulfillmentType,
          onTap: () {
            context.read<CheckoutCubit>().selectFulfillmentType('pickup');
            setState(() => _isAddingAddress = false);
          },
        ),
        const SizedBox(height: 10),
        _FulfillmentOptionCard(
          title: 'Drive-thru',
          subtitle: context.tr(
            'Receive your order in your car',
            'استلم طلبك وأنت في سيارتك',
          ),
          icon: Icons.directions_car_filled_rounded,
          value: 'drive_thru',
          selectedValue: state.fulfillmentType,
          onTap: () {
            context.read<CheckoutCubit>().selectFulfillmentType('drive_thru');
            setState(() => _isAddingAddress = false);
          },
        ),
        const SizedBox(height: 10),
        _FulfillmentOptionCard(
          title: context.tr('Home delivery', 'توصيل للمنزل'),
          subtitle: context.tr(
            'Deliver the order to a saved address',
            'وصّل الطلب إلى عنوان محفوظ',
          ),
          icon: Icons.delivery_dining_rounded,
          value: 'delivery',
          selectedValue: state.fulfillmentType,
          onTap: () {
            context.read<CheckoutCubit>().selectFulfillmentType('delivery');
            if (state.savedAddresses.isEmpty) {
              setState(() => _isAddingAddress = true);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFulfillmentDetails(
    BuildContext context,
    CheckoutInitial state,
  ) {
    switch (state.fulfillmentType) {
      case 'drive_thru':
        return Column(
          key: const ValueKey('drive_thru'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _branchSectionHeader(
              context,
              context.tr('Drive-thru branch', 'فرع الـDrive-thru'),
            ),
            const SizedBox(height: 12),
            _buildBranchPicker(context, state),
            const SizedBox(height: 16),
            TextField(
              controller: _driveThruNoteController,
              onChanged: context.read<CheckoutCubit>().updateDriveThruNote,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: context.tr(
                  'Vehicle type and color',
                  'نوع ولون السيارة',
                ),
                hintText: context.tr(
                  'Example: White Toyota Corolla, plate number if available',
                  'مثال: تويوتا كورولا بيضاء، ورقم اللوحة إن أمكن',
                ),
                helperText: context.tr(
                  'When you arrive, mention the order number and that it was placed through the Cup Tales app.',
                  'عند الوصول، اذكر رقم الطلب وأنه تم من تطبيق Cup Tales.',
                ),
                helperMaxLines: 3,
                prefixIcon: const Icon(Icons.directions_car_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      case 'delivery':
        return _buildDeliveryAddresses(context, state);
      case 'pickup':
      default:
        return Column(
          key: const ValueKey('pickup'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _branchSectionHeader(context, context.loc.pickupFromBranch),
            const SizedBox(height: 12),
            _buildBranchPicker(context, state),
          ],
        );
    }
  }

  Widget _branchSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle(title),
        if (!_isBranchPickerExpanded)
          TextButton(
            onPressed: () => setState(() => _isBranchPickerExpanded = true),
            child: Text(
              context.tr('Change', 'تغيير'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryAddresses(
    BuildContext context,
    CheckoutInitial state,
  ) {
    final showInput = _isAddingAddress || state.savedAddresses.isEmpty;
    return Column(
      key: const ValueKey('delivery'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.tr('Delivery address', 'عنوان التوصيل')),
        const SizedBox(height: 12),
        for (final address in state.savedAddresses) ...[
          _SavedAddressCard(
            address: address,
            selected: state.selectedAddress == address,
            onTap: () => context.read<CheckoutCubit>().selectAddress(address),
            onDelete: () async {
              final cubit = context.read<CheckoutCubit>();
              final removed = await cubit.removeSavedAddress(address);
              if (!removed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr(
                      'Could not delete the address',
                      'تعذر حذف العنوان',
                    )),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ],
        if (state.savedAddresses.isNotEmpty && !showInput)
          OutlinedButton.icon(
            onPressed: () => setState(() => _isAddingAddress = true),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.tr('Add another address', 'إضافة عنوان جديد')),
          ),
        if (showInput) ...[
          TextField(
            controller: _addressController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: context.tr('New address', 'العنوان الجديد'),
              hintText: context.tr(
                'Area, street, building, floor and apartment',
                'المنطقة، الشارع، رقم العقار، الدور والشقة',
              ),
              prefixIcon: const Icon(Icons.location_on_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final address = _addressController.text.trim();
                    if (address.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr(
                            'Please enter the complete address',
                            'يرجى كتابة العنوان كاملًا',
                          )),
                        ),
                      );
                      return;
                    }
                    final cubit = context.read<CheckoutCubit>();
                    final saved = await cubit.saveAddress(address);
                    if (!saved) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr(
                              'Could not save the address. Please try again.',
                              'تعذر حفظ العنوان، يرجى المحاولة مرة أخرى.',
                            )),
                          ),
                        );
                      }
                      return;
                    }
                    _addressController.clear();
                    if (mounted) {
                      setState(() => _isAddingAddress = false);
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(context.tr('Save address', 'حفظ العنوان')),
                ),
              ),
              if (state.savedAddresses.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _addressController.clear();
                    setState(() => _isAddingAddress = false);
                  },
                  child: Text(context.tr('Cancel', 'إلغاء')),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // Used when DB branches don't have a separate name_ar/name_en column.
  static const Map<String, String> _branchArMap = {
    'mahalla1': 'فرع المحلة 1 - طريق طنطا',
    'mahalla2': 'فرع المحلة 2 - ش رضا حافظ',
  };
  static const Map<String, String> _branchEnMap = {
    'mahalla1': 'Mahalla Branch 1 (Tanta Road)',
    'mahalla2': 'Mahalla Branch 2 (Reda Hafez St)',
  };
  static const Map<String, String> _areaArMap = {
    'mahalla1': 'المحلة الكبرى',
    'mahalla2': 'المحلة الكبرى',
  };
  static const Map<String, String> _areaEnMap = {
    'mahalla1': 'El Mahalla El Kubra',
    'mahalla2': 'El Mahalla El Kubra',
  };

  Widget _buildBranchPicker(BuildContext context, CheckoutInitial state) {
    if (state.branches.isEmpty) {
      return const Center(child: AntigravityLoaderCore(size: 80));
    }

    final branchesList = state.branches
        .where((branch) => supportedBranchIds.contains(branch.id))
        .toList(growable: false);
    final selectedBranch = state.selectedBranch;

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
    return RadioGroup<String>(
      groupValue: selectedBranch?.id,
      onChanged: (id) {
        if (id != null) {
          final branch = branchesList.firstWhere((item) => item.id == id);
          context.read<CheckoutCubit>().selectBranch(branch);
          setState(() => _isBranchPickerExpanded = false);
        }
      },
      child: Column(
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
              activeColor: AppColors.primary,
              title: Text(branchName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: areaName.isNotEmpty
                  ? Text(areaName,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600))
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context, String selectedMethod) {
    return Column(
      children: [
        PaymentMethodCard(
          title: context.tr('Cash on receipt', 'الدفع كاش عند الاستلام'),
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

class _FulfillmentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _FulfillmentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  final String address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedAddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.location_on : Icons.location_on_outlined,
              color: selected ? AppColors.primary : Colors.grey.shade500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: context.tr('Delete address', 'حذف العنوان'),
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
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
