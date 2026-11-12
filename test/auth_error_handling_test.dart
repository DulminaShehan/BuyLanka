import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/errors/auth_error_handler.dart';
import 'package:buylanka/core/widgets/auth_feedback_banner.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/customer_auth_screen.dart';
import 'package:buylanka/features/auth/presentation/seller_login_screen.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/repositories/auth_repository.dart';
import 'package:buylanka/repositories/rider_repository.dart';

class MockFailingAuthRepository implements AuthRepository {
  final Exception errorToThrow;

  MockFailingAuthRepository(this.errorToThrow);

  @override
  User? get currentUser => null;

  @override
  Future<ProfileModel> signInCustomer({required String email, required String password}) async {
    throw errorToThrow;
  }

  @override
  Future<ProfileModel> signUpCustomer({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    throw errorToThrow;
  }

  @override
  Future<ProfileModel> signInSeller({required String email, required String password}) async {
    throw errorToThrow;
  }

  @override
  Future<ProfileModel> signInRider({required String email, required String password}) async {
    throw errorToThrow;
  }

  @override
  Future<ProfileModel> signUpSeller({
    required String fullName,
    required String email,
    required String password,
    required String shopName,
    String? phoneNumber,
    String? address,
    String? city,
    String? district,
  }) async {
    throw errorToThrow;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRiderRepository implements RiderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthErrorHandler Unit Tests', () {
    test('Translates user_already_exists into friendly message', () {
      const err = AuthException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      );
      final msg = AuthErrorHandler.handle(err);
      expect(msg, 'This email is already registered. Please sign in.');
      expect(msg.contains('AuthApiException'), isFalse);
      expect(msg.contains('422'), isFalse);
    });

    test('Translates invalid_credentials into friendly message', () {
      const err = AuthException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );
      final msg = AuthErrorHandler.handle(err);
      expect(msg, 'Incorrect email or password. Please try again.');
    });

    test('Translates weak_password into friendly message', () {
      const err = AuthException(
        'Password should be at least 6 characters',
        statusCode: '422',
        code: 'weak_password',
      );
      final msg = AuthErrorHandler.handle(err);
      expect(msg, 'Your password is too weak. Please choose a stronger password.');
    });

    test('Translates email_not_confirmed into friendly message', () {
      const err = AuthException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      );
      final msg = AuthErrorHandler.handle(err);
      expect(msg, 'Please verify your email before signing in.');
    });

    test('Translates network_error and SocketException into friendly message', () {
      final socketErr = const SocketException('Failed host lookup: buylanka.supabase.co');
      final msg = AuthErrorHandler.handle(socketErr);
      expect(msg, 'Unable to connect. Please check your internet connection.');

      const networkTextErr = 'ClientException with SocketException: OS Error: Network is unreachable';
      expect(AuthErrorHandler.handle(networkTextErr), 'Unable to connect. Please check your internet connection.');
    });

    test('Translates too_many_requests into friendly message', () {
      const err = AuthException(
        'For security purposes, you can only request this once every 60 seconds.',
        statusCode: '429',
        code: 'over_request_rate_limit',
      );
      final msg = AuthErrorHandler.handle(err);
      expect(msg, 'Too many attempts. Please try again later.');
    });

    test('Translates invalid_email into friendly message', () {
      const err = AuthException(
        'Unable to validate email address: invalid format',
        code: 'validation_failed',
      );
      final msg = AuthErrorHandler.handle(err);
      expect(msg, 'Please enter a valid email address.');
    });

    test('Translates unknown technical errors into friendly message without technical leak', () {
      final postgrestErr = const PostgrestException(
        message: 'relation "profiles" does not exist',
        code: '42P01',
        details: 'table profiles not found in pg_catalog',
      );
      final msg = AuthErrorHandler.handle(postgrestErr);
      expect(msg, 'Something went wrong. Please try again.');
      expect(msg.contains('relation'), isFalse);
      expect(msg.contains('42P01'), isFalse);
    });

    test('Handles PostgreSQL unique constraint 23505 as already registered', () {
      final duplicateErr = const PostgrestException(
        message: 'duplicate key value violates unique constraint "profiles_email_key"',
        code: '23505',
        details: 'Key (email)=(test@buylanka.lk) already exists.',
      );
      final msg = AuthErrorHandler.handle(duplicateErr);
      expect(msg, 'This email is already registered. Please sign in.');
    });
  });

  group('AuthController Integration with AuthErrorHandler', () {
    test('signUpCustomer with registered email sets friendly error', () async {
      final mockRepo = MockFailingAuthRepository(
        const AuthException(
          'User already registered',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );
      final controller = AuthController(mockRepo, FakeRiderRepository());

      final success = await controller.signUpCustomer(
        fullName: 'Test User',
        email: 'existing@buylanka.lk',
        password: 'Password123!',
      );

      expect(success, isFalse);
      expect(controller.state.errorMessage, 'This email is already registered. Please sign in.');
    });

    test('signInCustomer with incorrect credentials sets friendly error', () async {
      final mockRepo = MockFailingAuthRepository(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      final controller = AuthController(mockRepo, FakeRiderRepository());

      final success = await controller.signInCustomer(
        email: 'user@buylanka.lk',
        password: 'WrongPassword',
      );

      expect(success, isFalse);
      expect(controller.state.errorMessage, 'Incorrect email or password. Please try again.');
    });

    test('signInSeller with network failure sets friendly error', () async {
      final mockRepo = MockFailingAuthRepository(
        const SocketException('Failed host lookup'),
      );
      final controller = AuthController(mockRepo, FakeRiderRepository());

      final success = await controller.signInSeller(
        email: 'seller@buylanka.lk',
        password: 'Password123!',
      );

      expect(success, isFalse);
      expect(controller.state.errorMessage, 'Unable to connect. Please check your internet connection.');
    });

    test('clearError resets the error state', () {
      final mockRepo = MockFailingAuthRepository(const AuthException('Error', code: 'test'));
      final controller = AuthController(mockRepo, FakeRiderRepository());

      controller.state = controller.state.copyWith(errorMessage: 'Some error');
      expect(controller.state.errorMessage, 'Some error');

      controller.clearError();
      expect(controller.state.errorMessage, isNull);
    });
  });

  group('UI Friendly Error Component & Banner Tests', () {
    testWidgets('AuthFeedbackBanner renders soft red background, red icon, and close button', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFeedbackBanner.error(
              message: 'This email is already registered. Please sign in.',
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('This email is already registered. Please sign in.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('CustomerAuthScreen displays AuthFeedbackBanner when errorMessage is present and dismisses on close', (tester) async {
      final mockRepo = MockFailingAuthRepository(
        const AuthException('Invalid login credentials', code: 'invalid_credentials'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            riderRepositoryProvider.overrideWithValue(FakeRiderRepository()),
          ],
          child: const MaterialApp(
            home: CustomerAuthScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter login info and submit
      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@buylanka.lk');
      await tester.enterText(find.byType(TextFormField).at(1), 'badpassword');
      await tester.ensureVisible(find.text('Sign In as Customer'));
      await tester.tap(find.text('Sign In as Customer'));
      await tester.pumpAndSettle();

      // Friendly error banner should be displayed
      expect(find.text('Incorrect email or password. Please try again.'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Close the error banner
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password. Please try again.'), findsNothing);
    });

    testWidgets('SellerLoginScreen displays friendly error and close button on auth failure', (tester) async {
      final mockRepo = MockFailingAuthRepository(
        const SocketException('Failed host lookup'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            riderRepositoryProvider.overrideWithValue(FakeRiderRepository()),
          ],
          child: const MaterialApp(
            home: SellerLoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter login info and submit
      await tester.enterText(find.byType(TextFormField).at(0), 'seller@buylanka.lk');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
      await tester.ensureVisible(find.text('Sign In as Restaurant →'));
      await tester.tap(find.text('Sign In as Restaurant →'));
      await tester.pumpAndSettle();

      // Should display friendly network error
      expect(find.text('Unable to connect. Please check your internet connection.'), findsAtLeastNWidgets(1));
    });
  });
}
