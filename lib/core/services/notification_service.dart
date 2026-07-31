import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  bool get hasSystemPermission => OneSignal.Notifications.permission;

  bool get isPushEnabled =>
      hasSystemPermission && OneSignal.User.pushSubscription.optedIn == true;

  Future<void> init() async {
    // OneSignal is initialized in main before this service is resolved.
  }

  Future<bool> enablePush() async {
    var granted = OneSignal.Notifications.permission;
    if (!granted) {
      granted = await OneSignal.Notifications.requestPermission(true);
    }
    if (!granted) return false;

    await OneSignal.User.pushSubscription.optIn();
    return OneSignal.User.pushSubscription.optedIn == true;
  }

  Future<void> disablePush() async {
    await OneSignal.User.pushSubscription.optOut();
  }

  Future<void> identifyUser(String userId) async {
    if (userId.trim().isEmpty) return;
    await OneSignal.login(userId);
  }

  Future<void> clearUserIdentity() async {
    await OneSignal.logout();
  }
}
