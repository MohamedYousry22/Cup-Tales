import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyFirstInstall = 'first_install';
  static const String _keyAppLanguage = 'app_language';
  static const String _keySelectedBranchId = 'selected_branch_id';
  static const String _keySavedAddressesPrefix = 'saved_addresses_';
  static const String _keySelectedAddressPrefix = 'selected_address_';

  bool get isOnboardingSeen => _prefs.getBool(_keyOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) async {
    await _prefs.setBool(_keyOnboardingSeen, value);
  }

  String? get selectedBranchId => _prefs.getString(_keySelectedBranchId);

  Future<void> setSelectedBranchId(String value) async {
    await _prefs.setString(_keySelectedBranchId, value);
  }

  List<String> getSavedAddresses(String userId) {
    return _prefs.getStringList('$_keySavedAddressesPrefix$userId') ??
        const <String>[];
  }

  String? getSelectedAddress(String userId) {
    return _prefs.getString('$_keySelectedAddressPrefix$userId');
  }

  Future<List<String>> saveAddress(String userId, String address) async {
    final normalized = address.trim();
    final addresses = getSavedAddresses(userId).toList();
    if (normalized.isNotEmpty &&
        !addresses
            .any((item) => item.toLowerCase() == normalized.toLowerCase())) {
      addresses.add(normalized);
      await _prefs.setStringList('$_keySavedAddressesPrefix$userId', addresses);
    }
    if (normalized.isNotEmpty) {
      await setSelectedAddress(userId, normalized);
    }
    return addresses;
  }

  Future<void> setSelectedAddress(String userId, String address) async {
    await _prefs.setString('$_keySelectedAddressPrefix$userId', address);
  }

  Future<void> clearSelectedAddress(String userId) async {
    await _prefs.remove('$_keySelectedAddressPrefix$userId');
  }

  Future<void> replaceSavedAddresses(
    String userId,
    List<String> addresses,
  ) async {
    await _prefs.setStringList('$_keySavedAddressesPrefix$userId', addresses);
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

  Future<void> clearUserData(String userId) async {
    await Future.wait([
      _prefs.remove('$_keySavedAddressesPrefix$userId'),
      _prefs.remove('$_keySelectedAddressPrefix$userId'),
      _prefs.remove(_keySelectedBranchId),
    ]);
  }
}
