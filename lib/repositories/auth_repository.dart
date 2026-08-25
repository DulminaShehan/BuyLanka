import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/rider_model.dart';
import 'package:buylanka/models/seller_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Register a new Customer account
  Future<ProfileModel> signUpCustomer({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber?.trim(),
        'role': 'customer',
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Customer registration failed');
    }

    // Upsert customer profile
    await _client.from(SupabaseConstants.profilesTable).upsert({
      'id': user.id,
      'full_name': fullName.trim(),
      'email': email.trim(),
      'phone_number': phoneNumber?.trim(),
      'role': 'customer',
      'status': 'active',
    });

    final profile = await getProfile(user.id);
    return profile ?? ProfileModel(
      id: user.id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: 'customer',
      status: 'active',
    );
  }

  /// Authenticate Customer
  Future<ProfileModel> signInCustomer({
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

    var profile = await getProfile(user.id);
    if (profile == null) {
      // Auto-provision customer profile if missing
      await _client.from(SupabaseConstants.profilesTable).insert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'Customer',
        'email': user.email ?? email,
        'phone_number': user.userMetadata?['phone_number'],
        'role': 'customer',
        'status': 'active',
      });
      profile = await getProfile(user.id);
    }

    return profile!;
  }

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
        'Access Denied: Account "${profile.email}" is registered as a ${profile.role}. This app portal is for verified Sellers & Restaurants only.',
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

  /// Authenticate with email & password and ensure user is an approved Rider
  Future<ProfileModel> signInRider({
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
      throw const AuthException('Rider profile not found. Please contact BuyLanka administration.');
    }

    if (profile.role != 'rider') {
      await _client.auth.signOut();
      throw AuthException(
        'Access Denied: Account "${profile.email}" is registered as a ${profile.role}. This portal is for authorized Delivery Riders only.',
      );
    }

    if (profile.status != 'active') {
      await _client.auth.signOut();
      throw const AuthException(
        'Rider Account Suspended or Inactive. Please contact BuyLanka operations support.',
      );
    }

    return profile;
  }

  /// General Sign In for any allowed account
  Future<ProfileModel> signInGeneric({
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

    var profile = await getProfile(user.id);
    if (profile == null) {
      // Create customer profile as default fallback
      await _client.from(SupabaseConstants.profilesTable).insert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'email': user.email ?? email,
        'phone_number': user.userMetadata?['phone_number'],
        'role': 'customer',
        'status': 'active',
      });
      profile = await getProfile(user.id);
    }

    if (profile!.status != 'active') {
      await _client.auth.signOut();
      throw const AuthException('Account is not active. Please contact administrator.');
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

  /// Update customer profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      if (fullName != null) 'full_name': fullName.trim(),
      if (phoneNumber != null) 'phone_number': phoneNumber.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client
        .from(SupabaseConstants.profilesTable)
        .update(updates)
        .eq('id', userId);
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

  /// Get rider details
  Future<RiderModel?> getRiderDetails(String riderId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ridersTable)
          .select('*, profile:${SupabaseConstants.profilesTable}!id(*)')
          .eq('id', riderId)
          .maybeSingle();

      if (data == null) return null;
      return RiderModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
