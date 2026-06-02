import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/presentation/cubit/cart_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';

// ── Data models ──────────────────────────────────────────────────────────────

class _OptionChoice {
  final String id;
  final String nameAr;
  final String nameEn;
  final double extraPrice;
  final int sortOrder;

  const _OptionChoice({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.extraPrice,
    required this.sortOrder,
  });

  factory _OptionChoice.fromJson(Map<String, dynamic> json) => _OptionChoice(
        id: json['id'].toString(),
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        extraPrice: (json['extra_price'] as num? ?? 0).toDouble(),
        sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
      );

  String displayName(bool isAr) {
    if (isAr && nameAr.trim().isNotEmpty) return nameAr.trim();
    if (nameEn.trim().isNotEmpty) return nameEn.trim();
    return nameAr.trim();
  }
}

class _OptionGroup {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool multiSelect;
  final bool required;
  final int sortOrder;
  final List<_OptionChoice> choices;

  const _OptionGroup({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.multiSelect,
    required this.required,
    required this.sortOrder,
    required this.choices,
  });

  factory _OptionGroup.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['category_option_choices'] as List<dynamic>? ?? [];
    final choices = rawChoices
        .map((c) => _OptionChoice.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return _OptionGroup(
      id: json['id'].toString(),
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      multiSelect: json['multi_select'] as bool? ?? false,
      required: json['required'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
      choices: choices,
    );
  }

  String displayName(bool isAr) {
    if (isAr && nameAr.trim().isNotEmpty) return nameAr.trim();
    if (nameEn.trim().isNotEmpty) return nameEn.trim();
    return nameAr.trim();
  }
}

class _Addon {
  final String id;
  final String nameAr;
  final String nameEn;
  final double price;
  final int sortOrder;

  const _Addon({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    required this.sortOrder,
  });

  factory _Addon.fromJson(Map<String, dynamic> json) => _Addon(
        id: json['id'].toString(),
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        price: (json['price'] as num? ?? 0).toDouble(),
        sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
      );

  String displayName(bool isAr) {
    if (isAr && nameAr.trim().isNotEmpty) return nameAr.trim();
    if (nameEn.trim().isNotEmpty) return nameEn.trim();
    return nameAr.trim();
  }
}

// ── Page ─────────────────────────────────────────────────────────────────────

class ProductDetailsPage extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // ── Quantity ──────────────────────────────────────────────────────────────
  int _quantity = 1;

  // ── Option groups + choices ───────────────────────────────────────────────
  bool _isLoadingCustomization = false;
  List<_OptionGroup> _optionGroups = const [];

  /// Single-select state: groupId → chosen choiceId
  final Map<String, String> _radioSelections = {};

  /// Multi-select state: groupId → Set of chosen choiceIds
  final Map<String, Set<String>> _checkboxSelections = {};

  /// Price per choice from products.option_prices jsonb: choiceId → price
  Map<String, double> _optionPrices = const {};

  // ── Add-ons ───────────────────────────────────────────────────────────────
  List<_Addon> _addons = const [];
  final Set<String> _selectedAddonIds = {};

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCustomization();
  }

  // ── Supabase data fetching ────────────────────────────────────────────────

  Future<void> _loadCustomization() async {
    setState(() => _isLoadingCustomization = true);
    try {
      final supabase = Supabase.instance.client;
      final catId = widget.product.categoryId;

      // Fetch option groups with nested choices
      final groupsRaw = await supabase
          .from('category_option_groups')
          .select('*, category_option_choices(*)')
          .eq('category_id', catId)
          .order('sort_order');

      final groups = (groupsRaw as List<dynamic>)
          .map((r) => _OptionGroup.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Fetch option_prices from this product row: Map<choiceId, price>
      Map<String, double> optionPrices = const {};
      try {
        final productRow = await supabase
            .from('products')
            .select('option_prices')
            .eq('id', widget.product.id)
            .maybeSingle();
        var raw = productRow?['option_prices'];
        if (raw is String) {
          raw = jsonDecode(raw);
        }
        if (raw is Map) {
          optionPrices = raw.map((k, v) =>
              MapEntry(k.toString(), (v as num? ?? 0).toDouble()));
        }
      } catch (_) {}

      // Fetch active add-ons
      final addonsRaw = await supabase
          .from('category_addons')
          .select()
          .eq('category_id', catId)
          .eq('active', true)
          .order('sort_order');

      final addons = (addonsRaw as List<dynamic>)
          .map((r) => _Addon.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (!mounted) return;
      setState(() {
        _optionGroups = groups;
        _optionPrices = optionPrices;
        _addons = addons;

        // Auto-select the first choice for required single-select groups
        for (final group in groups) {
          if (!group.multiSelect && group.required && group.choices.isNotEmpty) {
            _radioSelections[group.id] = group.choices.first.id;
          }
        }
        _isLoadingCustomization = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _optionGroups = const [];
          _addons = const [];
          _isLoadingCustomization = false;
        });
      }
    }
  }



  // ── Pricing calculation ───────────────────────────────────────────────────

  /// Price for the currently selected single-select choices.
  /// For multi-select groups, uses the first selected choice's price.
  /// Falls back to product.basePrice when no option price is set.
  double get _basePrice {
    // Collect prices from all single-select selections
    double choicePrice = 0;
    bool hasPriceSelection = false;
    for (final group in _optionGroups) {
      if (!group.multiSelect) {
        final choiceId = _radioSelections[group.id];
        if (choiceId != null) {
          final p = _optionPrices[choiceId] ?? 0;
          if (p > 0) {
            choicePrice += p;
            hasPriceSelection = true;
          }
        }
      }
    }
    if (hasPriceSelection) return choicePrice;
    return widget.product.basePrice;
  }

  /// Sum of selected addon prices
  double get _addonsExtraPrice {
    return _addons
        .where((a) => _selectedAddonIds.contains(a.id))
        .fold(0.0, (sum, a) => sum + a.price);
  }

  // Per spec: option group choices are configuration only — price = base + addons only.
  double get _unitPrice => _basePrice + _addonsExtraPrice;
  double get _totalPrice => _unitPrice * _quantity;

  // ── Validation ────────────────────────────────────────────────────────────

  /// Returns true if all required option groups have a selection
  bool get _canAddToCart {
    for (final group in _optionGroups) {
      if (!group.required) continue;
      if (!group.multiSelect) {
        if (!_radioSelections.containsKey(group.id)) return false;
      } else {
        if ((_checkboxSelections[group.id]?.isEmpty ?? true)) return false;
      }
    }
    return true;
  }

  // ── Build selectedOptions map for cart ────────────────────────────────────

  /// Builds a String-to-String map of groupName → choiceName for cart storage.
  Map<String, String> _buildSelectedOptionsMap(bool isAr) {
    final map = <String, String>{};
    for (final group in _optionGroups) {
      if (!group.multiSelect) {
        final choiceId = _radioSelections[group.id];
        if (choiceId != null) {
          final choice = group.choices.where((c) => c.id == choiceId).firstOrNull;
          if (choice != null) {
            map[group.displayName(isAr)] = choice.displayName(isAr);
          }
        }
      } else {
        final selected = _checkboxSelections[group.id] ?? {};
        final names = group.choices
            .where((c) => selected.contains(c.id))
            .map((c) => c.displayName(isAr))
            .join(', ');
        if (names.isNotEmpty) {
          map[group.displayName(isAr)] = names;
        }
      }
    }
    return map;
  }

  /// Builds List<Map> for selected addons
  List<Map<String, dynamic>> _buildSelectedAddonsList() {
    return _addons
        .where((a) => _selectedAddonIds.contains(a.id))
        .map((a) => {
              'id': a.id,
              'name': a.nameAr.isNotEmpty ? a.nameAr : a.nameEn,
              'name_en': a.nameEn,
              'price': a.price,
            })
        .toList();
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _getFallbackDescription(BuildContext context) {
    if (widget.product.description.isNotEmpty) {
      return widget.product.description;
    }
    final name = widget.product.name;
    final nameAr = widget.product.nameAr ?? name;
    return context.tr(
      'Enjoy the perfect and refreshing taste of $name. Crafted with the finest ingredients to bring you a unique flavor that brightens your day.',
      'استمتع بالمذاق الرائع والمنعش لـ $nameAr. محضر بأجود المكونات ليقدم لك نكهة فريدة ومميزة تضيء يومك.',
    );
  }

  void _addToCartAndPop(BuildContext ctx, {required bool navigate}) {
    if (!_canAddToCart) {
      // Show validation error for missing required group
      for (final group in _optionGroups) {
        if (!group.required) continue;
        final isAr = ctx.loc.isAr;
        bool missing = false;
        if (!group.multiSelect && !_radioSelections.containsKey(group.id)) {
          missing = true;
        } else if (group.multiSelect &&
            (_checkboxSelections[group.id]?.isEmpty ?? true)) {
          missing = true;
        }
        if (missing) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
              isAr
                  ? 'يرجى اختيار ${group.displayName(true)}'
                  : 'Please select ${group.displayName(false)}',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
      }
      return;
    }

    final isAr = ctx.loc.isAr;
    ctx.read<CartCubit>().addToCart(
          productId: widget.product.id,
          productName: widget.product.name,
          basePrice: widget.product.basePrice,
          price: _unitPrice,
          image: widget.product.imageUrl,
          quantity: _quantity,
          selectedSize: null,
          selectedOptions: _buildSelectedOptionsMap(isAr),
          selectedAddons: _buildSelectedAddonsList(),
        );

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(ctx.loc.addedToCart),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ));

    if (navigate) {
      Navigator.pushNamed(ctx, '/cart');
    } else {
      Navigator.pop(ctx);
    }
  }

  // ── Option groups rendered as pill/chip buttons ────────────────────────────

  Widget _buildOptionGroupsSection(bool isAr) {
    if (_isLoadingCustomization) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_optionGroups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in _optionGroups) ..._buildGroupPills(group, isAr),
      ],
    );
  }

  List<Widget> _buildGroupPills(_OptionGroup group, bool isAr) {
    return [
      // ── Group title row with required badge ────────────────────────────────
      Row(
        children: [
          Text(
            group.displayName(isAr),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          if (group.required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAr ? 'مطلوب' : 'Required',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),

      // ── Pill buttons row ────────────────────────────────────────────────
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: group.choices.map((choice) {
          final bool isSelected = group.multiSelect
              ? (_checkboxSelections[group.id] ?? {}).contains(choice.id)
              : _radioSelections[group.id] == choice.id;

          final String label = choice.displayName(isAr);

          return GestureDetector(
            onTap: () => setState(() {
              if (!group.multiSelect) {
                _radioSelections[group.id] = choice.id;
              } else {
                final s = Set<String>.from(
                    _checkboxSelections[group.id] ?? {});
                if (s.contains(choice.id)) {
                  s.remove(choice.id);
                } else {
                  s.add(choice.id);
                }
                _checkboxSelections[group.id] = s;
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildAddonsSection(bool isAr) {
    if (_isLoadingCustomization || _addons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'إضافات' : 'Add-ons',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAr ? 'اختياري' : 'Optional',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ..._addons.map((addon) {
                final isChecked = _selectedAddonIds.contains(addon.id);
                return InkWell(
                  onTap: () => setState(() {
                    if (isChecked) {
                      _selectedAddonIds.remove(addon.id);
                    } else {
                      _selectedAddonIds.add(addon.id);
                    }
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? Colors.orange.withValues(alpha: 0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) => setState(() {
                            if (isChecked) {
                              _selectedAddonIds.remove(addon.id);
                            } else {
                              _selectedAddonIds.add(addon.id);
                            }
                          }),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            addon.displayName(isAr),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isChecked
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '+${addon.price.toStringAsFixed(2)} ${isAr ? 'ج' : 'EGP'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    final isAr = context.loc.isAr;
    final displayName = context.tr(
      widget.product.name,
      widget.product.nameAr ?? widget.product.name,
    );
    final description = _getFallbackDescription(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              int itemCount = 0;
              if (state is CartLoaded) {
                itemCount =
                    state.items.fold(0, (sum, item) => sum + item.quantity);
              }
              return IconButton(
                icon: Badge(
                  isLabelVisible: itemCount > 0,
                  label: Text(itemCount.toString()),
                  backgroundColor: Colors.red,
                  offset: const Offset(4, -4),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.textPrimary,
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Image ──────────────────────────────────────────────────
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Transform.scale(
                  scale: 1.15,
                  alignment: const Alignment(0, -0.3),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Price Header ────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(2)} ${context.loc.egp}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Description ─────────────────────────────────────────
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Dynamic Option Groups (pill/chip style) ───────────────────
                  _buildOptionGroupsSection(isAr),

                  // ── Add-ons ─────────────────────────────────────────────
                  _buildAddonsSection(isAr),

                  const SizedBox(height: 8),

                  // ── Quantity & Add To Cart ──────────────────────────────
                  Row(
                    children: [
                      // Quantity Control
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  color: AppColors.textPrimary),
                              onPressed: () => setState(() {
                                if (_quantity > 1) _quantity--;
                              }),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: AppColors.textPrimary),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add To Cart Button
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 20),
                            side: const BorderSide(
                                color: AppColors.primary, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _addToCartAndPop(context, navigate: false),
                          child: const Icon(Icons.add_shopping_cart, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Buy Now Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () =>
                              _addToCartAndPop(context, navigate: true),
                          child: Text(
                            context.tr('Buy Now', 'اشتري الآن'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
