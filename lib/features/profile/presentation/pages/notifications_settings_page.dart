import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage>
    with WidgetsBindingObserver {
  NotificationService get _notifications => sl<NotificationService>();

  bool _pushEnabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _pushEnabled = _notifications.isPushEnabled);
  }

  Future<void> _setPushEnabled(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (enabled) {
        final didEnable = await _notifications.enablePush();
        if (!didEnable && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  'Enable notifications from your device settings.',
                  'فعّل الإشعارات من إعدادات الجهاز.',
                ),
              ),
              action: SnackBarAction(
                label: context.tr('Settings', 'الإعدادات'),
                onPressed: () => AppSettings.openAppSettings(
                  type: AppSettingsType.notification,
                ),
              ),
            ),
          );
        }
      } else {
        await _notifications.disablePush();
      }
    } finally {
      if (mounted) {
        setState(() {
          _pushEnabled = _notifications.isPushEnabled;
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
          context.loc.notifications,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.loc.alertPreferences.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: SwitchListTile(
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                title: Text(
                  context.loc.pushNotifications,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                subtitle: Text(
                  context.loc.stayUpdatedOrders,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _pushEnabled,
                onChanged: _busy ? null : _setPushEnabled,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                'You can change the system permission at any time from your device settings.',
                'يمكنك تغيير إذن النظام في أي وقت من إعدادات الجهاز.',
              ),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
