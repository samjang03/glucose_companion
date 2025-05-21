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
import 'package:glucose_companion/core/ml/glucose_predictor.dart';
import 'package:glucose_companion/data/repositories/prediction_repository_impl.dart';
import 'package:glucose_companion/domain/repositories/prediction_repository.dart';
import 'package:glucose_companion/presentation/bloc/prediction/prediction_bloc.dart';
import 'package:glucose_companion/services/mock_data_service.dart';
import 'package:glucose_companion/data/repositories/alert_repository_impl.dart';
import 'package:glucose_companion/domain/repositories/alert_repository.dart';
import 'package:glucose_companion/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:glucose_companion/services/alert_service.dart';

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
  sl.registerLazySingleton(() => MockDataService());
  sl.registerLazySingleton(() => AlertService(sl()));

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
  sl.registerLazySingleton<AlertRepository>(() => AlertRepositoryImpl(sl()));

  // ML-компоненти
  sl.registerLazySingleton(() => GlucosePredictor());

  // Репозиторії
  sl.registerLazySingleton<PredictionRepository>(
    () => PredictionRepositoryImpl(sl(), sl()),
  );

  // BLoCs
  sl.registerFactory(
    () => HomeBloc(
      sl<DexcomRepository>(),
      sl<InsulinRepository>(),
      sl<CarbRepository>(),
      sl<ActivityRepository>(),
      sl<AlertService>(),
      sl<SettingsBloc>(),
    ),
  );
  sl.registerFactory(() => SettingsBloc(sl()));
  sl.registerFactory(
    () => PredictionBloc(
      sl<DexcomRepository>(),
      sl<AlertService>(),
      sl<SettingsBloc>(),
    ),
  );
  sl.registerFactory(() => AlertsBloc(sl<AlertRepository>()));

  // Initialize services
  await sl<SecureStorage>().init();
  await sl<SessionManager>().init();
}
