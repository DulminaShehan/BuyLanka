import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buylanka/core/errors/auth_error_handler.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/rider/registration/models/rider_registration_model.dart';
import 'package:buylanka/repositories/rider_registration_repository.dart';

class RiderRegistrationState {
  final bool isLoading;
  final String? errorMessage;
  final int currentStep;
  final RiderApplicationResult? applicationResult;
  final Map<String, XFile> documents;
  final XFile? profilePhoto;

  const RiderRegistrationState({
    this.isLoading = false,
    this.errorMessage,
    this.currentStep = 0,
    this.applicationResult,
    this.documents = const {},
    this.profilePhoto,
  });

  bool get hasNicFront => documents.containsKey('nic_front');
  bool get hasNicBack => documents.containsKey('nic_back');
  bool get hasDrivingLicense => documents.containsKey('driving_license');
  bool get hasVehicleReg => documents.containsKey('vehicle_registration');
  bool get hasVehicleInsurance => documents.containsKey('vehicle_insurance');

  bool get areAllDocumentsUploaded =>
      hasNicFront &&
      hasNicBack &&
      hasDrivingLicense &&
      hasVehicleReg &&
      hasVehicleInsurance;

  RiderRegistrationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? currentStep,
    RiderApplicationResult? applicationResult,
    Map<String, XFile>? documents,
    XFile? profilePhoto,
  }) {
    return RiderRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentStep: currentStep ?? this.currentStep,
      applicationResult: applicationResult ?? this.applicationResult,
      documents: documents ?? this.documents,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}

final riderRegistrationControllerProvider =
    StateNotifierProvider<RiderRegistrationController, RiderRegistrationState>((ref) {
  final repo = ref.watch(riderRegistrationRepositoryProvider);
  return RiderRegistrationController(repo, ref);
});

class RiderRegistrationController extends StateNotifier<RiderRegistrationState> {
  final RiderRegistrationRepository _repository;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  RiderRegistrationController(this._repository, this._ref)
      : super(const RiderRegistrationState());

  void setStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  Future<void> pickProfilePhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        state = state.copyWith(profilePhoto: picked, clearError: true);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to access camera/photo: $e');
    }
  }

  Future<void> pickDocument(String docType, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        final updated = Map<String, XFile>.from(state.documents);
        updated[docType] = picked;
        state = state.copyWith(documents: updated, clearError: true);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick document: $e');
    }
  }

  void removeDocument(String docType) {
    final updated = Map<String, XFile>.from(state.documents);
    updated.remove(docType);
    state = state.copyWith(documents: updated);
  }

  Future<bool> submitApplication(RiderRegistrationData data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Read document bytes for upload
      final documentBytesMap = <String, Uint8List>{};
      for (final entry in state.documents.entries) {
        final bytes = await entry.value.readAsBytes();
        documentBytesMap[entry.key] = bytes;
      }

      if (state.profilePhoto != null) {
        final photoBytes = await state.profilePhoto!.readAsBytes();
        documentBytesMap['profile_photo'] = photoBytes;
      }

      // 2. Submit to repository
      final result = await _repository.submitApplication(
        data: data,
        documentBytesMap: documentBytesMap,
      );

      // 3. Update global Auth state so rider identity is recognized
      _ref.read(authControllerProvider.notifier).setRiderState(
            profile: result.profile,
            rider: result.rider,
          );

      state = state.copyWith(
        isLoading: false,
        applicationResult: result,
        clearError: true,
      );
      return true;
    } catch (e, stackTrace) {
      final errorMsg = AuthErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        context: 'Rider Registration',
      );
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  void reset() {
    state = const RiderRegistrationState();
  }
}
