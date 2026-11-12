class RiderRegistrationData {
  // Step 1: Personal Information
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String nicNumber;
  final String residentialAddress;
  final String city;
  final String? profilePhotoPath;

  // Step 2: Vehicle Information
  final String vehicleType; // 'motorcycle', 'scooter', 'bicycle', 'three_wheeler'
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColor;

  // Step 3: Document Paths / References
  final String? nicFrontPath;
  final String? nicBackPath;
  final String? drivingLicensePath;
  final String? vehicleRegistrationPath;
  final String? vehicleInsurancePath;

  const RiderRegistrationData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.nicNumber,
    required this.residentialAddress,
    required this.city,
    this.profilePhotoPath,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.vehicleColor,
    this.nicFrontPath,
    this.nicBackPath,
    this.drivingLicensePath,
    this.vehicleRegistrationPath,
    this.vehicleInsurancePath,
  });

  bool get hasAllDocuments =>
      nicFrontPath != null &&
      nicBackPath != null &&
      drivingLicensePath != null &&
      vehicleRegistrationPath != null &&
      vehicleInsurancePath != null;

  Map<String, dynamic> toApplicationJson({required String profileId}) {
    return {
      'profile_id': profileId,
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phoneNumber.trim(),
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'nic_number': nicNumber.trim().toUpperCase(),
      'residential_address': residentialAddress.trim(),
      'city': city.trim(),
      'vehicle_type': vehicleType.toLowerCase(),
      'vehicle_number': vehicleNumber.trim().toUpperCase(),
      'vehicle_model': vehicleModel.trim(),
      'vehicle_color': vehicleColor.trim(),
      'application_status': 'PENDING',
      'submitted_at': DateTime.now().toIso8601String(),
    };
  }
}

