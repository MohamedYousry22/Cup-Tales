import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../../products/presentation/pages/product_search_delegate.dart';
import '../../../categories/presentation/widgets/categories_section.dart';
import '../../../products/presentation/widgets/products_section.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/antigravity_loader.dart';
import '../widgets/animated_banners.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  late final HomeCubit _homeCubit = HomeCubit()..loadHomeData();
  late final CategoriesCubit _categoriesCubit = di.sl<CategoriesCubit>()
    ..loadCategories();
  late final ProductsCubit _productsCubit = di.sl<ProductsCubit>();

  Future<void> scrollToTop() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> refreshHome() async {
    if (!mounted) return;
    _homeCubit.loadHomeData();
    await _categoriesCubit.loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _homeCubit.close();
    _categoriesCubit.close();
    _productsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>.value(value: _homeCubit),
        BlocProvider<CategoriesCubit>.value(value: _categoriesCubit),
        BlocProvider<ProductsCubit>.value(value: _productsCubit),
      ],
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Fix ghost button issue
          titleSpacing: 16,
          title: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Cup Tales",
                  style: TextStyle(
                    color: Color(0xFF2D3194), // AppColors.primary
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Draw Your Smile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF2D3194),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                          color: Color(0xFF2D3194),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(child: AntigravityLoaderCore(size: 80.0));
            } else if (state is HomeLoaded) {
              return RefreshIndicator(
                color: const Color(0xFF2D3194),
                onRefresh: refreshHome,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Logo
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 20.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.loc.offers,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .black, // Assuming AppColors.primary is black or similar
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.search, color: Colors.grey[700]),
                              onPressed: () {
                                showSearch(
                                  context: context,
                                  delegate: ProductSearchDelegate(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── Promotional Banners ──
                      AnimatedBanners(banners: state.banners),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.loc.menu,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF161A5C),
                          ),
                        ),
                      ),
                      const CategoriesSection(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.loc.featuredProducts,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF161A5C),
                          ),
                        ),
                      ),
                      // Products Grid (Supabase Integrated)
                      const ProductsSection(),
                      const SizedBox(
                          height:
                              120), // Extra padding to scroll past the floating nav bar
                    ],
                  ),
                ),
              );
            } else if (state is HomeError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
