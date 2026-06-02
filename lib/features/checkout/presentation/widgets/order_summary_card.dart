import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translation_helper.dart';

class OrderSummaryCard extends StatelessWidget {
  final List<dynamic> items;
  final double subtotal;
  final double total;
  final double promoDiscount;
  final String? appliedPromo;

  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.total,
    this.promoDiscount = 0.0,
    this.appliedPromo,
  });

  // ── Arabic size labels ─────────────────────────────────────────────────
  static String _sizeLabel(BuildContext context, String? size) {
    // null / empty → default to Medium
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
        return isAr ? 'لارج' : 'Large';
      case 'XL':
        return isAr ? 'إكس لارج' : 'X-Large';
      default:
        return size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPromo = promoDiscount > 0 && appliedPromo != null;
    final double finalTotal = total.clamp(0.0, double.infinity);
    final grouped = _groupByProduct(items);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Text(
              context.tr('Order Summary', 'ملخص الطلب'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item rows (grouped by product) ─────────────────────
                for (int g = 0; g < grouped.length; g++) ...[
                  for (final item in grouped[g]) _buildItemRow(context, item),
                  // thin divider between product groups, not at the very end
                  if (g < grouped.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, color: Colors.grey.shade100),
                    ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),

                _buildSummaryRow(
                  context.tr('Subtotal', 'المجموع الفرعي'),
                  '${subtotal.toStringAsFixed(2)} ${context.loc.egp}',
                  isBold: false,
                ),

                // Promo discount row
                if (hasPromo) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              size: 15, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            context.tr(
                              'Discount ($appliedPromo)',
                              'خصم ($appliedPromo)',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '- ${promoDiscount.toStringAsFixed(2)} ${context.loc.egp}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),

                _buildSummaryRow(
                  context.loc.total,
                  '${finalTotal.toStringAsFixed(2)} ${context.loc.egp}',
                  isBold: true,
                  color: hasPromo ? Colors.green : AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Groups the flat [items] list by productId so variants of the same
  /// product cluster together without breaking the overall order.
  List<List<dynamic>> _groupByProduct(List<dynamic> items) {
    final Map<String, List<dynamic>> map = {};
    final List<String> order = [];
    for (final item in items) {
      final key = (item.productId as String?) ?? '';
      if (!map.containsKey(key)) {
        map[key] = [];
        order.add(key);
      }
      map[key]!.add(item);
    }
    return order.map((k) => map[k]!).toList();
  }

  Widget _buildItemRow(BuildContext context, dynamic item) {
    final bool isAr = context.loc.isAr;
    final String nameEn = (item.productName as String?) ?? '';
    final String? nameAr = item.productNameAr as String?;
    final int qty = (item.quantity as int?) ?? 1;
    final double price = (item.price as double?) ?? 0.0;
    final String? rawSize = item.selectedSize as String?;
    final String? selectedOption = item.selectedOption as String?;

    // ── Options: Map<String, String> → "group: choice, ..."
    String optionsStr = '';
    try {
      final rawOptions = item.selectedOptions;
      if (rawOptions is Map && rawOptions.isNotEmpty) {
        optionsStr =
            rawOptions.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
      }
    } catch (_) {}

    // ── Add-ons: List<Map> → "addon1 (+price), addon2 (+price)"
    String addonsStr = '';
    try {
      final rawAddons = item.selectedAddons;
      if (rawAddons is List && rawAddons.isNotEmpty) {
        addonsStr = rawAddons
            .map((a) {
              final m = a as Map;
              final name =
                  (isAr ? m['name']?.toString() : m['name_en']?.toString()) ??
                      m['name']?.toString() ??
                      '';
              final price = (m['price'] as num?)?.toDouble();
              if (name.isEmpty) return '';
              if (price == null || price <= 0) return name;
              return '$name (+${price.toStringAsFixed(2)} ${context.loc.egp})';
            })
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
    } catch (_) {}

    // Locale-correct product name
    final String displayName =
        TranslationHelper.translateProductName(context, nameEn, nameAr);

    // Size / single option label
    final String sizeTag = optionsStr.isNotEmpty
        ? ''
        : (selectedOption != null && selectedOption.isNotEmpty
            ? ' ($selectedOption)'
            : (rawSize != null && rawSize.isNotEmpty
                ? ' (${_sizeLabel(context, rawSize)})'
                : ''));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + qty + total price row ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${qty}x $displayName$sizeTag',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(price * qty).toStringAsFixed(2)} ${context.loc.egp}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          // ── Options subtitle ────────────────────────────────────────
          if (optionsStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                optionsStr,
                style: TextStyle(fontSize: 12, color: Colors.indigo.shade400),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // ── Add-ons subtitle ──────────────────────────────────────
          if (addonsStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                '+ $addonsStr',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isBold = false,
    Color? color,
    double size = 15,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w800,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
