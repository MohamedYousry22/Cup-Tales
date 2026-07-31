import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/phone_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/local_storage/prefs_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/antigravity_loader.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _addresses = [];

  bool _isInitialLoading = true;
  bool _isProfileSaving = false;
  bool _isAddressBusy = false;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;
  PrefsService get _prefs => di.sl<PrefsService>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await di.appReady;
    final user = _client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _client.from('profiles').select().eq('id', user.id).maybeSingle(),
        _client
            .from('user_addresses')
            .select('address')
            .eq('user_id', user.id)
            .order('created_at'),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      final addressRows = results[1] as List<dynamic>;
      final addresses = addressRows
          .map((row) => (row as Map<String, dynamic>)['address']?.toString())
          .whereType<String>()
          .where((address) => address.trim().isNotEmpty)
          .toList(growable: false);

      _nameController.text = profile?['name'] as String? ??
          user.userMetadata?['full_name'] as String? ??
          '';
      _phoneController.text = profile?['phone'] as String? ?? '';
      await _prefs.replaceSavedAddresses(user.id, addresses);

      if (!mounted) return;
      setState(() {
        _addresses
          ..clear()
          ..addAll(addresses);
        _isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
      _showMessage(
        context.tr(
          'Could not load your account details',
          'تعذر تحميل بيانات حسابك',
        ),
        isError: true,
      );
    }
  }

  Future<void> _updateProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final phone = _phoneController.text.trim();
    if (!EgyptianPhoneValidator.isValid(phone)) {
      _showMessage(
        context.tr(
          'Enter a valid 11-digit Egyptian mobile number',
          'اكتب رقم موبايل مصري صحيح مكوّن من 11 رقمًا',
        ),
        isError: true,
      );
      return;
    }

    setState(() => _isProfileSaving = true);
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'name': _nameController.text.trim(),
        'phone': phone,
      });
      if (!mounted) return;
      _showMessage(
        context.tr(
          'Profile updated successfully',
          'تم تحديث الملف الشخصي بنجاح',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        context.tr(
          'Could not update your profile',
          'تعذر تحديث الملف الشخصي',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isProfileSaving = false);
    }
  }

  Future<void> _showAddressEditor({String? existingAddress}) async {
    var addressValue = existingAddress ?? '';
    final address = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          existingAddress == null
              ? context.tr('Add address', 'إضافة عنوان')
              : context.tr('Edit address', 'تعديل العنوان'),
        ),
        content: TextFormField(
          initialValue: existingAddress ?? '',
          onChanged: (value) => addressValue = value,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: context.tr('Complete address', 'العنوان كاملًا'),
            hintText: context.tr(
              'Area, street, building, floor and apartment',
              'المنطقة، الشارع، رقم العقار، الدور والشقة',
            ),
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () {
              final value = addressValue.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(context.tr('Save', 'حفظ')),
          ),
        ],
      ),
    );
    if (address == null || !mounted) return;
    await _saveAddress(address, existingAddress: existingAddress);
  }

  Future<void> _saveAddress(
    String address, {
    String? existingAddress,
  }) async {
    final userId = _userId;
    if (userId == null || _isAddressBusy) return;
    final normalized = address.trim();

    final duplicate = _addresses.any(
      (item) =>
          item != existingAddress &&
          item.toLowerCase() == normalized.toLowerCase(),
    );
    if (duplicate) {
      _showMessage(
        context.tr('This address is already saved', 'هذا العنوان محفوظ بالفعل'),
        isError: true,
      );
      return;
    }

    setState(() => _isAddressBusy = true);
    try {
      if (existingAddress == null) {
        await _client.from('user_addresses').insert({
          'user_id': userId,
          'address': normalized,
        });
        _addresses.add(normalized);
      } else {
        await _client
            .from('user_addresses')
            .update({'address': normalized})
            .eq('user_id', userId)
            .eq('address', existingAddress);
        final index = _addresses.indexOf(existingAddress);
        if (index >= 0) _addresses[index] = normalized;
        if (_prefs.getSelectedAddress(userId) == existingAddress) {
          await _prefs.setSelectedAddress(userId, normalized);
        }
      }
      await _prefs.replaceSavedAddresses(userId, _addresses);
      if (!mounted) return;
      setState(() {});
      _showMessage(
        existingAddress == null
            ? context.tr('Address saved', 'تم حفظ العنوان')
            : context.tr('Address updated', 'تم تعديل العنوان'),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        context.tr(
          'Could not save the address',
          'تعذر حفظ العنوان',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAddressBusy = false);
    }
  }

  Future<void> _deleteAddress(String address) async {
    final userId = _userId;
    if (userId == null || _isAddressBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete address?', 'حذف العنوان؟')),
        content: Text(
          context.tr(
            'This address will be removed from your saved addresses.',
            'سيتم حذف هذا العنوان من العناوين المحفوظة.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel', 'إلغاء')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.tr('Delete', 'حذف'),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isAddressBusy = true);
    try {
      await _client
          .from('user_addresses')
          .delete()
          .eq('user_id', userId)
          .eq('address', address);
      _addresses.remove(address);
      await _prefs.replaceSavedAddresses(userId, _addresses);

      if (_prefs.getSelectedAddress(userId) == address) {
        if (_addresses.isEmpty) {
          await _prefs.clearSelectedAddress(userId);
        } else {
          await _prefs.setSelectedAddress(userId, _addresses.first);
        }
      }
      if (!mounted) return;
      setState(() {});
      _showMessage(context.tr('Address deleted', 'تم حذف العنوان'));
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        context.tr('Could not delete the address', 'تعذر حذف العنوان'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAddressBusy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;

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
          context.loc.personalInfo,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isInitialLoading
          ? const Center(child: AntigravityLoaderCore(size: 80))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel(
                    context.tr('Account Details', 'تفاصيل الحساب'),
                  ),
                  const SizedBox(height: 16),
                  _card(
                    child: Column(
                      children: [
                        _buildInputField(
                          label: context.tr('Full Name', 'الاسم الكامل'),
                          controller: _nameController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: context.tr('Phone Number', 'رقم الهاتف'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildReadOnlyField(
                          label: context.loc.email,
                          value: user?.email ?? '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel(
                        context.tr('Saved Addresses', 'العناوين المحفوظة'),
                      ),
                      TextButton.icon(
                        onPressed:
                            _isAddressBusy ? null : () => _showAddressEditor(),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(context.tr('Add', 'إضافة')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_addresses.isEmpty)
                    _emptyAddressesCard()
                  else
                    for (final address in _addresses) ...[
                      _addressCard(address),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isProfileSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProfileSaving
                        ? const AntigravityLoaderCore(size: 24)
                        : Text(
                            context.tr('Save Changes', 'حفظ التغييرات'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyAddressesCard() {
    return _card(
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 38,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'No saved addresses yet',
              'لا توجد عناوين محفوظة حتى الآن',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
              'Addresses added during checkout will appear here automatically.',
              'أي عنوان تضيفه أثناء الطلب سيظهر هنا تلقائيًا.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(String address) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('Edit address', 'تعديل العنوان'),
            onPressed: _isAddressBusy
                ? null
                : () => _showAddressEditor(existingAddress: address),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
          IconButton(
            tooltip: context.tr('Delete address', 'حذف العنوان'),
            onPressed: _isAddressBusy ? null : () => _deleteAddress(address),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
