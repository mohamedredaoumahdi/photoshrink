import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/core/theme/app_theme.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/app_bloc_observer.dart';
import 'package:photoshrink/presentation/routes/app_router.dart';
import 'package:photoshrink/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize dependencies
  await initDependencies();
  
  // Set up BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  runApp(const PhotoShrinkApp());
}

class PhotoShrinkApp extends StatelessWidget {
  const PhotoShrinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Design size based on iPhone X
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: RouteConstants.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}