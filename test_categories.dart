// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/config/supabase_config.dart';

void main() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  final client = Supabase.instance.client;
  final res = await client.from('categories').select('*');
  print(res);
}
