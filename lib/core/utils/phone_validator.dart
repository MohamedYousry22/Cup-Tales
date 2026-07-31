class EgyptianPhoneValidator {
  EgyptianPhoneValidator._();

  static final RegExp _pattern = RegExp(r'^01[0125][0-9]{8}$');

  static bool isValid(String phone) => _pattern.hasMatch(phone.trim());
}
