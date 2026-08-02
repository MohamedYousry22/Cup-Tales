import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static final Uri _privacyUrl = Uri.parse(
    'https://mohamedyousry22.github.io/Cup-Tales/privacy-policy.html',
  );
  static final Uri _supportEmail = Uri(
    scheme: 'mailto',
    path: 'm1662006@gmail.com',
    queryParameters: {'subject': 'Cup Tales Privacy Request'},
  );

  @override
  Widget build(BuildContext context) {
    final sections = <({String title, String body})>[
      (
        title: context.tr('Information we collect', 'البيانات التي نجمعها'),
        body: context.tr(
          'We collect the name, email address and phone number you provide, saved delivery addresses, order and cart details, and identifiers needed for authentication. Android users who enable push notifications also provide a notification identifier.',
          'نجمع الاسم والبريد الإلكتروني ورقم الهاتف الذي تقدمه، وعناوين التوصيل المحفوظة، وتفاصيل الطلبات والسلة، والمعرّفات اللازمة لتسجيل الدخول. ويوفّر مستخدمو Android معرّف إشعارات عند تفعيل الإشعارات.',
        ),
      ),
      (
        title: context.tr('How we use data', 'كيفية استخدام البيانات'),
        body: context.tr(
          'We use this information to create and manage your account, prepare and deliver orders, contact you about an order, remember your preferences, prevent abuse, and send Android order updates when notifications are enabled.',
          'نستخدم هذه البيانات لإنشاء الحساب وإدارته، وتجهيز الطلبات وتوصيلها، والتواصل معك بشأن الطلب، وحفظ تفضيلاتك، ومنع إساءة الاستخدام، وإرسال تحديثات الطلب على Android عند تفعيل الإشعارات.',
        ),
      ),
      (
        title: context.tr('Service providers', 'مقدمو الخدمات'),
        body: context.tr(
          'Cup Tales uses Supabase for authentication and database services. On Android, Firebase and Google provide Google Sign-In and OneSignal provides optional push notifications. iOS uses Cup Tales email/password authentication and does not initialize Google Sign-In or push notifications in this release.',
          'يستخدم Cup Tales خدمة Supabase لتسجيل الدخول وقاعدة البيانات. وعلى Android توفّر Firebase وGoogle تسجيل الدخول باستخدام Google، وتوفّر OneSignal الإشعارات الاختيارية. ويستخدم iOS تسجيل Cup Tales بالبريد وكلمة المرور فقط، من دون تشغيل تسجيل Google أو الإشعارات في هذا الإصدار.',
        ),
      ),
      (
        title: context.tr('Retention and deletion', 'الاحتفاظ والحذف'),
        body: context.tr(
          'Your data is kept while your account is active. You can permanently delete your account and associated profile, addresses, cart and order history from Profile > Delete account. You can also contact us using the link below.',
          'نحتفظ ببياناتك طوال فترة نشاط الحساب. يمكنك حذف الحساب والملف الشخصي والعناوين والسلة وسجل الطلبات نهائيًا من الملف الشخصي ← حذف الحساب، كما يمكنك التواصل معنا من الرابط أدناه.',
        ),
      ),
      (
        title: context.tr('Your choices', 'اختياراتك'),
        body: context.tr(
          'You can edit your profile and saved addresses, sign out, or delete your account. Android users can also disable push notifications in the app or device settings.',
          'يمكنك تعديل بياناتك وعناوينك المحفوظة، وتسجيل الخروج، أو حذف الحساب. ويمكن لمستخدمي Android أيضًا إيقاف الإشعارات من التطبيق أو إعدادات الجهاز.',
        ),
      ),
      (
        title: context.tr('Security', 'الأمان'),
        body: context.tr(
          'We use authenticated connections, database access controls and row-level security to protect account data. No internet service can guarantee absolute security, but we limit access to what is required to operate the service.',
          'نستخدم اتصالات موثقة وصلاحيات لقاعدة البيانات وسياسات أمان على مستوى الصفوف لحماية بيانات الحساب. لا توجد خدمة إنترنت تضمن الأمان المطلق، لكننا نقصر الوصول على ما يلزم لتشغيل الخدمة.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.loc.privacyPolicy,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in sections) ...[
                _PolicySection(title: section.title, body: section.body),
                const SizedBox(height: 24),
              ],
              Text(
                context.tr('Contact us', 'تواصل معنا'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => launchUrl(_supportEmail),
                icon: const Icon(Icons.email_outlined),
                label: const Text('m1662006@gmail.com'),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                  _privacyUrl,
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  context.tr(
                    'View the web privacy policy',
                    'عرض سياسة الخصوصية على الويب',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  context.tr(
                    'Last updated: August 2, 2026',
                    'آخر تحديث: 2 أغسطس 2026',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
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

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
