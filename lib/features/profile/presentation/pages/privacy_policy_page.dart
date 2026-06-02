import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                        'Data Collection & Usage', 'جمع البيانات واستخدامها'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      'Welcome to Cup Tales! We take your privacy seriously. This document outlines the types of personal information we receive and collect when you use our application, as well as some of the steps we take to safeguard that information.',
                      'مرحباً بك في كاب تيلز! الخصوصية مهمة جداً بالنسبة لنا. توضح هذه الوثيقة أنواع المعلومات الشخصية التي نجمعها أثناء استخدامك لتطبيقنا، بالإضافة إلى الخطوات التي نتخذها لحماية تلك المعلومات.',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('Information Security', 'أمن المعلومات'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      'We implement security measures to maintain the safety of your personal information when you enter, submit, or access your personal information online. Our app relies on Supabase Auth ensuring enterprise-grade data protection.',
                      'نحن نتخذ تدابير أمنية مشددة للحفاظ على سلامة معلوماتك الشخصية. التطبيق يعتمد على بروتوكولات حماية متطورة و Supabase Auth لضمان تشفير بياناتك بالكامل.',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      context.tr(
                          'Last Updated: Sep 2024', 'آخر تحديث: سبتمبر ٢٠٢٤'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
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
