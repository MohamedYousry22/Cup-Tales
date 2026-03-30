import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Result Types ─────────────────────────────────────────────────────────────

abstract class PromoResult {
  const PromoResult();
}

class PromoValid extends PromoResult {
  final double discountAmount; // absolute EGP value to subtract
  final String code;           // the validated code string
  const PromoValid({required this.discountAmount, required this.code});
}

class PromoInvalid extends PromoResult {
  final String arabicReason;
  const PromoInvalid(this.arabicReason);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class PromoCodeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Validates a promo code against the Supabase [promo_codes] table.
  /// [subtotal] is the cart total BEFORE any discount — used to compute
  /// percentage-based discounts.
  Future<PromoResult> validate(String code, double subtotal) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      print('DEBUG: Validating code: $cleanCode');

      final data = await _client
          .from('promo_codes')
          .select()
          .eq('code', cleanCode)
          .eq('active', true)
          .maybeSingle();

      print('DEBUG: Response: $data');

      if (data == null) {
        return const PromoInvalid('invalid');
      }

      // ── Check expiry_date ─────────────────────────────────────────────────
      final String? expiryRaw = data['expiry_date'] as String?;
      if (expiryRaw != null) {
        final expiry = DateTime.tryParse(expiryRaw);
        if (expiry != null && DateTime.now().toUtc().isAfter(expiry.toUtc())) {
          return const PromoInvalid('expired');
        }
      }

      // ── Check usage_limit ─────────────────────────────────────────────────
      final int usedCount = (data['used_count'] as num? ?? 0).toInt();
      final int usageLimit = (data['usage_limit'] as num? ?? 0).toInt();
      if (usageLimit > 0 && usedCount >= usageLimit) {
        return const PromoInvalid('limit');
      }

      // ── Parse discount ────────────────────────────────────────────────────
      final dynamic rawDiscount = data['discount'];
      double discountAmount = 0.0;

      if (rawDiscount is String) {
        final trimmed = rawDiscount.trim();
        if (trimmed.endsWith('%')) {
          final percent = double.tryParse(trimmed.replaceAll('%', '')) ?? 0.0;
          discountAmount = subtotal * (percent / 100);
        } else {
          discountAmount = double.tryParse(trimmed) ?? 0.0;
        }
      } else if (rawDiscount is num) {
        discountAmount = rawDiscount.toDouble();
      }

      if (discountAmount <= 0) {
        return const PromoInvalid('invalid');
      }

      discountAmount = discountAmount.clamp(0.0, subtotal);

      return PromoValid(
        discountAmount: discountAmount,
        code: (data['code'] as String? ?? cleanCode),
      );
    } catch (e, stack) {
      print('DEBUG: Query FAILED with error: $e');
      print('DEBUG: Stack trace: $stack');
      return const PromoInvalid('error');
    }
  }

  /// Increments [used_count] by 1 for the given [code].
  /// Called after a successful payment — failures are silently swallowed
  /// so they never block order confirmation.
  Future<void> incrementUsage(String code) async {
    try {
      // Fetch current count first, then update
      final data = await _client
          .from('promo_codes')
          .select('id, used_count')
          .ilike('code', code.trim())
          .maybeSingle();

      if (data == null) return;

      final int currentCount = (data['used_count'] as num? ?? 0).toInt();
      await _client
          .from('promo_codes')
          .update({'used_count': currentCount + 1})
          .eq('id', data['id'] as Object);
    } catch (_) {
      // Non-critical — don't rethrow
    }
  }
}
