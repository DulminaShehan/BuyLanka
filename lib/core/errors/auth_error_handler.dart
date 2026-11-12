import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authErrorHandlerProvider = Provider<AuthErrorHandler>((ref) {
  return AuthErrorHandler();
});

/// Centralized service to sanitize, log, and translate raw Supabase / network
/// authentication exceptions into friendly, customer-ready messages.
class AuthErrorHandler {
  // Standard Friendly Messages
  static const String userAlreadyExists = 'This email is already registered. Please sign in.';
  static const String invalidCredentials = 'Incorrect email or password. Please try again.';
  static const String weakPassword = 'Your password is too weak. Please choose a stronger password.';
  static const String emailNotConfirmed = 'Please verify your email before signing in.';
  static const String networkError = 'Unable to connect. Please check your internet connection.';
  static const String tooManyRequests = 'Too many attempts. Please try again later.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String unknownError = 'Something went wrong. Please try again.';

  // Domain & Role Status Messages
  static const String pendingSellerApproval =
      'Your Restaurant partner account is currently pending approval. Please wait for operations verification.';
  static const String pendingRiderApproval =
      'Your Delivery Rider application is currently pending approval. Operations will verify your vehicle & license.';
  static const String suspendedAccount =
      'Your account has been suspended. Please contact BuyLanka support (operations@buylanka.lk).';
  static const String partnerAccessDenied =
      'Access Denied: This portal is for verified Restaurant and Rider partners only. Customers, please sign in from the main app.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';

  /// Translates any caught exception into a friendly, professional UI message.
  /// Also logs the full sanitized technical stack in developer logs only.
  static String handle(dynamic error, {StackTrace? stackTrace, String? context}) {
    // 1. Log technical details safely for developers
    logError(error, stackTrace: stackTrace, context: context);

    if (error == null) {
      return unknownError;
    }

    // 2. Handle Network / Socket / Timeout exceptions
    if (_isNetworkError(error)) {
      return networkError;
    }

    // 3. Handle Supabase AuthException / AuthApiException
    if (error is AuthException) {
      return _mapAuthException(error);
    }

    // 4. Handle PostgreSQL database exceptions (e.g., unique violations)
    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }

    // 5. Handle String errors or custom exceptions
    return _mapGenericError(error);
  }

  /// Maps Supabase GoTrue AuthException and AuthApiException instances
  static String _mapAuthException(AuthException error) {
    final code = error.code?.toLowerCase().trim() ?? '';
    final message = error.message.toLowerCase().trim();
    final statusCode = error.statusCode?.toString().trim() ?? '';

    // A. User already registered / exists
    if (code == 'user_already_exists' ||
        message.contains('user already registered') ||
        message.contains('user already exists') ||
        message.contains('already registered') ||
        message.contains('email already exists') ||
        (statusCode == '422' && (message.contains('already') || code.contains('exists')))) {
      return userAlreadyExists;
    }

    // B. Invalid login credentials
    if (code == 'invalid_credentials' ||
        code == 'invalid_grant' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('invalid email or password') ||
        message.contains('invalid grant') ||
        message.contains('wrong password') ||
        (statusCode == '400' && message.contains('credentials'))) {
      return invalidCredentials;
    }

    // C. Weak password
    if (code == 'weak_password' ||
        message.contains('weak password') ||
        message.contains('password should be at least') ||
        message.contains('password must be at least') ||
        message.contains('password is too weak')) {
      return weakPassword;
    }

    // D. Email not confirmed / verified
    if (code == 'email_not_confirmed' ||
        code == 'email_not_verified' ||
        message.contains('email not confirmed') ||
        message.contains('email not verified') ||
        message.contains('confirm your email') ||
        message.contains('verify your email')) {
      return emailNotConfirmed;
    }

    // E. Rate limit / Too many requests
    if (code == 'too_many_requests' ||
        code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit' ||
        statusCode == '429' ||
        message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('try again later') ||
        message.contains('for security purposes, you can only request')) {
      return tooManyRequests;
    }

    // F. Invalid email format
    if (code == 'invalid_email' ||
        code == 'validation_failed' && message.contains('email') ||
        message.contains('invalid email') ||
        message.contains('validate email address') ||
        message.contains('email format')) {
      return invalidEmail;
    }

    // G. Sign-up disabled
    if (code == 'signup_disabled' || message.contains('signup disabled')) {
      return 'Account registration is temporarily disabled. Please contact support.';
    }

    // H. User banned / suspended
    if (code == 'user_banned' || message.contains('banned') || message.contains('suspended')) {
      return suspendedAccount;
    }

    // I. Session expired
    if (code == 'session_expired' ||
        code == 'bad_jwt' ||
        message.contains('jwt expired') ||
        message.contains('token is expired')) {
      return sessionExpired;
    }

    // J. User not found
    if (code == 'user_not_found' || message.contains('user not found')) {
      return 'No account found with this email. Please check your email or register.';
    }

    // K. Existing friendly domain messages passed in AuthException
    final domainCheck = _checkDomainFriendlyMessage(error.message);
    if (domainCheck != null) {
      return domainCheck;
    }

    // Fallback: Never expose raw message if it has technical signatures
    if (_containsTechnicalSignatures(error.message)) {
      return unknownError;
    }

    return error.message.isNotEmpty ? error.message : unknownError;
  }

  /// Maps PostgreSQL / PostgrestException errors
  static String _mapPostgrestException(PostgrestException error) {
    final code = error.code?.trim() ?? '';
    final message = error.message.toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';

    // PostgreSQL 23505 = Unique violation
    if (code == '23505' || message.contains('unique constraint') || details.contains('already exists')) {
      if (message.contains('email') || details.contains('email')) {
        return userAlreadyExists;
      }
      if (message.contains('phone') || details.contains('phone')) {
        return 'This phone number is already registered with another account.';
      }
      return 'This information is already registered. Please sign in.';
    }

    // PostgreSQL 42501 = Insufficient privilege / RLS error
    if (code == '42501' || message.contains('row-level security') || message.contains('permission denied')) {
      return 'Access denied. Please check your account permissions.';
    }

    return unknownError;
  }

  /// Maps generic Exceptions, Error objects or Strings
  static String _mapGenericError(dynamic error) {
    final rawText = error.toString();
    final lowerText = rawText.toLowerCase();

    // Check network keywords in string
    if (_isNetworkText(lowerText)) {
      return networkError;
    }

    // Check user already exists keywords
    if (lowerText.contains('already registered') || lowerText.contains('user_already_exists')) {
      return userAlreadyExists;
    }

    // Check invalid credentials
    if (lowerText.contains('invalid login credentials') || lowerText.contains('invalid_credentials')) {
      return invalidCredentials;
    }

    // Check rate limit
    if (lowerText.contains('rate limit') || lowerText.contains('too many requests')) {
      return tooManyRequests;
    }

    // Check domain message
    final domainCheck = _checkDomainFriendlyMessage(rawText);
    if (domainCheck != null) {
      return domainCheck;
    }

    // If string has technical tokens or stack traces, hide them
    if (_containsTechnicalSignatures(rawText)) {
      return unknownError;
    }

    // Clean up generic 'Exception: ' prefix if clean message
    final cleaned = rawText.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    return cleaned.isNotEmpty ? cleaned : unknownError;
  }

  /// Checks if the message is a recognized BuyLanka domain message
  static String? _checkDomainFriendlyMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('access denied') && lower.contains('portal is for')) {
      return partnerAccessDenied;
    }
    if (lower.contains('pending super admin approval') || lower.contains('pending approval')) {
      if (lower.contains('rider')) {
        return pendingRiderApproval;
      }
      return pendingSellerApproval;
    }
    if (lower.contains('suspended') || lower.contains('rejected')) {
      return suspendedAccount;
    }
    if (lower.contains('registration complete')) {
      return 'Registration complete! Please sign in with your email and password.';
    }

    return null;
  }

  /// Detects if an exception represents a network or connectivity issue
  static bool _isNetworkError(dynamic error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return true;
    }

    final str = error.toString().toLowerCase();
    return _isNetworkText(str);
  }

  static bool _isNetworkText(String text) {
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('network_error') ||
        text.contains('connection refused') ||
        text.contains('connection timed out') ||
        text.contains('connection closed') ||
        text.contains('connection reset') ||
        text.contains('handshake failed') ||
        text.contains('clientexception') ||
        text.contains('os error') ||
        text.contains('no internet') ||
        text.contains('networkerror');
  }

  /// Detects raw technical keywords that should never be shown in user UI
  static bool _containsTechnicalSignatures(String text) {
    return text.contains('AuthApiException') ||
        text.contains('AuthException') ||
        text.contains('PostgrestException') ||
        text.contains('statusCode:') ||
        text.contains('statusCode =') ||
        text.contains('code:') ||
        text.contains('code =') ||
        text.contains('StackTrace') ||
        text.contains('SELECT ') ||
        text.contains('INSERT ') ||
        text.contains('UPDATE ') ||
        text.contains('DELETE ') ||
        text.contains('table') && text.contains('does not exist') ||
        text.contains('pg_catalog') ||
        text.contains('null_check_operator');
  }

  /// Logs technical error details strictly to developer console.
  /// Automatically redacts sensitive information such as passwords, access tokens,
  /// secrets, or API keys.
  static void logError(dynamic error, {StackTrace? stackTrace, String? context}) {
    if (kDebugMode) {
      final safeContext = context != null ? '[$context] ' : '';
      final safeError = _sanitizeSensitiveData(error.toString());
      debugPrint('[BuyLanka Auth] $safeContext$safeError');

      if (stackTrace != null) {
        debugPrint('[BuyLanka Auth Stack] $stackTrace');
      }
    }
  }

  /// Redacts passwords, bearer tokens, and credentials from log output
  static String _sanitizeSensitiveData(String input) {
    var sanitized = input;

    // Redact password occurrences (e.g. password: 'xyz' or password=xyz)
    sanitized = sanitized.replaceAll(
      RegExp(r'(password|pass|secret|token|apikey|api_key|jwt|access_token)\s*[:=]\s*[^\s,}\]]+', caseSensitive: false),
      r'$1=[REDACTED]',
    );

    // Redact email addresses from raw logs if desired for privacy
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b'),
      '***@***.***',
    );

    return sanitized;
  }
}

