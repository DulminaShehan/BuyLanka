import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/splash/presentation/splash_screen.dart';
import 'package:buylanka/main.dart';

// Fake AuthController for testing loading state
class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SplashScreen renders official branding and loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Verify loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify Image.asset widgets are present for waves and logo
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('BuyLankaApp displays SplashScreen when authState is loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(isLoading: true, profile: null),
            );
          }),
        ],
        child: const BuyLankaApp(),
      ),
    );

    await tester.pump();

    // Verify SplashScreen is rendered
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

