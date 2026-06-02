import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/supabase_cart_item.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../../../../core/widgets/antigravity_loader.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/utils/translation_helper.dart';
import '../../../../core/routing/app_router.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const _primaryColor = Color(0xFF2D3194);

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('Your Cart', 'سلة المشتريات'),
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartCheckedOut) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr(
                    'Order placed successfully!', 'تم تأكيد الطلب بنجاح!')),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CartLoading || state is CartCheckingOut) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AntigravityLoaderCore(size: 80),
                  const SizedBox(height: 16),
                  Text(
                    state is CartCheckingOut
                        ? context.tr(
                            'Placing your order...', 'جاري تأكيد طلبك...')
                        : context.tr('Loading cart...', 'جاري تحميل السلة...'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (state is CartLoaded) {
            if (state.items.isEmpty) {
              return const _EmptyCartView();
            }

            final subtotal = state.subtotal;

            return Column(
              children: [
                // ── Item list ────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: () => context.read<CartCubit>().loadCart(),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...state.items.map((item) => _CartItemCard(item: item)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                _OrderSummary(
                  subtotal: subtotal,
                  discount: state.discount,
                  total: state.total,
                ),
              ],
            );
          }

          if (state is CartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CartCubit>().loadCart(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor),
                    child: Text(context.loc.retry,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  static const _primaryColor = Color(0xFF2D3194);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 44),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF3F4FF),
                      border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 0.16,
                          child: Image.asset(
                            'assets/images/logo/logo.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 54,
                          color: _primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr('Your cart is empty', 'سلة المشتريات فارغة'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF161A5C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(
                      'Pick your favorite cup and we will keep it ready for you.',
                      'اختار مشروبك المفضل، وإحنا هنجهزه لك بكل حب.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.home,
                        (route) => false,
                      ),
                      icon: const Icon(Icons.local_cafe_rounded),
                      label: Text(context.tr('Browse Menu', 'تصفح القائمة')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
    );
  }
}

// ─── Cart Item Card ───────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final SupabaseCartItem item;
  static const _primaryColor = Color(0xFF2D3194);

  const _CartItemCard({required this.item});

  String _sizeLabel(BuildContext context, String? size) {
    if (size == null || size.trim().isEmpty) {
      return context.loc.isAr ? 'وسط' : 'Medium';
    }
    final isAr = context.loc.isAr;
    switch (size.toUpperCase()) {
      case 'S':
        return isAr ? 'صغير' : 'Small';
      case 'M':
        return isAr ? 'وسط' : 'Medium';
      case 'L':
        return isAr ? 'كبير' : 'Large';
      case 'XL':
        return isAr ? 'إكس لارج' : 'X-Large';
      default:
        return size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    final size = _sizeLabel(context, item.selectedSize);

    // Build options subtitle: Map<groupName, choiceName> → "group: choice, ..."
    final optionsMap = item.selectedOptions; // Map<String, String>
    final optionStr = optionsMap.isNotEmpty
        ? optionsMap.entries.map((e) => '${e.key}: ${e.value}').join(' · ')
        : '';

    // Build addons subtitle: List<Map> → "addon1, addon2, ..."
    final addonsList = item.selectedAddons; // List<Map<String, dynamic>>
    final addonsStr = addonsList.isNotEmpty
        ? addonsList
            .map((a) =>
                (isAr ? a['name']?.toString() : a['name_en']?.toString()) ??
                a['name']?.toString() ??
                '')
            .where((s) => s.isNotEmpty)
            .join(', ')
        : '';

    final categoryOption =
        item.selectedOption == null ? '' : '${item.selectedOption}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _primaryColor.withValues(alpha: 0.1),
            ),
            child: item.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.local_cafe, color: _primaryColor),
                    ),
                  )
                : const Icon(Icons.local_cafe, color: _primaryColor),
          ),
          const SizedBox(width: 12),

          // Product info + qty controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translateProductName(
                    context,
                    item.productName,
                    item.productNameAr,
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // ── Size / category option chip ───────────────────────────
                if (optionStr.isEmpty &&
                    _buildSizeOptionLabel(size, categoryOption).isNotEmpty) ...[
                  _buildChip(
                    _buildSizeOptionLabel(size, categoryOption),
                    color: _primaryColor,
                  ),
                ],
                // ── Option group selections ───────────────────────────────
                if (optionStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildChip(optionStr, color: const Color(0xFF5C6BC0)),
                ],
                // ── Add-ons ───────────────────────────────────────────────
                if (addonsStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildChip(
                    '${context.tr("+ Addons", "+ إضافات")}: $addonsStr',
                    color: Colors.orange.shade700,
                  ),
                ],
                const SizedBox(height: 4),
                Text('${item.price.toStringAsFixed(2)} ${context.loc.egp}',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () =>
                          context.read<CartCubit>().decreaseQuantity(item),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () =>
                          context.read<CartCubit>().increaseQuantity(item),
                    ),
                    const Spacer(),
                    // Delete
                    GestureDetector(
                      onTap: () => context.read<CartCubit>().removeItem(item),
                      child: Icon(Icons.delete_outline,
                          color: Colors.red.shade300),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSizeOptionLabel(String size, String categoryOption) {
    if (categoryOption.isNotEmpty) return categoryOption;
    return size;
  }

  Widget _buildChip(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF2D3194).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF2D3194)),
      ),
    );
  }
}

// ─── Order Summary ────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;
  static const _primaryColor = Color(0xFF2D3194);

  const _OrderSummary({
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: context.tr('Subtotal', 'المجموع الفرعي'),
              value: '${subtotal.toStringAsFixed(2)} ${context.loc.egp}'),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              label: context.tr('Discount', 'الخصم'),
              value: '- ${discount.toStringAsFixed(2)} ${context.loc.egp}',
              valueColor: Colors.green,
            ),
          ],
          const Divider(height: 24),
          _SummaryRow(
            label: context.tr('Total', 'الإجمالي'),
            value:
                '${(total > 0 ? total : 0.0).toStringAsFixed(2)} ${context.loc.egp}',
            bold: true,
            valueColor: _primaryColor,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: Text(
                context.tr('Checkout', 'إتمام الطلب'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 17 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: Colors.black87)),
        Text(value, style: style.copyWith(color: valueColor ?? Colors.black87)),
      ],
    );
  }
}
