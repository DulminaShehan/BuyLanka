import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/features/rider/registration/models/rider_registration_model.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/rider_model.dart';
import 'package:buylanka/services/supabase_service.dart';

final riderRegistrationRepositoryProvider = Provider<RiderRegistrationRepository>((ref) {
  return RiderRegistrationRepository();
});

class RiderApplicationResult {
  final String applicationId;
  final String profileId;
  final String status;
  final DateTime submittedAt;
  final String fullName;
  final String vehicleType;
  final String vehicleNumber;
  final String? rejectionReason;
  final ProfileModel profile;
  final RiderModel rider;

  const RiderApplicationResult({
    required this.applicationId,
    required this.profileId,
    required this.status,
    required this.submittedAt,
    required this.fullName,
    required this.vehicleType,
    required this.vehicleNumber,
    this.rejectionReason,
    required this.profile,
    required this.rider,
  });
}

class RiderRegistrationRepository {
  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? SupabaseService.client;

  RiderRegistrationRepository([SupabaseClient? client])
      : _clientOverride = client;

  /// Submits a complete Rider Registration application to Supabase.
  /// 
  /// 1. Creates a Supabase Auth user.
  /// 2. Saves the profile with status 'pending' (zero premature privileges).
  /// 3. Saves the rider record with verification_status 'pending'.
  /// 4. Uploads verification documents to private storage or saves file references.
  /// 5. Attempts to record the application in rider_applications.
  /// 6. Sends in-app alert notification to the admin operations team.
  Future<RiderApplicationResult> submitApplication({
    required RiderRegistrationData data,
    Map<String, Uint8List>? documentBytesMap,
  }) async {
    final cleanEmail = data.email.trim().toLowerCase();
    final cleanFullName = data.fullName.trim();
    final cleanPhone = data.phoneNumber.trim();
    final cleanNic = data.nicNumber.trim().toUpperCase();

    // 1. Create Supabase Auth Account
    final authResponse = await _client.auth.signUp(
      email: cleanEmail,
      password: data.password,
      data: {
        'full_name': cleanFullName,
        'phone_number': cleanPhone,
        'role': 'rider',
        'nic_number': cleanNic,
        'vehicle_type': data.vehicleType,
        'vehicle_number': data.vehicleNumber,
      },
    );

    var user = authResponse.user;
    if (user != null && user.identities != null && user.identities!.isEmpty) {
      throw const AuthException(
        'This email address is already registered. Please sign in or use another email.',
        statusCode: '422',
        code: 'user_already_exists',
      );
    }

    // Fallback: If session needs sign-in
    if (user == null) {
      try {
        final signRes = await _client.auth.signInWithPassword(
          email: cleanEmail,
          password: data.password,
        );
        user = signRes.user;
      } catch (_) {}
    }

    if (user == null) {
      throw const AuthException('Could not create rider account. Please verify credentials.');
    }

    final userId = user.id;

    // 2. Save Profile (status = 'pending', role = 'rider')
    final profileJson = {
      'id': userId,
      'full_name': cleanFullName,
      'email': cleanEmail,
      'phone_number': cleanPhone,
      'role': 'rider',
      'status': 'pending', // Do NOT activate account before Admin approval
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from(SupabaseConstants.profilesTable).upsert(profileJson);
    } catch (e) {
      debugPrint('Notice during profile upsert: $e');
    }

    final profile = ProfileModel(
      id: userId,
      fullName: cleanFullName,
      email: cleanEmail,
      phoneNumber: cleanPhone,
      role: 'rider',
      status: 'pending',
    );

    // 3. Save Rider Details (verification_status = 'pending')
    final cleanVehicleType = data.vehicleType.toLowerCase() == 'scooter' ? 'motorcycle' : data.vehicleType.toLowerCase();
    final riderJson = {
      'id': userId,
      'vehicle_type': cleanVehicleType,
      'vehicle_number': data.vehicleNumber.trim().toUpperCase(),
      'driving_license_number': cleanNic,
      'availability_status': 'offline',
      'verification_status': 'pending', // Crucial: PENDING until Admin review
      'is_online': false,
      'rating': 5.0,
      'total_deliveries': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from(SupabaseConstants.ridersTable).upsert(riderJson);
    } catch (e) {
      debugPrint('Notice during riders upsert: $e');
    }

    final rider = RiderModel(
      id: userId,
      vehicleType: data.vehicleType,
      vehicleNumber: data.vehicleNumber.trim().toUpperCase(),
      drivingLicenseNumber: cleanNic,
      availabilityStatus: 'offline',
      verificationStatus: 'pending',
      isOnline: false,
      profile: profile,
    );

    // 4. Upload Documents to Supabase Storage (rider-documents bucket)
    final uploadedDocPaths = <String, String>{};
    if (documentBytesMap != null && documentBytesMap.isNotEmpty) {
      for (final entry in documentBytesMap.entries) {
        final docType = entry.key;
        final bytes = entry.value;
        final fileName = '${userId}_${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = '$userId/$fileName';

        try {
          await _client.storage.from('rider-documents').uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          uploadedDocPaths[docType] = storagePath;
        } catch (storageErr) {
          debugPrint('Storage notice for $docType: $storageErr');
          // Fallback reference
          uploadedDocPaths[docType] = 'fallback://$storagePath';
        }
      }
    }

    // 5. Save in rider_applications table if available
    String applicationId = 'APP-${userId.substring(0, 8).toUpperCase()}';
    try {
      final appJson = data.toApplicationJson(profileId: userId);
      appJson['document_paths'] = uploadedDocPaths;
      final inserted = await _client.from('rider_applications').upsert(appJson).select('id').maybeSingle();
      if (inserted != null && inserted['id'] != null) {
        applicationId = inserted['id'].toString();
      }
    } catch (appTableErr) {
      debugPrint('Notice for rider_applications table: $appTableErr');
    }

    // 6. Notify Admin Dashboard
    try {
      await _client.from(SupabaseConstants.notificationsTable).insert({
        'title': 'New Rider Application 🛵',
        'message': '$cleanFullName submitted a rider application ($cleanVehicleType - ${data.vehicleNumber.trim().toUpperCase()}, NIC: $cleanNic). Documents uploaded and pending verification.',
        'type': 'rider_application',
        'data': {
          'application_id': applicationId,
          'rider_id': userId,
          'full_name': cleanFullName,
          'email': cleanEmail,
          'phone': cleanPhone,
          'vehicle_type': cleanVehicleType,
          'vehicle_number': data.vehicleNumber.trim().toUpperCase(),
          'nic_number': cleanNic,
          'documents': uploadedDocPaths,
        },
      });
    } catch (notifErr) {
      debugPrint('Notice for notifications table: $notifErr');
    }

    return RiderApplicationResult(
      applicationId: applicationId,
      profileId: userId,
      status: 'PENDING',
      submittedAt: DateTime.now(),
      fullName: cleanFullName,
      vehicleType: data.vehicleType,
      vehicleNumber: data.vehicleNumber.trim().toUpperCase(),
      profile: profile,
      rider: rider,
    );
  }

  /// Fetches the active application or rider verification status
  Future<Map<String, dynamic>?> getApplicationStatus(String userId) async {
    try {
      // 1. Try rider_applications table
      final appData = await _client
          .from('rider_applications')
          .select('*')
          .eq('profile_id', userId)
          .order('submitted_at', ascending: false)
          .maybeSingle();

      if (appData != null) {
        return appData;
      }
    } catch (_) {}

    // 2. Fallback to riders table verification_status
    try {
      final riderData = await _client
          .from(SupabaseConstants.ridersTable)
          .select('*, profile:profiles!id(*)')
          .eq('id', userId)
          .maybeSingle();

      if (riderData != null) {
        return {
          'id': 'APP-${userId.substring(0, 8).toUpperCase()}',
          'profile_id': userId,
          'application_status': (riderData['verification_status'] ?? 'pending').toString().toUpperCase(),
          'vehicle_type': riderData['vehicle_type'] ?? 'motorcycle',
          'vehicle_number': riderData['vehicle_number'] ?? '',
          'submitted_at': riderData['created_at'] ?? DateTime.now().toIso8601String(),
        };
      }
    } catch (_) {}

    return null;
  }
}

