import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/seller_login_screen.dart';

class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SellerLoginScreen renders full partner portal UI and handles role and tab switching', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(isLoading: false, profile: null),
            );
          }),
        ],
        child: const MaterialApp(
          home: SellerLoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header & Branding
    expect(find.text('Partner Portal'), findsOneWidget);
    expect(find.text('Join as a Restaurant Partner or Delivery Rider'), findsOneWidget);
    expect(find.text('BuyLanka'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // 2. Verify Partner Selection Cards
    expect(find.text('Restaurant Partner'), findsOneWidget);
    expect(find.text('Manage shop & food menu'), findsOneWidget);
    expect(find.text('Delivery Rider'), findsOneWidget);
    expect(find.text('Deliver orders & earn'), findsOneWidget);

    // 3. Verify Default Restaurant Sign In State
    expect(find.text('Sign In to manage orders and menu for your restaurant.'), findsNothing); // Case check
    expect(find.text('Sign in to manage orders and menu for your restaurant.'), findsOneWidget);
    expect(find.text('Restaurant Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In as Restaurant →'), findsOneWidget);

    // 4. Test Switching to "Delivery Rider" Role Card
    await tester.tap(find.text('Delivery Rider'));
    await tester.pumpAndSettle();

    // Verify dynamic text updates for Rider
    expect(find.text('Sign in to manage deliveries and track your earnings.'), findsOneWidget);
    expect(find.text('Rider Email'), findsOneWidget);
    expect(find.text('Sign In as Rider →'), findsOneWidget);
    expect(find.text('Register as Rider'), findsOneWidget);

    // 5. Test Switching to "Register as Rider" Tab opens Rider Registration Screen
    await tester.tap(find.text('Register as Rider'));
    await tester.pumpAndSettle();

    expect(find.text('Rider Registration'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Full Name (as per NIC)'), findsOneWidget);

    // 6. Test Back navigation returns to Partner Portal
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Sign In as Rider →'), findsOneWidget);

    // 7. Switch back to "Restaurant Partner" and test "Register Restaurant" Tab
    await tester.tap(find.text('Restaurant Partner'));
    await tester.pumpAndSettle();

    expect(find.text('Register Restaurant'), findsOneWidget);
    await tester.tap(find.text('Register Restaurant'));
    await tester.pumpAndSettle();

    // Verify Restaurant Registration fields
    expect(find.text('Restaurant / Shop Name'), findsOneWidget);
    expect(find.text('Owner / Manager Full Name'), findsOneWidget);
    expect(find.text('Business Email Address'), findsOneWidget);
    expect(find.text('Contact Phone Number'), findsOneWidget);
    expect(find.text('Restaurant Location'), findsOneWidget);
    expect(find.text('GPS Auto-fill'), findsOneWidget);
    expect(find.text('Street Address / Landmark'), findsOneWidget);
    expect(find.text('City / Town'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('Create Password'), findsOneWidget);
    expect(find.text('Register Restaurant Partner →'), findsOneWidget);

    // 8. Test Forgot Password Dialog
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.text('Send Link'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Your Password'), findsNothing);
  });
}
