import 'package:flutter/material.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/presentation/screens/auth/auth_screen.dart';
import 'package:photoshrink/presentation/screens/compression/compression_screen.dart';
import 'package:photoshrink/presentation/screens/extract/extract_screen.dart';
import 'package:photoshrink/presentation/screens/home/home_screen.dart';
import 'package:photoshrink/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:photoshrink/presentation/screens/preview/preview_screen.dart';
import 'package:photoshrink/presentation/screens/settings/settings_screen.dart';
import 'package:photoshrink/presentation/screens/splash/splash_screen.dart';
import 'package:photoshrink/presentation/screens/subscription/subscription_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteConstants.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case RouteConstants.auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case RouteConstants.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteConstants.compression:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CompressionScreen(
            imagePaths: args?['imagePaths'] as List<String>? ?? [],
            quality: args?['quality'] as int? ?? 100,
          ),
        );
      case RouteConstants.preview:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PreviewScreen(
            originalPath: args?['originalPath'] as String? ?? '',
            compressedPath: args?['compressedPath'] as String? ?? '',
            originalSize: args?['originalSize'] as int? ?? 0,
            compressedSize: args?['compressedSize'] as int? ?? 0,
          ),
        );
      case RouteConstants.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteConstants.subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
      case RouteConstants.extract:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ExtractScreen(
            archivePath: args?['archivePath'] as String? ?? '',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}