import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:glucose_companion/core/security/secure_storage.dart';
import 'package:glucose_companion/core/security/session_manager.dart';
import 'package:glucose_companion/data/datasources/dexcom_api_client.dart';
import 'package:glucose_companion/data/repositories/dexcom_repository_impl.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Core
  sl.registerLazySingleton(() => SecureStorage(sl()));
  sl.registerLazySingleton(() => SessionManager(sl()));

  // Data sources
  sl.registerLazySingleton(
    () => DexcomApiClient(
      dio: sl(),
      sessionManager: sl(),
      region: DexcomRegion.ous,
    ),
  );

  // Repositories
  sl.registerLazySingleton<DexcomRepository>(() => DexcomRepositoryImpl(sl()));

  // Initialize services
  await sl<SecureStorage>().init();
  await sl<SessionManager>().init();
}
