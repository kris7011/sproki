import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthBridge {
  static Future<String?> tokenProvider() async {
    final s = Supabase.instance.client.auth.currentSession;
    return s?.accessToken;
  }
}
