import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/models/rider_earnings_model.dart';
import 'package:buylanka/repositories/rider_repository.dart';

class RiderEarningsState {
  final RiderEarningsModel earnings;
  final bool isLoading;
  final String? errorMessage;

  const RiderEarningsState({
    this.earnings = const RiderEarningsModel(),
    this.isLoading = false,
    this.errorMessage,
  });

  RiderEarningsState copyWith({
    RiderEarningsModel? earnings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RiderEarningsState(
      earnings: earnings ?? this.earnings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RiderEarningsController extends StateNotifier<RiderEarningsState> {
  final RiderRepository _repository;
  final String? _riderId;

  RiderEarningsController(this._repository, this._riderId) : super(const RiderEarningsState(isLoading: true)) {
    if (_riderId != null) {
      loadEarnings();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadEarnings() async {
    if (_riderId == null) return;
    try {
      state = state.copyWith(isLoading: true);
      final earnings = await _repository.getRiderEarnings(_riderId);
      state = state.copyWith(earnings: earnings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final riderEarningsControllerProvider = StateNotifierProvider<RiderEarningsController, RiderEarningsState>((ref) {
  final repository = ref.watch(riderRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  final riderId = authState.rider?.id ?? authState.profile?.id;
  return RiderEarningsController(repository, riderId);
});
