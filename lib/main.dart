import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/presentation/seller_login_screen.dart';
import 'features/seller/presentation/seller_main_nav_screen.dart';
import 'services/supabase_service.dart';

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
      child: BuyLankaSellerApp(),
    ),
  );
}

class BuyLankaSellerApp extends ConsumerWidget {
  const BuyLankaSellerApp({super.key});

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
              ? const SellerMainNavScreen()
              : const SellerLoginScreen(),
    );
  }
}
