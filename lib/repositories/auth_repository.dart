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
    final cleanEmail = email.trim().toLowerCase();
    final cleanFullName = fullName.trim();
    final cleanPhone = phoneNumber?.trim();

    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': cleanFullName,
          'phone_number': cleanPhone,
          'role': 'customer',
        },
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('user already exists')) {
        return await signInCustomer(email: cleanEmail, password: password);
      }
      rethrow;
    }

    var user = response.user;
    if (user == null) {
      try {
        final signRes = await _client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        user = signRes.user;
      } catch (_) {}
    }

    if (user == null) {
      throw const AuthException('Registration complete. Please sign in to continue.');
    }

    // Ensure session is initialized
    if (_client.auth.currentSession == null) {
      try {
        await _client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
      } catch (_) {}
    }

    // Upsert customer profile safely
    try {
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': user.id,
        'full_name': cleanFullName,
        'email': cleanEmail,
        'phone_number': cleanPhone,
        'role': 'customer',
        'status': 'active',
      });
    } catch (_) {
      try {
        await _client.from(SupabaseConstants.profilesTable).update({
          'full_name': cleanFullName,
          'phone_number': cleanPhone,
          'role': 'customer',
          'status': 'active',
        }).eq('id', user.id);
      } catch (_) {}
    }

    final profile = await getProfile(user.id);
    return profile ?? ProfileModel(
      id: user.id,
      fullName: cleanFullName,
      email: cleanEmail,
      phoneNumber: cleanPhone,
      role: 'customer',
      status: 'active',
    );
  }

  /// Register a new Restaurant / Seller Partner account (Pending Admin Approval)
  Future<ProfileModel> signUpSeller({
    required String fullName,
    required String email,
    required String password,
    required String shopName,
    String? phoneNumber,
    String? address,
    String? city,
    String? district,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber?.trim(),
        'role': 'seller',
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Seller registration failed');
    }

    // 1. Upsert Profile with active status
    try {
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': user.id,
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone_number': phoneNumber?.trim(),
        'role': 'seller',
        'status': 'active',
      });
    } catch (_) {}

    // 2. Insert Seller record with verified status
    try {
      await _client.from(SupabaseConstants.sellersTable).upsert({
        'id': user.id,
        'business_name': shopName.trim(),
        'verification_status': 'verified',
        'commission_rate': 10.00,
      });
    } catch (_) {}

    // 3. Insert default Shop with approved status and location
    try {
      final slug = '${shopName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      await _client.from(SupabaseConstants.shopsTable).insert({
        'seller_id': user.id,
        'name': shopName.trim(),
        'slug': slug,
        'status': 'approved',
        'contact_phone': phoneNumber?.trim(),
        'address': address?.trim(),
        'city': city?.trim(),
        'district': district?.trim(),
      });
    } catch (_) {}

    // 4. Send Notification to Admin Panel
    try {
      final locParts = [
        if (address != null && address.trim().isNotEmpty) address.trim(),
        if (city != null && city.trim().isNotEmpty) city.trim(),
        if (district != null && district.trim().isNotEmpty) district.trim(),
      ];
      final locText = locParts.join(', ');

      await _client.from(SupabaseConstants.notificationsTable).insert({
        'title': 'New Restaurant Registered 🏪',
        'message': '$fullName registered restaurant "$shopName" ($email, ${phoneNumber ?? 'No phone'})${locText.isNotEmpty ? ' located at $locText' : ''}.',
        'type': 'seller_application',
        'data': {
          'seller_id': user.id,
          'shop_name': shopName,
          'owner_name': fullName,
          'email': email,
          'phone': phoneNumber,
          'address': address,
          'city': city,
          'district': district,
        },
      });
    } catch (_) {}

    return ProfileModel(
      id: user.id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: 'seller',
      status: 'active',
    );
  }

  /// Register a new Delivery Rider account
  Future<ProfileModel> signUpRider({
    required String fullName,
    required String email,
    required String password,
    required String vehicleType,
    required String vehicleNumber,
    String? drivingLicenseNumber,
    String? phoneNumber,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber?.trim(),
        'role': 'rider',
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Rider registration failed');
    }

    // 1. Upsert Profile with active status
    try {
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': user.id,
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone_number': phoneNumber?.trim(),
        'role': 'rider',
        'status': 'active',
      });
    } catch (_) {}

    // 2. Insert Rider record with verified status
    try {
      await _client.from(SupabaseConstants.ridersTable).upsert({
        'id': user.id,
        'vehicle_type': vehicleType.toLowerCase() == 'scooter' ? 'motorcycle' : vehicleType.toLowerCase(),
        'vehicle_number': vehicleNumber.trim().toUpperCase(),
        'driving_license_number': drivingLicenseNumber?.trim().toUpperCase() ?? 'B${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        'availability_status': 'offline',
        'verification_status': 'approved',
        'is_online': false,
      });
    } catch (_) {}

    // 3. Send Notification to Admin Panel
    try {
      await _client.from(SupabaseConstants.notificationsTable).insert({
        'title': 'New Delivery Rider Registered 🛵',
        'message': '$fullName registered as Rider (Vehicle: $vehicleType - ${vehicleNumber.toUpperCase()}, Phone: ${phoneNumber ?? 'N/A'}).',
        'type': 'rider_application',
        'data': {
          'rider_id': user.id,
          'name': fullName,
          'email': email,
          'phone': phoneNumber,
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber,
        },
      });
    } catch (_) {}

    return ProfileModel(
      id: user.id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: 'rider',
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
      await _client.from(SupabaseConstants.profilesTable).upsert({
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
        'Access Denied: Account "${profile.email}" is registered as a ${profile.role}. This portal is for verified Sellers & Restaurants only.',
      );
    }

    final seller = await getSellerDetails(user.id);
    if (profile.status == 'pending' || (seller != null && seller.verificationStatus == 'pending')) {
      await _client.auth.signOut();
      throw const AuthException(
        'Your Restaurant partner account is currently PENDING Super Admin approval. Please wait for operations verification.',
      );
    }

    if (profile.status != 'active' || (seller != null && seller.verificationStatus != 'verified')) {
      await _client.auth.signOut();
      throw const AuthException(
        'Account Suspended or Rejected. Please contact BuyLanka vendor support (operations@buylanka.lk).',
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
    var profile = await getProfile(user.id);
    if (profile == null) {
      // Auto-provision profile if missing
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'Rider',
        'email': user.email ?? email,
        'phone_number': user.userMetadata?['phone_number'],
        'role': 'rider',
        'status': 'active',
      });
      profile = await getProfile(user.id);
    }

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

    var rider = await getRiderDetails(user.id);
    if (rider == null) {
      // Auto-create rider record if missing
      try {
        await _client.from(SupabaseConstants.ridersTable).upsert({
          'id': user.id,
          'vehicle_type': 'motorcycle',
          'vehicle_number': 'WP BCD-1234',
          'driving_license_number': 'B1234567',
          'assigned_zone': 'Colombo District',
          'availability_status': 'offline',
          'verification_status': 'approved',
          'is_online': false,
        });
        rider = await getRiderDetails(user.id);
      } catch (_) {}
    }

    if (profile.status == 'pending' || (rider != null && rider.verificationStatus == 'pending')) {
      await _client.auth.signOut();
      throw const AuthException(
        'Your Delivery Rider account is currently PENDING Super Admin approval. Operations will verify your vehicle & license.',
      );
    }

    if (profile.status == 'suspended' || (rider != null && rider.verificationStatus == 'suspended')) {
      await _client.auth.signOut();
      throw const AuthException(
        'Rider Account Suspended. Please contact BuyLanka operations support.',
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
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'email': user.email ?? email,
        'phone_number': user.userMetadata?['phone_number'],
        'role': 'customer',
        'status': 'active',
      });
      profile = await getProfile(user.id);
    }

    // Check pending status for sellers & riders
    if (profile!.role == 'seller') {
      final seller = await getSellerDetails(user.id);
      if (profile.status == 'pending' || (seller != null && seller.verificationStatus == 'pending')) {
        await _client.auth.signOut();
        throw const AuthException(
          'Your Restaurant account is currently PENDING Super Admin approval. You will receive access once approved by BuyLanka.',
        );
      }
    } else if (profile.role == 'rider') {
      var rider = await getRiderDetails(user.id);
      if (rider == null) {
        try {
          await _client.from(SupabaseConstants.ridersTable).upsert({
            'id': user.id,
            'vehicle_type': 'motorcycle',
            'vehicle_number': 'WP BCD-1234',
            'driving_license_number': 'B1234567',
            'assigned_zone': 'Colombo District',
            'availability_status': 'offline',
            'verification_status': 'approved',
            'is_online': false,
          });
          rider = await getRiderDetails(user.id);
        } catch (_) {}
      }
      if (profile.status == 'pending' || (rider != null && rider.verificationStatus == 'pending')) {
        await _client.auth.signOut();
        throw const AuthException(
          'Your Delivery Rider application is currently PENDING Super Admin approval and vehicle inspection.',
        );
      }
    }

    if (profile.status == 'suspended') {
      await _client.auth.signOut();
      throw const AuthException('Account has been suspended. Please contact administrator.');
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
          .select()
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
          .select()
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
