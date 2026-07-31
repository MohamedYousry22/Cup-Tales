import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/localization/language_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routing/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class ProfilePage extends StatefulWidget {
  final int resetNonce;

  const ProfilePage({super.key, this.resetNonce = 0});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>?> _profileFuture;
  final ScrollController _scrollController = ScrollController();
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    _profileFuture = Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user?.id ?? '')
        .maybeSingle();
  }

  void _refreshProfile() {
    setState(() {
      _loadProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete account?', 'حذف الحساب؟')),
        content: Text(
          context.tr(
            'Your account, profile, saved addresses, cart and order history will be permanently deleted. This action cannot be undone.',
            'سيتم حذف حسابك وبياناتك الشخصية وعناوينك المحفوظة والسلة وسجل الطلبات نهائيًا، ولا يمكن التراجع عن ذلك.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel', 'إلغاء')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Delete permanently', 'حذف نهائي')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    final authCubit = context.read<AuthCubit>();
    await authCubit.deleteAccount();
    if (!mounted) return;

    if (authCubit.state is AuthError) {
      final error = authCubit.state as AuthError;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.register,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          context.loc.cupTalesProfile,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final userName = profile?['name'] as String? ??
              user?.userMetadata?['full_name'] as String? ??
              'Cup Tales User';
          final userEmail = profile?['email'] as String? ??
              user?.email ??
              'No email available';
          final userPhone = profile?['phone'] as String?;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                // 1. User Info Section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (userPhone != null && userPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userPhone,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                        context, AppRouter.personalInfo)
                                    .then((_) => _refreshProfile());
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.edit,
                                    size: 16, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.personalInfo)
                                .then((_) => _refreshProfile());
                          },
                          icon: const Icon(Icons.add_call, size: 18),
                          label: Text(context.tr(
                              'Add phone number', 'إضافة رقم الهاتف')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 2. Account Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: context.loc.accountSettings),
                      Container(
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
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.person,
                              title: context.loc.personalInfo,
                              subtitle: context.loc.personalInfoSubtitle,
                              onTap: () {
                                Navigator.pushNamed(
                                        context, AppRouter.personalInfo)
                                    .then((_) => _refreshProfile());
                              },
                            ),
                            const _Divider(),
                            const _LanguageTile(),
                            const _Divider(),
                            _SettingsTile(
                              icon: Icons.notifications,
                              title: context.loc.notifications,
                              subtitle: context.loc.notificationsSubtitle,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.notifications,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Support / Information
                      _SectionHeader(title: context.loc.support),
                      Container(
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
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.map,
                              title: context.tr('Our Branches', 'فروعنا'),
                              subtitle: context.tr('Find a branch near you',
                                  'ابحث عن فرع قريب منك'),
                              showChevron: true,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, AppRouter.branches);
                              },
                            ),
                            const _Divider(),
                            _SettingsTile(
                              icon: Icons.shield,
                              title: context.loc.privacyPolicy,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, AppRouter.privacyPolicy);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 4. Logout
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: Colors.red.shade100, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade50.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _SettingsTile(
                          icon: Icons.logout,
                          title: context.loc.logout,
                          titleColor: Colors.red.shade600,
                          iconBackgroundColor: Colors.red.shade50,
                          iconColor: Colors.red.shade600,
                          showChevron: false,
                          onTap: () async {
                            await context.read<AuthCubit>().logout();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRouter.login,
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: Colors.red.shade100, width: 2),
                        ),
                        child: _SettingsTile(
                          icon: Icons.delete_forever_outlined,
                          title: _isDeletingAccount
                              ? context.tr(
                                  'Deleting account...',
                                  'جارٍ حذف الحساب...',
                                )
                              : context.tr(
                                  'Delete account',
                                  'حذف الحساب',
                                ),
                          subtitle: context.tr(
                            'Permanently delete your account and associated data',
                            'حذف الحساب والبيانات المرتبطة به نهائيًا',
                          ),
                          titleColor: Colors.red.shade700,
                          iconBackgroundColor: Colors.red.shade50,
                          iconColor: Colors.red.shade700,
                          showChevron: false,
                          onTap: _isDeletingAccount
                              ? () {}
                              : _confirmDeleteAccount,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, right: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade50,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = titleColor ?? AppColors.primary;
    final effectiveIconBgColor = iconBackgroundColor ?? AppColors.primary;
    final effectiveIconColor = iconColor ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: effectiveTitleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.translate, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.appLanguage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                BlocBuilder<LanguageCubit, LanguageState>(
                  builder: (context, state) {
                    final isEn = state.language == AppLanguage.en;
                    return Text(
                      isEn
                          ? context.loc.englishSelected
                          : context.loc.arabicSelected,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, state) {
              final isEn = state.language == AppLanguage.en;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => context
                          .read<LanguageCubit>()
                          .setLanguage(AppLanguage.en),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isEn ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isEn ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context
                          .read<LanguageCubit>()
                          .setLanguage(AppLanguage.ar),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isEn ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'AR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !isEn ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
