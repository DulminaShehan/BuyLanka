import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/rider/presentation/rider_application_status_screen.dart';
import 'package:buylanka/features/rider/registration/presentation/rider_registration_screen.dart';
import 'package:buylanka/main.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/rider_model.dart';

class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('RiderRegistrationScreen renders Step 1 and form fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RiderRegistrationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Stepper
    expect(find.text('Rider Registration'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);

    // Verify Fields
    expect(find.text('Full Name (as per NIC)'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Account Password'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('NIC Number'), findsOneWidget);
    expect(find.text('Residential Address'), findsOneWidget);

    // Verify Continue Button
    expect(find.text('Continue to Step 2 →'), findsOneWidget);
  });

  testWidgets('RiderApplicationStatusScreen renders pending timeline and details', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(
                isLoading: false,
                profile: ProfileModel(
                  id: 'test-user-123',
                  fullName: 'Kasun Perera',
                  email: 'kasun@example.com',
                  role: 'rider',
                  status: 'pending',
                ),
                rider: RiderModel(
                  id: 'test-user-123',
                  vehicleType: 'motorcycle',
                  vehicleNumber: 'WP BCD-1234',
                  drivingLicenseNumber: 'B1234567',
                  verificationStatus: 'pending',
                ),
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: RiderApplicationStatusScreen(
            applicationId: 'APP-TEST1234',
            fullName: 'Kasun Perera',
            vehicleType: 'Motorcycle',
            vehicleNumber: 'WP BCD-1234',
            status: 'PENDING',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Application Status'), findsOneWidget);
    expect(find.text('PENDING APPROVAL'), findsOneWidget);
    expect(find.text('Your rider application has been submitted successfully.'), findsOneWidget);
    expect(find.text('Your application is waiting for Admin approval. Our BuyLanka team will review your identity and vehicle documents shortly.'), findsOneWidget);
    expect(find.text('Verification Progress'), findsOneWidget);
    expect(find.text('Application Submitted'), findsOneWidget);
    expect(find.text('Documents Under Review'), findsOneWidget);
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text('WP BCD-1234'), findsOneWidget);
    expect(find.text('Check Latest Status'), findsOneWidget);
    expect(find.text('Return to Partner Portal'), findsOneWidget);
  });

  testWidgets('BuyLankaApp routes unapproved rider to RiderApplicationStatusScreen', (WidgetTester tester) async {
    const pendingProfile = ProfileModel(
      id: 'rider_pending_1',
      fullName: 'Kamal Rider',
      email: 'kamal@gmail.com',
      role: 'rider',
      status: 'pending',
    );

    const pendingRider = RiderModel(
      id: 'rider_pending_1',
      vehicleType: 'motorcycle',
      vehicleNumber: 'WP BCD-9999',
      drivingLicenseNumber: 'B1234567',
      verificationStatus: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(
                isLoading: false,
                profile: pendingProfile,
                rider: pendingRider,
              ),
            );
          }),
        ],
        child: const BuyLankaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify unapproved rider sees Application Status Screen, NOT Rider Dashboard
    expect(find.byType(RiderApplicationStatusScreen), findsOneWidget);
    expect(find.text('Application Status'), findsOneWidget);
    expect(find.text('PENDING APPROVAL'), findsOneWidget);
  });
}

