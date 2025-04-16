import 'package:get_it/get_it.dart';
import 'package:photoshrink/services/analytics/analytics_service.dart';
import 'package:photoshrink/services/auth/auth_service.dart';
import 'package:photoshrink/services/compression/compression_service.dart';
import 'package:photoshrink/services/purchase/purchase_service.dart';
import 'package:photoshrink/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

Future<void> initDependencies() async {
  // External services
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  
  // App services
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsServiceImpl());
  getIt.registerLazySingleton<AuthService>(() => AuthServiceImpl());
  getIt.registerLazySingleton<CompressionService>(() => CompressionServiceImpl());
  getIt.registerLazySingleton<StorageService>(() => StorageServiceImpl(sharedPreferences));
  getIt.registerLazySingleton<PurchaseService>(() => PurchaseServiceImpl());
  
  // Repositories will be registered here
  
  // BLoCs will be registered here
}