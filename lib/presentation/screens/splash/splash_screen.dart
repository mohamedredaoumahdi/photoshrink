import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_bloc.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_event.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_state.dart';
import 'package:photoshrink/services/storage/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final StorageService _storageService = getIt<StorageService>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });

    _animationController.forward();
  }

  Future<void> _navigateNext() async {
    final bool onboardingCompleted = await _storageService.isOnboardingCompleted();
    
    if (onboardingCompleted) {
      // Check auth status
      if (AppConstants.enableUserAuthentication) {
        context.read<AuthBloc>().add(AuthCheckRequested());
      } else {
        Navigator.of(context).pushReplacementNamed(RouteConstants.home);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(RouteConstants.onboarding);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacementNamed(RouteConstants.home);
        } else if (state is Unauthenticated && AppConstants.enableUserAuthentication) {
          Navigator.of(context).pushReplacementNamed(RouteConstants.auth);
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo animation
              Lottie.asset(
                'assets/animations/compress_animation.json',
                controller: _animationController,
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text('Compress your images in seconds'),
            ],
          ),
        ),
      ),
    );
  }
}