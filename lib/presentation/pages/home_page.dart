import 'package:flutter/material.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/core/security/session_manager.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repository = sl<DexcomRepository>();
  final _sessionManager = sl<SessionManager>();

  @override
  void initState() {
    super.initState();
    // Встановлюємо обробник закінчення сесії
    _sessionManager.onSessionExpired = _handleSessionExpired;
  }

  void _handleSessionExpired() {
    // Переходимо на сторінку входу, якщо сесія закінчилась
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please login again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _logout() async {
    await _sessionManager.logout();

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Companion'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(child: Text('Home Page - Coming Soon')),
    );
  }
}
