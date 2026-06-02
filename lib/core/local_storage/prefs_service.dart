import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyFirstInstall = 'first_install';
  static const String _keyAppLanguage = 'app_language';
  static const String _keySelectedBranchId = 'selected_branch_id';

  bool get isOnboardingSeen => _prefs.getBool(_keyOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) async {
    await _prefs.setBool(_keyOnboardingSeen, value);
  }

  String? get selectedBranchId => _prefs.getString(_keySelectedBranchId);

  Future<void> setSelectedBranchId(String value) async {
    await _prefs.setString(_keySelectedBranchId, value);
  }

  bool get isFirstInstall => _prefs.getBool(_keyFirstInstall) ?? true;

  Future<void> setFirstInstall(bool value) async {
    await _prefs.setBool(_keyFirstInstall, value);
  }

  String getAppLanguage() => _prefs.getString(_keyAppLanguage) ?? 'ar';

  Future<void> setAppLanguage(String lang) async {
    await _prefs.setString(_keyAppLanguage, lang);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
