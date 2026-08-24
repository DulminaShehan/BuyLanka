import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/seller_model.dart';
import 'package:buylanka/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthStateData {
  final ProfileModel? profile;
  final SellerModel? seller;
  final bool isLoading;
  final String? errorMessage;

  const AuthStateData({
    this.profile,
    this.seller,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => profile != null && profile!.isSeller && profile!.isActive;

  AuthStateData copyWith({
    ProfileModel? profile,
    SellerModel? seller,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthStateData(
      profile: clearUser ? null : (profile ?? this.profile),
      seller: clearUser ? null : (seller ?? this.seller),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthStateData> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthStateData(isLoading: true)) {
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
      if (profile != null && profile.isSeller && profile.isActive) {
        final seller = await _authRepository.getSellerDetails(user.id);
        state = state.copyWith(profile: profile, seller: seller, isLoading: false);
      } else {
        await _authRepository.signOut();
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> signIn({
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final profile = await _authRepository.getProfile(user.id);
    final seller = await _authRepository.getSellerDetails(user.id);
    state = state.copyWith(profile: profile, seller: seller);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.signOut();
    state = const AuthStateData(isLoading: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateData>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});
