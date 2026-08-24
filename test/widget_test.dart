import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/seller_login_screen.dart';
import 'package:buylanka/main.dart';

// Fake AuthController for testing
class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Renders Seller Login Screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(isLoading: false, profile: null),
            );
          }),
        ],
        child: const BuyLankaSellerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify login screen elements
    expect(find.byType(SellerLoginScreen), findsOneWidget);
    expect(find.text('Merchant & Restaurant Portal'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
