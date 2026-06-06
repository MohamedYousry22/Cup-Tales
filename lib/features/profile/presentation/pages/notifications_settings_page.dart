import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;

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
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRouter.home),
        ),
        title: Text(
          context.loc.notifications,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.loc.alertPreferences.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
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
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      title: Text(
                        context.loc.pushNotifications,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      subtitle: Text(
                        context.loc.stayUpdatedOrders,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      value: _pushEnabled,
                      onChanged: (val) => setState(() => _pushEnabled = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      title: Text(
                        context.loc.emailOffers,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      subtitle: Text(
                        context.loc.getDiscountsInbox,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      value: _emailEnabled,
                      onChanged: (val) => setState(() => _emailEnabled = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
