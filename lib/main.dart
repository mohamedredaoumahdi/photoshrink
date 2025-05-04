import 'dart:async';
import 'dart:io';
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
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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

class PhotoShrinkApp extends StatefulWidget {
  const PhotoShrinkApp({Key? key}) : super(key: key);

  @override
  State<PhotoShrinkApp> createState() => _PhotoShrinkAppState();
}

class _PhotoShrinkAppState extends State<PhotoShrinkApp> {
  String? _initialRoute;
  Map<String, dynamic>? _initialRouteArgs;
  StreamSubscription? _intentDataStreamSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen for incoming shared files
    _setupSharingListener();
  }
  
  void _setupSharingListener() {
    // For shared files coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    }, onError: (err) {
      print("Error receiving shared files: $err");
    });

    // For shared files coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });
  }
  
  void _handleSharedFiles(List<SharedMediaFile> sharedFiles) {
    for (final file in sharedFiles) {
      final path = file.path;
      if (path.toLowerCase().endsWith(AppConstants.archiveExtension)) {
        setState(() {
          _initialRoute = RouteConstants.extract;
          _initialRouteArgs = {'archivePath': path};
        });
        break;
      }
    }
  }

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
          initialRoute: _initialRoute ?? RouteConstants.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: (String initialRouteName) {
            if (initialRouteName == RouteConstants.extract && _initialRouteArgs != null) {
              return [
                AppRouter.onGenerateRoute(
                  const RouteSettings(name: RouteConstants.splash),
                ),
                AppRouter.onGenerateRoute(
                  RouteSettings(
                    name: RouteConstants.extract,
                    arguments: _initialRouteArgs,
                  ),
                ),
              ];
            } else {
              return [
                AppRouter.onGenerateRoute(
                  RouteSettings(name: initialRouteName),
                ),
              ];
            }
          },
        );
      },
    );
  }
  
  @override
  void dispose() {
    // Clean up any listeners
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }
}