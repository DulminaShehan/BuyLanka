import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  bool get isAuthenticated => profile != null && profile!.isActive;
  bool get isCustomer => profile != null && profile!.role == 'customer' && profile!.isActive;
  bool get isSeller => profile != null && profile!.role == 'seller' && profile!.isActive;
  bool get isRider => profile != null && profile!.role == 'rider' && profile!.isActive;

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
      final profile = await _authRepository.getProfile(user.id);
      if (profile != null && profile.isActive) {
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
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
      state = state.copyWith(profile: profile, isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
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
