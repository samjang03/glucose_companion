import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:glucose_companion/core/security/secure_storage.dart';
import 'package:glucose_companion/core/security/session_manager.dart';
import 'package:glucose_companion/data/datasources/dexcom_api_client.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/repositories/activity_repository_impl.dart';
import 'package:glucose_companion/data/repositories/carb_repository_impl.dart';
import 'package:glucose_companion/data/repositories/dexcom_repository_impl.dart';
import 'package:glucose_companion/data/repositories/insulin_repository_impl.dart';
import 'package:glucose_companion/domain/repositories/activity_repository.dart';
import 'package:glucose_companion/domain/repositories/carb_repository.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/domain/repositories/glucose_reading_repository.dart';
import 'package:glucose_companion/domain/repositories/glucose_reading_repository_impl.dart';
import 'package:glucose_companion/domain/repositories/insulin_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/services/settings_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Core
  sl.registerLazySingleton(() => SecureStorage(sl()));
  sl.registerLazySingleton(() => SessionManager(sl()));
  sl.registerLazySingleton(() => DatabaseHelper());

  // Services
  sl.registerLazySingleton(() => SettingsService());

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
  sl.registerLazySingleton<GlucoseReadingRepository>(
    () => GlucoseReadingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<InsulinRepository>(
    () => InsulinRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CarbRepository>(() => CarbRepositoryImpl(sl()));
  sl.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(sl()),
  );

  // BLoCs
  sl.registerFactory(
    () => HomeBloc(
      sl<DexcomRepository>(),
      sl<InsulinRepository>(),
      sl<CarbRepository>(),
      sl<ActivityRepository>(),
    ),
  );
  sl.registerFactory(() => SettingsBloc(sl()));

  // Initialize services
  await sl<SecureStorage>().init();
  await sl<SessionManager>().init();
}
