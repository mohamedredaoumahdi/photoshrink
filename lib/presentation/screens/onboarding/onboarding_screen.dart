import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/core/theme/app_theme.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StorageService storageService = getIt<StorageService>();

    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Welcome to ${AppConstants.appName}",
            body: "The easiest way to compress your images without losing quality.",
            image: Center(
              child: Lottie.asset(
                'assets/animations/welcome_animation.json',
                width: 300,
                height: 300,
              ),
            ),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              bodyTextStyle: TextStyle(fontSize: 18.0),
              bodyPadding: EdgeInsets.all(16.0),
            ),
          ),
          PageViewModel(
            title: "Compress Multiple Images",
            body: "Select and compress multiple images at once with just a few taps.",
            image: Center(
              child: Lottie.asset(
                'assets/animations/batch_animation.json',
                width: 300,
                height: 300,
              ),
            ),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              bodyTextStyle: TextStyle(fontSize: 18.0),
              bodyPadding: EdgeInsets.all(16.0),
            ),
          ),
          PageViewModel(
            title: "Adjust Compression Level",
            body: "Fine-tune the compression level to achieve the perfect balance between size and quality.",
            image: Center(
              child: Lottie.asset(
                'assets/animations/quality_animation.json',
                width: 300,
                height: 300,
              ),
            ),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              bodyTextStyle: TextStyle(fontSize: 18.0),
              bodyPadding: EdgeInsets.all(16.0),
            ),
          ),
          PageViewModel(
            title: "Share Instantly",
            body: "Share your compressed images via email or social media with a single tap.",
            image: Center(
              child: Lottie.asset(
                'assets/animations/share_animation.json',
                width: 300,
                height: 300,
              ),
            ),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              bodyTextStyle: TextStyle(fontSize: 18.0),
              bodyPadding: EdgeInsets.all(16.0),
            ),
          ),
        ],
        showSkipButton: true,
        skip: const Text("Skip"),
        next: const Text("Next"),
        done: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.w700)),
        onDone: () async {
          // Set onboarding as completed
          await storageService.setOnboardingCompleted(true);
          
          // Navigate to the auth screen if authentication is enabled, otherwise to the home screen
          if (AppConstants.enableUserAuthentication) {
            Navigator.of(context).pushReplacementNamed(RouteConstants.auth);
          } else {
            Navigator.of(context).pushReplacementNamed(RouteConstants.home);
          }
        },
        onSkip: () async {
          // Set onboarding as completed
          await storageService.setOnboardingCompleted(true);
          
          // Navigate to the auth screen if authentication is enabled, otherwise to the home screen
          if (AppConstants.enableUserAuthentication) {
            Navigator.of(context).pushReplacementNamed(RouteConstants.auth);
          } else {
            Navigator.of(context).pushReplacementNamed(RouteConstants.home);
          }
        },
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          activeColor: AppTheme.primaryColor,
          color: Colors.grey,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
  }
}