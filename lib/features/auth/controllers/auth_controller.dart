import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/errors/auth_error_handler.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/rider_model.dart';
import 'package:buylanka/models/seller_model.dart';
import 'package:buylanka/repositories/auth_repository.dart';
import 'package:buylanka/repositories/rider_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository();
});

class AuthStateData {
  final ProfileModel? profile;
  final SellerModel? seller;
  final RiderModel? rider;
  final bool isLoading;
  final String? errorMessage;

  const AuthStateData({
    this.profile,
    this.seller,
    this.rider,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      profile != null && (profile!.isActive || (profile!.isPending && profile!.role == 'rider'));
  bool get isCustomer => profile != null && profile!.role == 'customer' && profile!.isActive;
  bool get isSeller => profile != null && profile!.role == 'seller' && profile!.isActive;
  bool get isRider => profile != null && profile!.role == 'rider';

  AuthStateData copyWith({
    ProfileModel? profile,
    SellerModel? seller,
    RiderModel? rider,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthStateData(
      profile: clearUser ? null : (profile ?? this.profile),
      seller: clearUser ? null : (seller ?? this.seller),
      rider: clearUser ? null : (rider ?? this.rider),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthStateData> {
  final AuthRepository _authRepository;
  final RiderRepository _riderRepository;

  AuthController(this._authRepository, this._riderRepository) : super(const AuthStateData(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, clearUser: true);
      return;
    }

    try {
      var profile = await _authRepository.getProfile(user.id);
      if (profile == null) {
        profile = ProfileModel(
          id: user.id,
          fullName: user.userMetadata?['full_name'] ?? 'Valued Customer',
          email: user.email ?? 'customer@buylanka.lk',
          phoneNumber: user.userMetadata?['phone_number'],
          role: user.userMetadata?['role'] ?? 'customer',
          status: 'active',
        );
        try {
          await _authRepository.updateProfile(
            userId: user.id,
            fullName: profile.fullName,
            phoneNumber: profile.phoneNumber,
          );
        } catch (_) {}
      }

      if (profile.isActive || (profile.status == 'pending' && profile.role == 'rider')) {
        if (profile.role == 'customer') {
          state = state.copyWith(profile: profile, isLoading: false);
        } else if (profile.role == 'seller') {
          final seller = await _authRepository.getSellerDetails(user.id);
          state = state.copyWith(profile: profile, seller: seller, isLoading: false);
        } else if (profile.role == 'rider') {
          var rider = await _riderRepository.getRiderById(user.id);
          rider ??= await _riderRepository.createDefaultRiderRecord(riderId: user.id);
          state = state.copyWith(profile: profile, rider: rider, isLoading: false);
        } else {
          state = state.copyWith(profile: profile, isLoading: false);
        }
      } else {
        await _authRepository.signOut();
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  /// Register Customer
  Future<bool> signUpCustomer({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _authRepository.signUpCustomer(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(profile: profile, isLoading: false, clearError: true);
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Customer Sign Up'),
      );
      return false;
    }
  }

  /// Register Restaurant / Seller Partner (Pending Super Admin Approval)
  Future<bool> signUpSeller({
    required String fullName,
    required String email,
    required String password,
    required String shopName,
    String? phoneNumber,
    String? address,
    String? city,
    String? district,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.signUpSeller(
        fullName: fullName,
        email: email,
        password: password,
        shopName: shopName,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        district: district,
      );
      state = state.copyWith(isLoading: false, clearError: true, clearUser: true);
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Seller Sign Up'),
      );
      return false;
    }
  }

  /// Register Delivery Rider Partner
  Future<bool> signUpRider({
    required String fullName,
    required String email,
    required String password,
    required String vehicleType,
    required String vehicleNumber,
    String? drivingLicenseNumber,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _authRepository.signUpRider(
        fullName: fullName,
        email: email,
        password: password,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        drivingLicenseNumber: drivingLicenseNumber,
        phoneNumber: phoneNumber,
      );
      var rider = await _riderRepository.getRiderById(profile.id);
      rider ??= await _riderRepository.createDefaultRiderRecord(
        riderId: profile.id,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        drivingLicenseNumber: drivingLicenseNumber ?? 'B1234567',
      );
      state = state.copyWith(profile: profile, rider: rider, isLoading: false, clearError: true);
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Rider Sign Up'),
      );
      return false;
    }
  }

  /// Customer Sign-In
  Future<bool> signInCustomer({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _authRepository.signInCustomer(
        email: email,
        password: password,
      );
      if (profile.role == 'rider') {
        var rider = await _riderRepository.getRiderById(profile.id);
        rider ??= await _riderRepository.createDefaultRiderRecord(riderId: profile.id);
        state = state.copyWith(profile: profile, rider: rider, isLoading: false, clearError: true);
      } else if (profile.role == 'seller') {
        final seller = await _authRepository.getSellerDetails(profile.id);
        state = state.copyWith(profile: profile, seller: seller, isLoading: false, clearError: true);
      } else {
        state = state.copyWith(profile: profile, isLoading: false, clearError: true);
      }
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Customer Sign In'),
      );
      return false;
    }
  }

  /// Universal Sign-In supporting all roles
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _authRepository.signInGeneric(
        email: email,
        password: password,
      );

      if (profile.role == 'customer') {
        state = state.copyWith(profile: profile, isLoading: false, clearError: true);
        return true;
      } else if (profile.role == 'seller') {
        final seller = await _authRepository.getSellerDetails(profile.id);
        state = state.copyWith(
          profile: profile,
          seller: seller,
          isLoading: false,
          clearError: true,
        );
        return true;
      } else if (profile.role == 'rider') {
        var rider = await _riderRepository.getRiderById(profile.id);
        rider ??= await _riderRepository.createDefaultRiderRecord(riderId: profile.id);
        state = state.copyWith(
          profile: profile,
          rider: rider,
          isLoading: false,
          clearError: true,
        );
        return true;
      } else {
        state = state.copyWith(profile: profile, isLoading: false, clearError: true);
        return true;
      }
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Universal Sign In'),
      );
      return false;
    }
  }

  /// Seller / Restaurant Sign-In with Role Verification
  Future<bool> signInSeller({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _authRepository.signInSeller(
        email: email,
        password: password,
      );
      final seller = await _authRepository.getSellerDetails(profile.id);

      state = state.copyWith(
        profile: profile,
        seller: seller,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Seller Sign In'),
      );
      return false;
    }
  }

  /// Rider-specific sign-in
  Future<bool> signInRider({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _authRepository.signInRider(
        email: email,
        password: password,
      );

      var rider = await _riderRepository.getRiderById(profile.id);
      rider ??= await _riderRepository.createDefaultRiderRecord(riderId: profile.id);

      state = state.copyWith(
        profile: profile,
        rider: rider,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Rider Sign In'),
      );
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    await _authRepository.updateProfile(
      userId: user.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );

    await refreshProfile();
  }

  /// Update ordinary rider profile fields
  Future<void> updateRiderProfileDetails({
    required String fullName,
    required String phoneNumber,
    String? residentialAddress,
    String? vehicleModel,
    String? vehicleColor,
    String? avatarUrl,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    await _riderRepository.updateRiderProfile(
      riderId: user.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      residentialAddress: residentialAddress,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      avatarUrl: avatarUrl,
    );

    await refreshProfile();
  }

  /// Submit sensitive changes for admin approval
  Future<void> submitRiderSensitiveChangeRequest({
    required Map<String, dynamic> requestedChanges,
    required Map<String, dynamic> previousValues,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    await _riderRepository.submitSensitiveChangeRequest(
      riderId: user.id,
      requestedChanges: requestedChanges,
      previousValues: previousValues,
    );

    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final profile = await _authRepository.getProfile(user.id);
    if (profile?.role == 'customer') {
      state = state.copyWith(profile: profile);
    } else if (profile?.role == 'seller') {
      final seller = await _authRepository.getSellerDetails(user.id);
      state = state.copyWith(profile: profile, seller: seller);
    } else if (profile?.role == 'rider') {
      final rider = await _riderRepository.getRiderById(user.id);
      state = state.copyWith(profile: profile, rider: rider);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordReset(email);
      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        errorMessage: AuthErrorHandler.handle(e, stackTrace: stackTrace, context: 'Password Reset'),
      );
      return false;
    }
  }

  /// Sets rider profile and state directly (e.g. after registration)
  void setRiderState({
    required ProfileModel profile,
    required RiderModel rider,
  }) {
    state = state.copyWith(
      profile: profile,
      rider: rider,
      isLoading: false,
      clearError: true,
    );
  }

  /// Clears active error message state
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.signOut();
    state = const AuthStateData(isLoading: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateData>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final riderRepository = ref.watch(riderRepositoryProvider);
  return AuthController(authRepository, riderRepository);
});
