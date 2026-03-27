import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

class AuthService {
  final SupabaseClient _supabase;
  AuthService(this._supabase);

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateProfile({required String name}) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': name}),
    );
  }

  Future<void> updatePassword({required String newPassword}) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
