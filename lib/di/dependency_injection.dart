import 'package:get_it/get_it.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_bloc.dart';
import 'package:photoshrink/presentation/bloc/compression/compression_bloc.dart';
import 'package:photoshrink/presentation/bloc/home/home_bloc.dart';
import 'package:photoshrink/presentation/bloc/settings/settings_bloc.dart';
import 'package:photoshrink/services/analytics/analytics_service.dart';
import 'package:photoshrink/services/auth/auth_service.dart';
import 'package:photoshrink/services/compression/compression_service.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;
const String TAG = 'DependencyInjection';

Future<void> initDependencies() async {
  LoggerUtil.i(TAG, 'Initializing dependencies');
  
  // Configure logger in debug mode
  if (true) { // Replace with appropriate condition for debug mode
    LoggerUtil.setLogLevel(LoggerUtil.VERBOSE);
    LoggerUtil.i(TAG, 'Logger set to VERBOSE level for debugging');
  }

  // External services
  LoggerUtil.d(TAG, 'Initializing shared preferences');
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  
  // App services
  LoggerUtil.d(TAG, 'Registering app services');
  
  getIt.registerLazySingleton<AnalyticsService>(() {
    LoggerUtil.d(TAG, 'Creating AnalyticsService');
    return AnalyticsServiceImpl();
  });
  
  getIt.registerLazySingleton<AuthService>(() {
    LoggerUtil.d(TAG, 'Creating AuthService');
    return AuthServiceImpl();
  });
  
  getIt.registerLazySingleton<CompressionService>(() {
    LoggerUtil.d(TAG, 'Creating CompressionService');
    return CompressionServiceImpl();
  });
  
  getIt.registerLazySingleton<StorageService>(() {
    LoggerUtil.d(TAG, 'Creating StorageService');
    return StorageServiceImpl(sharedPreferences);
  });
  
  getIt.registerLazySingleton<PurchaseService>(() {
    LoggerUtil.d(TAG, 'Creating PurchaseService');
    return PurchaseServiceImpl();
  });
  
  // BLoCs will be registered here
  LoggerUtil.d(TAG, 'Registering BLoCs');
  
  getIt.registerFactory<AuthBloc>(() {
    LoggerUtil.d(TAG, 'Creating AuthBloc');
    return AuthBloc(
      authService: getIt<AuthService>(),
    );
  });
  
  getIt.registerFactory<CompressionBloc>(() {
    LoggerUtil.d(TAG, 'Creating CompressionBloc');
    return CompressionBloc(
      compressionService: getIt<CompressionService>(),
      storageService: getIt<StorageService>(),
      analyticsService: getIt<AnalyticsService>(),
    );
  });
  
  getIt.registerFactory<HomeBloc>(() {
    LoggerUtil.d(TAG, 'Creating HomeBloc');
    return HomeBloc(
      storageService: getIt<StorageService>(),
      purchaseService: getIt<PurchaseService>(),
    );
  });
  
  getIt.registerFactory<SettingsBloc>(() {
    LoggerUtil.d(TAG, 'Creating SettingsBloc');
    return SettingsBloc(
      storageService: getIt<StorageService>(),
      purchaseService: getIt<PurchaseService>(),
    );
  });
  
  LoggerUtil.i(TAG, 'Dependencies initialized successfully');
}