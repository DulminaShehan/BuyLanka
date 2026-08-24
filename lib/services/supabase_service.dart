import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? 'https://wwwwdgtonybfslkdfjjd.supabase.co';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_W3GJpglTCdbrxrKf3JerNg_FX92sREI';

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
    );
  }
}
