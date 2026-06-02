import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_language.dart';
import 'language_cubit.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  bool get isAr => locale.languageCode == 'ar';

  // Helper method for dynamic keys
  String translate(String en, String ar) => isAr ? ar : en;

  // ─── Common ───────────────────────────────────────────
  String get retry => isAr ? 'إعادة المحاولة' : 'Retry';
  String get confirm => isAr ? 'تأكيد' : 'Confirm';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get close => isAr ? 'إغلاق' : 'Close';

  // ─── Navigation ───────────────────────────────────────
  String get navHome => isAr ? 'الرئيسية' : 'Home';
  String get navOrders => isAr ? 'الطلبات' : 'Orders';
  String get navProfile => isAr ? 'حسابي' : 'Profile';

  // ─── Home / Body ─────────────────────────────────────
  String get offers => isAr ? 'الأبرز' : 'Highlights';

  // ─── Auth ─────────────────────────────────────────────
  String get login => isAr ? 'تسجيل الدخول' : 'Login';
  String get signUp => isAr ? 'إنشاء حساب' : 'Sign Up';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email Address';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get forgotPassword => isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?';

  // ─── Home ─────────────────────────────────────────────
  String get menu => isAr ? 'القائمة' : 'Menu';
  String get featuredProducts => isAr ? 'منتجات مميزة' : 'Featured Products';
  String get searchPlaceholder =>
      isAr ? 'ابحث عن مشروبك...' : 'Search for a drink...';
  String get noCategories =>
      isAr ? 'لا توجد أصناف حالياً.' : 'No categories found.';
  String get noProducts => isAr
      ? 'لا توجد منتجات ضمن هذا التصنيف.'
      : 'No products found for this category.';

  // ─── Product Details ──────────────────────────────────
  String get size => isAr ? 'الحجم' : 'Size';
  String get small => isAr ? 'صغير' : 'Small';
  String get medium => isAr ? 'وسط' : 'Medium';
  String get large => isAr ? 'كبير' : 'Large';
  String get addToCart => isAr ? 'إضافة للسلة' : 'Add to Cart';
  String get addedToCart =>
      isAr ? 'تمت الإضافة للسلة بنجاح!' : 'Added to cart successfully!';

  // ─── Cart & Checkout ──────────────────────────────────
  String get cart => isAr ? 'السلة' : 'Cart';
  String get checkout => isAr ? 'إتمام الطلب' : 'Checkout';
  String get emptyCart => isAr ? 'سلتك فارغة' : 'Your cart is empty';
  String get total => isAr ? 'الإجمالي' : 'Total';
  String get placeOrder => isAr ? 'تأكيد الطلب' : 'Place Order';
  String get egp => isAr ? 'ج.م' : 'EGP';
  String get search => isAr ? 'بحث' : 'Search';
  String get searchProduct =>
      isAr ? 'ابحث عن منتج...' : 'Search for a product...';
  String get noProductsFound =>
      isAr ? 'لم يتم العثور على منتجات.' : 'No products found.';
  String get error => isAr ? 'خطأ' : 'Error';
  String get processingPayment =>
      isAr ? 'جاري معالجة الدفع...' : 'Processing Payment...';
  String get paymentMethod =>
      isAr ? 'اختر طريقة الدفع' : 'Select Payment Method';
  String get cashier =>
      isAr ? 'الكاشير (الدفع بالفرع)' : 'Cashier (Pay at Counter)';
  String get confirmPayment => isAr ? 'تأكيد الدفع' : 'Confirm Payment';
  String get paymentSuccess =>
      isAr ? 'يرجى التوجه الى الكاشير للدفع' : 'Please proceed to the cashier';
  String get paymentSuccessMsg => isAr
      ? 'تم استلام طلبك ويتم تجهيزه خصيصًا لك.'
      : 'Your order has been received and is being prepared especially for you.';
  String get backToHome => isAr ? 'العودة للرئيسية' : 'Back to Home';
  String get paymentInfoCash => isAr
      ? 'سيتم الدفع نقداً عند استلام الطلب من الفرع (استلام من الفرع).'
      : 'You will pay in cash upon receiving your order at the branch (Pick-up).';

  String get pickupFromBranch => isAr ? 'استلام من الفرع' : 'In-Store Pick-up';
  String get pickupFromBranchSubtitle =>
      isAr ? 'مجانًا - فرع مدينة نصر' : 'Free - Nasr City Branch';

  // ─── Profile ──────────────────────────────────────────
  String get cupTalesProfile => isAr ? 'الملف الشخصي' : 'Cup Tales Profile';
  String get accountSettings => isAr ? 'إعدادات الحساب' : 'Account Settings';
  String get support => isAr ? 'الدعم' : 'Support';

  String get personalInfo => isAr ? 'البيانات الشخصية' : 'Personal Info';
  String get personalInfoSubtitle =>
      isAr ? 'تحديث الاسم والبريد' : 'Update name and email';
  String get personalInfoDemo => isAr
      ? 'أدوات التعديل غير متاحة (تجريبي)'
      : 'Editing is not supported yet (Demo)';

  String get notifications => isAr ? 'الإشعارات' : 'Notifications';
  String get notificationsSubtitle =>
      isAr ? 'الصوت والاهتزاز والتنبيهات' : 'Sound, vibration & alerts';
  String get notificationsDemo => isAr
      ? 'تنبيهات غير مفعلة (تجريبي)'
      : 'Notifications not implemented yet (Demo)';

  String get alertPreferences =>
      isAr ? 'تفضيلات التنبيهات' : 'Alert Preferences';
  String get pushNotifications =>
      isAr ? 'إشعارات الهاتف' : 'Push Notifications';
  String get stayUpdatedOrders =>
      isAr ? 'ابق على اطلاع بحالة طلباتك' : 'Stay updated on your orders';
  String get emailOffers => isAr ? 'عروض البريد الإلكتروني' : 'Email Offers';
  String get getDiscountsInbox => isAr
      ? 'احصل على خصومات حصرية عبر بريدك'
      : 'Receive special discounts directly to your inbox';

  String get privacyPolicy => isAr ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get privacyPolicyDemo => isAr
      ? 'السياسة قيد المراجعة (تجريبي)'
      : 'Privacy Policy not ready yet (Demo)';

  String get logout => isAr ? 'تسجيل الخروج' : 'Logout';
  String get appLanguage => isAr ? 'لغة التطبيق' : 'App Language';
  String get arabicSelected => isAr ? 'العربية (محدّد)' : 'Arabic (selected)';
  String get englishSelected =>
      isAr ? 'الإنجليزية (محدّد)' : 'English (selected)';

  // Provide a bridge compatibility method so existing code relying on context.tr() doesn't break instantly
  // but acts as an alias to our new typed delegate. It listens to LanguageCubit state dynamically
  // purely to smooth the transition for widgets we haven't touched yet.
}

extension LocalizationHelper on BuildContext {
  /// Backward compatibility layer bridging the new AppLocalizations Delegate
  /// with the `context.tr()` convenience extension used previously.
  bool get isArabic => read<LanguageCubit>().state.language == AppLanguage.ar;
  String tr(String en, String ar) {
    if (isArabic && ar.trim().isNotEmpty) return ar.trim();
    return en.trim();
  }

  /// The global, typed AppLocalizations object. Calling `context.loc` automatically establishes a widget subscription!
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
