import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glucose_companion/core/di/injection_container.dart' as di;
import 'package:glucose_companion/core/theme/app_theme.dart';
import 'package:glucose_companion/data/models/user_settings.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_bloc.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_event.dart';
import 'package:glucose_companion/presentation/bloc/settings/settings_state.dart';
import 'package:glucose_companion/presentation/pages/login_page.dart';
import 'package:glucose_companion/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(create: (context) => di.sl<HomeBloc>()),
        BlocProvider<SettingsBloc>(
          create: (context) {
            final bloc = di.sl<SettingsBloc>();
            bloc.add(LoadSettingsEvent());
            return bloc;
          },
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // За замовчуванням використовуємо системну тему
          ThemeMode themeMode = ThemeMode.system;

          if (state is SettingsLoaded) {
            // Встановлюємо тему на основі налаштувань
            switch (state.settings.theme) {
              case 'light':
                themeMode = ThemeMode.light;
                break;
              case 'dark':
                themeMode = ThemeMode.dark;
                break;
              case 'system':
              default:
                themeMode = ThemeMode.system;
                break;
            }
          }

          return MaterialApp(
            title: 'Glucose Companion',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const LoginPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
