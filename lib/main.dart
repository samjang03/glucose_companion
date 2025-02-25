import 'package:flutter/material.dart';
import 'package:glucose_companion/core/di/injection_container.dart' as di;
import 'package:glucose_companion/core/theme/app_theme.dart';
import 'package:glucose_companion/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucose Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const LoginPage(),
    );
  }
}
