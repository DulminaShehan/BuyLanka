import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/rider/profile/presentation/rider_edit_profile_screen.dart';
import 'package:buylanka/features/rider/profile/presentation/rider_profile_screen.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/rider_model.dart';

class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testProfile = ProfileModel(
    id: 'test_rider_uuid',
    fullName: 'Kasun Chamara Perera',
    email: 'kasun@buylanka.lk',
    phoneNumber: '0771234567',
    role: 'rider',
    status: 'active',
  );

  const testRider = RiderModel(
    id: 'test_rider_uuid',
    vehicleType: 'motorcycle',
    vehicleNumber: 'WP BCD-1234',
    vehicleModel: 'Honda Dio 110',
    vehicleColor: 'Matte Blue',
    drivingLicenseNumber: 'B1234567',
    residentialAddress: '45 Galle Road, Colombo 03',
    assignedZone: 'Colombo Central',
    verificationStatus: 'approved',
    profileUpdateStatus: 'approved',
  );

  testWidgets('RiderProfileScreen displays rider details and Edit Profile button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(
                isLoading: false,
                profile: testProfile,
                rider: testRider,
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: RiderProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify profile details
    expect(find.text('Kasun Chamara Perera'), findsOneWidget);
    expect(find.text('kasun@buylanka.lk'), findsOneWidget);
    expect(find.text('Verified BuyLanka Rider'), findsOneWidget);
    expect(find.text('WP BCD-1234'), findsOneWidget);
    expect(find.text('Honda Dio 110'), findsOneWidget);
    expect(find.text('Matte Blue'), findsOneWidget);
    expect(find.text('45 Galle Road, Colombo 03'), findsOneWidget);

    // Verify Edit Profile button
    expect(find.text('Edit Profile & Vehicle Details'), findsOneWidget);
  });

  testWidgets('RiderProfileScreen displays pending review warning when status is pending_review', (WidgetTester tester) async {
    const pendingRider = RiderModel(
      id: 'test_rider_uuid',
      vehicleType: 'motorcycle',
      vehicleNumber: 'WP BCD-1234',
      drivingLicenseNumber: 'B1234567',
      profileUpdateStatus: 'pending_review',
      verificationStatus: 'approved',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(
                isLoading: false,
                profile: testProfile,
                rider: pendingRider,
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: RiderProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your vehicle or license details update is pending review by Admin.'), findsOneWidget);
  });

  testWidgets('RiderEditProfileScreen renders all editable fields and pre-fills existing info', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(
                isLoading: false,
                profile: testProfile,
                rider: testRider,
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: RiderEditProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Section Headers
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Vehicle & Fleet Information'), findsOneWidget);

    // Verify Pre-filled Fields
    expect(find.text('Kasun Chamara Perera'), findsOneWidget);
    expect(find.text('0771234567'), findsOneWidget);
    expect(find.text('kasun@buylanka.lk'), findsOneWidget);
    expect(find.text('45 Galle Road, Colombo 03'), findsOneWidget);
    expect(find.text('Honda Dio 110'), findsOneWidget);
    expect(find.text('Matte Blue'), findsOneWidget);
    expect(find.text('WP BCD-1234'), findsOneWidget);
    expect(find.text('B1234567'), findsOneWidget);

    // Verify Save Button
    expect(find.text('Save Profile Changes'), findsOneWidget);
  });
}

