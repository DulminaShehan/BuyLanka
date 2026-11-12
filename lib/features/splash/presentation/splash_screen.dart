import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buylanka/core/constants/app_colors.dart';

/// Official BuyLanka Splash Screen matching the branded mobile startup design.
///
/// Features:
/// - Branded background (#F5F9FF)
/// - Top & bottom subtle blue decorative wave elements
/// - Centered official BuyLanka logo, wordmark, and Sri Lankan tagline
/// - Minimal blue circular loading indicator
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Top decorative blue waves
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/splash_top_waves.png',
                  width: size.width,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Bottom decorative blue waves
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/splash_bottom_waves.png',
                  width: size.width,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Centered Brand Content & Loading Indicator
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // BuyLanka Brand Logo with Symbol, Wordmark & Tagline
                        Image.asset(
                          'assets/images/buylanka_logo.png',
                          width: 270,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),

                        const SizedBox(height: 48),

                        // Subtle Minimal Blue Circular Loading Indicator
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

