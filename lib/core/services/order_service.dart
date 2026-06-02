import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Saves a new order to the [orders] table.
  ///
  /// [status] is intentionally NOT sent; cash orders use the DB default.
  ///
  /// Returns the generated order_id on success.
  Future<String?> saveOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double total,
    String? branchId,
    String? branchName,
    String? appliedPromo,
    double promoDiscount = 0.0,
  }) async {
    try {
      final response = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            // No 'status' field; DB default is applied automatically.
            'total_amount': total,
            'items': items,
            'branch_id': branchId,
            'branch_name': branchName,
            'promo_code': appliedPromo,
            'discount_amount': promoDiscount,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final id = response['id'];
      return id?.toString();
    } catch (e) {
      throw Exception('Failed to save order: ${e.toString()}');
    }
  }
}
