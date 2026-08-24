import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/seller_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Authenticate with email & password and ensure user is an approved Seller
  Future<ProfileModel> signInSeller({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Invalid login credentials');
    }

    // Verify role in public.profiles table
    final profile = await getProfile(user.id);
    if (profile == null) {
      await _client.auth.signOut();
      throw const AuthException('Seller profile not found. Please contact BuyLanka administration.');
    }

    if (profile.role != 'seller') {
      await _client.auth.signOut();
      throw AuthException(
        'Access Denied: Account "${profile.email}" is registered as a ${profile.role}. This app is for verified Sellers & Restaurants only.',
      );
    }

    if (profile.status != 'active') {
      await _client.auth.signOut();
      throw const AuthException(
        'Account Suspended or Inactive. Please contact BuyLanka vendor support.',
      );
    }

    return profile;
  }

  /// Get profile by user ID
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Get seller vendor details
  Future<SellerModel?> getSellerDetails(String sellerId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.sellersTable)
          .select('*, profile:${SupabaseConstants.profilesTable}!id(*)')
          .eq('id', sellerId)
          .maybeSingle();

      if (data == null) return null;
      return SellerModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
