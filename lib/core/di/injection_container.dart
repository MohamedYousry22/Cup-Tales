import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../local_storage/hive_service.dart';
import '../local_storage/prefs_service.dart';
import '../services/notification_service.dart';
import '../localization/language_cubit.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/branch_service.dart';
import '../services/promo_code_service.dart';
import '../../features/auth/data/profile_service.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/categories/data/datasources/categories_remote_ds.dart';
import '../../features/categories/data/repositories/categories_repo_impl.dart';
import '../../features/categories/domain/repositories/categories_repo.dart';
import '../../features/categories/domain/usecases/get_categories.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/products/data/datasources/products_remote_ds.dart';
import '../../features/products/data/repositories/products_repo_impl.dart';
import '../../features/products/domain/repositories/products_repo.dart';
import '../../features/products/domain/usecases/get_products_by_category.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';
import '../../features/orders/presentation/cubit/orders_cubit.dart';
import '../../features/checkout/presentation/cubit/checkout_cubit.dart';

final sl = GetIt.instance;

/// Completer that resolves once the async init (SharedPreferences + Supabase) is done.
/// SplashCubit and AuthCubit await this before reading any pref/auth values.
final _readyCompleter = Completer<void>();
Future<void> get appReady => _readyCompleter.future;

/// Step 1 — register all factories/singletons SYNCHRONOUSLY.
/// No IO, no awaits — completes in <1ms.
void registerSync() {
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => HiveService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => AuthService());
  sl.registerLazySingleton(() => OrderService());
  sl.registerLazySingleton(() => ProfileService());
  sl.registerLazySingleton(() => BranchService());
  sl.registerLazySingleton(() => PromoCodeService());

  // Features
  sl.registerFactory(() => LanguageCubit());
  // A single auth cubit must be shared by the splash screen and AuthGate.
  // Multiple instances subscribe to Supabase twice and can emit conflicting
  // authentication states.
  sl.registerLazySingleton(
    () => AuthCubit(authService: sl(), profileService: sl()),
  );

  // Checkout
  sl.registerFactoryParam<CheckoutCubit, CartCubit, void>(
    (cartCubit, _) => CheckoutCubit(
      cartCubit,
      sl<BranchService>(),
      sl<PromoCodeService>(),
      sl<PrefsService>(),
    ),
  );

  // Categories
  sl.registerLazySingleton<CategoriesRemoteDS>(() => CategoriesRemoteDSImpl());
  sl.registerLazySingleton<CategoriesRepo>(() => CategoriesRepoImpl(sl()));
  sl.registerLazySingleton(() => GetCategoriesUsecase(sl()));
  sl.registerFactory(() => CategoriesCubit(getCategoriesUsecase: sl()));

  // Products
  sl.registerLazySingleton<ProductsRemoteDS>(() => ProductsRemoteDSImpl());
  sl.registerLazySingleton<ProductsRepo>(() => ProductsRepoImpl(sl()));
  sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  sl.registerFactory(() => ProductsCubit(sl()));

  // Cart
  sl.registerFactory(() => CartCubit());

  // Orders
  sl.registerFactory(() => OrdersCubit());
}

/// Step 2 — load SharedPreferences and signal readiness.
/// Called AFTER runApp() — runs in parallel with the splash animation.
Future<void> initAsync() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => PrefsService(sharedPreferences));

  // Initialize Hive and open all boxes before signaling readiness
  await sl<HiveService>().init();

  _readyCompleter.complete();
}

/// Legacy entry point kept for compatibility if anything still calls di.init().
Future<void> init() async {
  registerSync();
  await initAsync();
}
