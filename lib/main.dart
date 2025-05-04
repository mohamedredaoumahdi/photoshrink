import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photoshrink/app_wrapper.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/debug_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/core/theme/app_theme.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/app_bloc_observer.dart';
import 'package:photoshrink/presentation/routes/app_router.dart';
import 'package:photoshrink/firebase_options.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

const String APP_TAG = 'PhotoShrinkApp';

void main() async {
  LoggerUtil.i(APP_TAG, '🚀 Application starting...');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with options
  LoggerUtil.d(APP_TAG, 'Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggerUtil.i(APP_TAG, 'Firebase initialized successfully');
  } catch (e) {
    LoggerUtil.e(APP_TAG, 'Error initializing Firebase: $e');
  }
  
  // Set preferred orientations
  LoggerUtil.d(APP_TAG, 'Setting preferred orientations');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize dependencies
  LoggerUtil.d(APP_TAG, 'Initializing dependencies');
  await initDependencies();
  LoggerUtil.i(APP_TAG, 'Dependencies initialized successfully');
  
  // Set up BLoC observer for debugging
  LoggerUtil.d(APP_TAG, 'Setting up BLoC observer');
  Bloc.observer = AppBlocObserver();
  
  LoggerUtil.i(APP_TAG, '✨ Application ready to run');
  
  // When in debug mode, run with the AppWrapper for debugging features
  if (kDebugMode) {
    LoggerUtil.i(APP_TAG, 'Running in debug mode with AppWrapper');
    runApp(const AppWrapper());
  } else {
    LoggerUtil.i(APP_TAG, 'Running in release mode');
    runApp(const PhotoShrinkApp());
  }
}

class PhotoShrinkApp extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  
  const PhotoShrinkApp({
    Key? key,
    this.navigatorKey,
  }) : super(key: key);

  @override
  State<PhotoShrinkApp> createState() => _PhotoShrinkAppState();
}

class _PhotoShrinkAppState extends State<PhotoShrinkApp> {
  static const String TAG = 'PhotoShrinkApp';
  
  String? _initialRoute;
  Map<String, dynamic>? _initialRouteArgs;
  StreamSubscription? _intentDataStreamSubscription;
  
  @override
  void initState() {
    super.initState();
    LoggerUtil.d(TAG, 'App widget initializing');
    
    // Listen for incoming shared files
    _setupSharingListener();
  }
  
  void _setupSharingListener() {
    LoggerUtil.d(TAG, 'Setting up sharing listener');
    
    // For shared files coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        LoggerUtil.i(TAG, 'Received shared files while app is running');
        _handleSharedFiles(value);
      }
    }, onError: (err) {
      LoggerUtil.e(TAG, "Error receiving shared files: $err");
    });

    // For shared files coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        LoggerUtil.i(TAG, 'Received shared files on app launch');
        _handleSharedFiles(value);
      }
    });
  }
  
  void _handleSharedFiles(List<SharedMediaFile> sharedFiles) {
    LoggerUtil.d(TAG, 'Handling ${sharedFiles.length} shared files');
    
    for (final file in sharedFiles) {
      final path = file.path;
      LoggerUtil.d(TAG, 'Checking shared file: ${LoggerUtil.truncatePath(path)}');
      
      if (path.toLowerCase().endsWith(AppConstants.archiveExtension)) {
        LoggerUtil.i(TAG, 'Found archive file: ${LoggerUtil.truncatePath(path)}');
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
    LoggerUtil.d(TAG, 'Building app with initialRoute: ${_initialRoute ?? RouteConstants.splash}');
    
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Design size based on iPhone X
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: widget.navigatorKey,
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: _initialRoute ?? RouteConstants.splash,
          onGenerateRoute: (settings) {
            LoggerUtil.d(TAG, 'Generating route for: ${settings.name}');
            return AppRouter.onGenerateRoute(settings);
          },
          onGenerateInitialRoutes: (String initialRouteName) {
            if (initialRouteName == RouteConstants.extract && _initialRouteArgs != null) {
              LoggerUtil.d(TAG, 'Generating initial routes for extract screen');
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
              LoggerUtil.d(TAG, 'Generating default initial route: $initialRouteName');
              return [
                AppRouter.onGenerateRoute(
                  RouteSettings(name: initialRouteName),
                ),
              ];
            }
          },
          navigatorObservers: [
            _NavigatorObserver(),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    LoggerUtil.d(TAG, 'Disposing app widget');
    // Clean up any listeners
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }
}

/// Custom navigator observer for logging navigation events
class _NavigatorObserver extends NavigatorObserver {
  static const String TAG = 'Navigator';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    LoggerUtil.d(TAG, 'didPush: ${_getRouteName(route)} from ${_getRouteName(previousRoute)}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    LoggerUtil.d(TAG, 'didPop: ${_getRouteName(route)} to ${_getRouteName(previousRoute)}');
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    LoggerUtil.d(TAG, 'didRemove: ${_getRouteName(route)}');
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    LoggerUtil.d(TAG, 'didReplace: ${_getRouteName(oldRoute)} with ${_getRouteName(newRoute)}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  String _getRouteName(Route<dynamic>? route) {
    return route?.settings.name ?? 'unknown';
  }
}