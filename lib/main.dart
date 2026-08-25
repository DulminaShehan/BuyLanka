import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_constants.dart';
import 'package:buylanka/core/theme/app_theme.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/customer_auth_screen.dart';
import 'package:buylanka/features/customer/presentation/customer_main_nav_screen.dart';
import 'package:buylanka/features/rider/presentation/rider_main_nav_screen.dart';
import 'package:buylanka/features/seller/presentation/seller_main_nav_screen.dart';
import 'package:buylanka/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Dotenv notice (using default fallback credentials if unavailable): $e');
  }

  // Initialize Supabase client
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(
    const ProviderScope(
      child: BuyLankaApp(),
    ),
  );
}

class BuyLankaApp extends ConsumerWidget {
  const BuyLankaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : authState.isAuthenticated
              ? (authState.isCustomer
                  ? const CustomerMainNavScreen()
                  : (authState.isRider
                      ? const RiderMainNavScreen()
                      : const SellerMainNavScreen()))
              : const CustomerAuthScreen(),
    );
  }
}
