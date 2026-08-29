import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/address_model.dart';
import 'package:buylanka/repositories/address_repository.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository();
});

class AddressState {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final bool isLoading;
  final String? errorMessage;

  const AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.errorMessage,
  });

  AddressState copyWith({
    List<AddressModel>? addresses,
    AddressModel? selectedAddress,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AddressController extends StateNotifier<AddressState> {
  final AddressRepository _repository;
  final String? _customerId;

  AddressController(this._repository, this._customerId) : super(const AddressState()) {
    if (_customerId != null) {
      loadAddresses();
    }
  }

  Future<void> loadAddresses() async {
    if (_customerId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getCustomerAddresses(_customerId);
      AddressModel? selected;
      if (list.isNotEmpty) {
        selected = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
      }
      state = state.copyWith(
        addresses: list,
        selectedAddress: selected,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<bool> createAddress({
    required String label,
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String city,
    String? district,
    String? deliveryInstructions,
    bool isDefault = false,
  }) async {
    if (_customerId == null) return false;

    state = state.copyWith(isLoading: true);
    final created = await _repository.createAddress(AddressModel(
      id: '',
      customerId: _customerId,
      label: label,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      streetAddress: streetAddress,
      city: city,
      district: district,
      deliveryInstructions: deliveryInstructions,
      isDefault: isDefault,
    ));

    if (created != null) {
      await loadAddresses();
      selectAddress(created);
      return true;
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> deleteAddress(String addressId) async {
    await _repository.deleteAddress(addressId);
    await loadAddresses();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_customerId == null) return;
    await _repository.setDefaultAddress(_customerId, addressId);
    await loadAddresses();
  }
}

final addressControllerProvider = StateNotifierProvider<AddressController, AddressState>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  final customerId = ref.watch(authControllerProvider).profile?.id;
  return AddressController(repo, customerId);
});
