import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/customer_auth_screen.dart';

class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CustomerAuthScreen renders full matching login UI and responds to tab switches', (WidgetTester tester) async {
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
          home: CustomerAuthScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header & Branding
    expect(find.byType(Image), findsNWidgets(2)); // Header banner & bottom wave
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // 2. Verify Sign In Inputs
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    // 3. Verify Options & Action Buttons
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In as Customer'), findsOneWidget);
    expect(find.text('OR'), findsOneWidget);
    expect(find.text('Restaurant & Rider Partner Portal'), findsOneWidget);

    // 4. Test Tab Switch to "Register"
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Create Password'), findsOneWidget);
    expect(find.text('Create Customer Account'), findsOneWidget);

    // 5. Switch back to "Sign In"
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In as Customer'), findsOneWidget);

    // 6. Test "Forgot Password?" dialog opens
    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });
}
