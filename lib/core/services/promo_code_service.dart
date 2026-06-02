import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Result Types ─────────────────────────────────────────────────────────────

abstract class PromoResult {
  const PromoResult();
}

class PromoValid extends PromoResult {
  final double discountAmount; // absolute EGP value to subtract
  final String code; // the validated code string
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

      final response = await _client
          .from('promo_codes')
          .select()
          .eq('code', cleanCode)
          .eq('active', true)
          .maybeSingle();

      if (response == null) {
        return const PromoInvalid('الكود غير صحيح');
      }

      // ── Check expires_at ─────────────────────────────────────────────────
      final String? expiryRaw = response['expires_at'] as String?;
      if (expiryRaw != null) {
        final expiry = DateTime.parse(expiryRaw);
        if (expiry.isBefore(DateTime.now())) {
          return const PromoInvalid('انتهت صلاحية الكود');
        }
      }

      // ── Check max_uses ───────────────────────────────────────────────────
      if (response['max_uses'] != null) {
        final int usedCount = (response['used_count'] as num? ?? 0).toInt();
        final int maxUses = (response['max_uses'] as num).toInt();
        if (usedCount >= maxUses) {
          return const PromoInvalid('تم استنفاد الكود');
        }
      }

      // ── Parse discount ────────────────────────────────────────────────────
      final int discount = (response['discount'] as num).toInt();
      final String discountType =
          response['discount_type']?.toString() ?? 'percent';
      double discountAmount;
      if (discountType == 'fixed') {
        discountAmount = discount.toDouble();
      } else {
        discountAmount = subtotal * discount / 100;
      }

      discountAmount = discountAmount.clamp(0.0, subtotal);

      await _client.from('promo_codes').update({
        'used_count': (response['used_count'] as num? ?? 0).toInt() + 1,
      }).eq('code', cleanCode);

      return PromoValid(
        discountAmount: discountAmount,
        code: response['code'] as String? ?? cleanCode,
      );
    } catch (_) {
      return const PromoInvalid('error');
    }
  }

  /// Increments [used_count] by 1 for the given [code].
  /// Called after a successful payment — failures are silently swallowed
  /// so they never block order confirmation.
  Future<void> incrementUsage(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final response = await _client
          .from('promo_codes')
          .select('used_count')
          .eq('code', cleanCode)
          .eq('active', true)
          .maybeSingle();

      if (response == null) return;

      final int currentCount = (response['used_count'] as num? ?? 0).toInt();
      await _client.from('promo_codes').update({
        'used_count': currentCount + 1,
      }).eq('code', cleanCode);
    } catch (_) {
      // Non-critical — don't rethrow
    }
  }
}
