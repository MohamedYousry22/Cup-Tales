import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/utils/translation_helper.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/widgets/antigravity_loader.dart';

// ─── Brand constants shared across all widgets in this file ──────────────────
const _kPrimary = Color(0xFF2D3194);

class OrdersPage extends StatelessWidget {
  final int resetNonce;

  const OrdersPage({super.key, this.resetNonce = 0});

  @override
  Widget build(BuildContext context) {
    return _OrdersView(resetNonce: resetNonce);
  }
}

class _OrdersView extends StatefulWidget {
  final int resetNonce;

  const _OrdersView({required this.resetNonce});

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  final ScrollController _scrollController = ScrollController();
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersCubit>().loadOrders();
    });
  }

  @override
  void didUpdateWidget(covariant _OrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetNonce != widget.resetNonce) {
      _scrollToTop();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
              )
            : null,
        title: Text(
          context.loc.navOrders,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) {
              final hasOrders =
                  state is OrdersLoaded && state.orders.isNotEmpty;
              if (!hasOrders) return const SizedBox.shrink();
              return IconButton(
                tooltip: context.tr('Clear orders', 'مسح الطلبات'),
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: () => _confirmClearOrders(context),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) => _buildBody(state),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Future<void> _confirmClearOrders(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('Clear orders?', 'مسح الطلبات؟')),
        content: Text(
          context.tr(
            'This will remove all your order history from this account.',
            'سيتم مسح كل طلباتك من هذا الحساب.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Clear', 'مسح')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final success = await context.read<OrdersCubit>().clearOrders();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.tr('Orders cleared', 'تم مسح الطلبات')
              : context.tr('Could not clear orders', 'تعذر مسح الطلبات'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state is OrdersLoading || state is OrdersInitial) {
      return const Center(
        child: AntigravityLoaderCore(size: 80),
      );
    }

    if (state is OrdersError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 52, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(state.message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.read<OrdersCubit>().loadOrders(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: Text(context.loc.retry,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (state is OrdersLoaded) {
      final displayed =
          _selectedFilter == 0 ? state.activeOrders : state.historyOrders;
      final emptyLabel = _selectedFilter == 0
          ? context.tr('No active orders', 'لا توجد طلبات حالية')
          : context.tr('No previous orders', 'لا توجد طلبات سابقة');

      return Column(
        children: [
          _OrderFilterBar(
            selectedIndex: _selectedFilter,
            activeCount: state.activeOrders.length,
            historyCount: state.historyOrders.length,
            onChanged: (index) {
              setState(() => _selectedFilter = index);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToTop();
              });
            },
          ),
          Expanded(
            child: displayed.isEmpty
                ? _EmptyState(
                    icon: Icons.receipt_long_rounded,
                    label: emptyLabel,
                  )
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: () => context.read<OrdersCubit>().loadOrders(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) =>
                          _OrderCard(order: displayed[index], displayNumber: displayed.length - index),
                    ),
                  ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _OrderFilterBar extends StatelessWidget {
  final int selectedIndex;
  final int activeCount;
  final int historyCount;
  final ValueChanged<int> onChanged;

  const _OrderFilterBar({
    required this.selectedIndex,
    required this.activeCount,
    required this.historyCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _FilterButton(
              label: context.tr('Current', 'الحالية'),
              count: activeCount,
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _FilterButton(
              label: context.tr('Previous', 'السابقة'),
              count: historyCount,
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF161A5C),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : _kPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : _kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Order Card (Receipt-style) ───────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final int displayNumber;

  const _OrderCard({required this.order, required this.displayNumber});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    if (order.items.isEmpty) return const SizedBox.shrink();

    final shortId = displayNumber.toString();
    final isAr = context.loc.isAr;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Order ID + Status ──────────────────────────────────────
          _buildHeader(context, shortId, isAr),

          // ── Meta: Date + Branch ────────────────────────────────────────────
          _buildMeta(context, isAr),

          // ── Dashed separator ──────────────────────────────────────────────
          _DashedDivider(),

          // ── Item list ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final item in order.items) ...[
                  _ItemRow(item: item, isAr: isAr),
                  if (item != order.items.last)
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ],
              ],
            ),
          ),

          // ── Dashed separator ──────────────────────────────────────────────
          _DashedDivider(),

          // ── Footer: Total ─────────────────────────────────────────────────
          _buildFooter(context),

          // ── Order action ──────────────────────────────────────────────────
          _buildOrderActionButton(context),
        ],
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildOrderActionButton(BuildContext context) {
    final isPending = order.status.toLowerCase().trim() == 'pending';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            if (isPending) {
              final success =
                  await context.read<OrdersCubit>().cancelOrder(order.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? context.tr('Order cancelled', 'تم إلغاء الطلب')
                        : context.tr(
                            'Could not cancel this order. Please try again.',
                            'تعذر إلغاء الطلب. حاول مرة أخرى.',
                          ),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            final cartCubit = context.read<CartCubit>();

            final success = await cartCubit.replaceCartWithItems(order.items);
            if (!context.mounted) return;
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr(
                    'Could not rebuild this order. Please try again.',
                    'تعذر إعادة تجهيز الطلب. حاول مرة أخرى.',
                  )),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            Navigator.pushNamed(context, '/checkout');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: isPending ? Colors.red.shade700 : _kPrimary,
            side: BorderSide(
              color: isPending ? Colors.red.shade700 : _kPrimary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: Icon(
            isPending ? Icons.cancel_outlined : Icons.replay_rounded,
            size: 18,
          ),
          label: Text(
            isPending
                ? context.tr('Cancel order', 'إلغاء الطلب')
                : context.tr('Reorder', 'اطلب مرة أخرى'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String shortId, bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Order ID badge
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 16, color: _kPrimary),
              const SizedBox(width: 6),
              Text(
                '#$shortId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          // Status chip
          _StatusChip(status: order.status),
        ],
      ),
    );
  }

  Widget _buildMeta(BuildContext context, bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _getBranchName(context, order.branchName),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today_rounded,
              size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _formattedDate(order.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final hasDiscount = order.discountAmount > 0 || order.promoCode != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          if (hasDiscount) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Discount', 'الخصم'),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '- ${order.discountAmount.toStringAsFixed(2)} ${context.loc.egp}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Order Total', 'إجمالي الطلب'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${order.totalAmount.toStringAsFixed(2)} ${context.loc.egp}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formattedDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  static const Map<String, String> _branchArMap = {
    'rehab': 'فرع الرحاب',
    'mahalla1': 'فرع المحلة 1 - طريق طنطا',
    'mahalla2': 'فرع المحلة 2 - ش رضا حافظ',
  };

  String _getBranchName(BuildContext context, String branchId) {
    // Task 5: Force Arabic branch names globally, regardless of locale.
    if (branchId.isEmpty) {
      return 'فرع كب تيلز';
    }
    return _branchArMap[branchId] ?? branchId;
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final Color bg;
    final Color fg;

    switch (s) {
      case 'preparing':
      case 'paid':
        bg = _kPrimary.withValues(alpha: 0.10);
        fg = _kPrimary;
        break;
      case 'completed':
      case 'delivered':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        break;
      case 'pending':
        bg = Colors.amber.withValues(alpha: 0.14);
        fg = Colors.amber.shade900;
        break;
      case 'ready':
        bg = Colors.teal.withValues(alpha: 0.12);
        fg = Colors.teal.shade700;
        break;
      case 'cancelled':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        TranslationHelper.translateStatus(context, status),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Item Row (Receipt line) ──────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final OrderItemEntity item;
  final bool isAr;

  const _ItemRow({required this.item, required this.isAr});

  String _sizeLabel(String? size) {
    if (size == null || size.trim().isEmpty) return isAr ? 'وسط' : 'M';
    switch (size.toUpperCase()) {
      case 'S':
        return isAr ? 'صغير' : 'S';
      case 'M':
        return isAr ? 'وسط' : 'M';
      case 'L':
        return isAr ? 'كبير' : 'L';
      case 'XL':
        return isAr ? 'XL' : 'XL';
      default:
        return size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item.displayName(isAr);
    final sizeLabel = _sizeLabel(item.selectedSize);

    // ── Options Map → "group: choice, ..."
    final optionsMap = item.selectedOptions; // Map<String, String>
    final optionStr = optionsMap.isNotEmpty
        ? optionsMap.entries.map((e) => '${e.key}: ${e.value}').join(' · ')
        : '';

    // ── Addons List → "addon1, addon2"
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

    final categoryOptionStr =
        item.selectedOption == null ? '' : '${item.selectedOption}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.hasImage
                  ? Transform.scale(
                      scale: 1.3, // Task 1: Zoom in to crop out text
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                      ),
                    )
                  : _PlaceholderIcon(),
            ),
          ),
          const SizedBox(width: 12),

          // ── Name + size + options ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity badge + name on same line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Qty pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}×',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        optionStr.isNotEmpty
                            ? name
                            : (categoryOptionStr.isNotEmpty
                                ? '$name ($categoryOptionStr)'
                                : (sizeLabel.isNotEmpty
                                    ? '$name ($sizeLabel)'
                                    : name)),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Option groups subtitle ───────────────────────────────
                if (optionStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    optionStr,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.indigo.shade400,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // ── Add-ons subtitle ────────────────────────────────
                if (addonsStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '+ $addonsStr',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 4),

                // Unit price × qty = line total
                Row(
                  children: [
                    Text(
                      '${item.unitPrice.toStringAsFixed(2)} ${context.loc.egp}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (item.quantity > 1) ...[
                      Text(
                        '  ×${item.quantity}  =  ',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(2)} ${context.loc.egp}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
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

// Helper: image placeholder
class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F5),
      child: const Icon(Icons.local_cafe_rounded, color: _kPrimary, size: 22),
    );
  }
}

// ─── Dashed Divider ───────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashGap = 4.0;
          final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
          return Row(
            children: List.generate(count, (_) {
              return Padding(
                padding: const EdgeInsets.only(right: dashGap),
                child: SizedBox(
                  width: dashWidth,
                  height: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFDDDDDD)),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 52, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
