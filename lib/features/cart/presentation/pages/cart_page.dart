import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/supabase_cart_item.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const _primaryColor = Color(0xFF2D3194);
  static const _bgColor = Color(0xFFF6F6F8);

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                content: Text(context.tr('Order placed successfully!',
                    'تم تأكيد الطلب بنجاح!')),
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
                  const CircularProgressIndicator(color: _primaryColor),
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                        context.tr('Your cart is empty', 'سلة المشتريات فارغة'),
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 16)),
                  ],
                ),
              );
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
                  total: subtotal,
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

// ─── Cart Item Card ───────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final SupabaseCartItem item;
  static const _primaryColor = Color(0xFF2D3194);

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: _primaryColor.withOpacity(0.1),
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
                  item.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('\$${item.price.toStringAsFixed(2)}',
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
          color: const Color(0xFF2D3194).withOpacity(0.1),
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
  final double total;
  static const _primaryColor = Color(0xFF2D3194);

  const _OrderSummary({
    required this.subtotal,
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
              value: '\$${subtotal.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _SummaryRow(
            label: context.tr('Total', 'الإجمالي'),
            value: '\$${(total > 0 ? total : 0.0).toStringAsFixed(2)}',
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
