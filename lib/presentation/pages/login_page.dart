import 'package:flutter/material.dart';
import 'package:glucose_companion/core/di/injection_container.dart';
import 'package:glucose_companion/core/errors/exceptions.dart';
import 'package:glucose_companion/data/datasources/local/database_helper.dart';
import 'package:glucose_companion/data/repositories/dexcom_repository_impl.dart';
import 'package:glucose_companion/domain/repositories/dexcom_repository.dart';
import 'package:glucose_companion/presentation/bloc/home/home_bloc.dart';
import 'package:glucose_companion/presentation/bloc/home/home_event.dart';
import 'package:glucose_companion/presentation/pages/home_page.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _repository = sl<DexcomRepository>();
  final _homeBloc = sl<HomeBloc>();
  final _databaseHelper = sl<DatabaseHelper>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both username and password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repository.authenticate(
        _usernameController.text,
        _passwordController.text,
      );

      final reading = await _repository.getCurrentGlucoseReading();

      if (!mounted) return;

      // Створюємо або отримуємо користувача
      final userId = await _createOrGetUser(_usernameController.text);

      // Встановлюємо ID користувача для HomeBloc
      _homeBloc.add(SetUserIdEvent(userId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Success! Current glucose: ${reading.mmolL.toStringAsFixed(1)} mmol/L',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Переходимо на головну сторінку після успішної автентифікації
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } on AuthenticationException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _createOrGetUser(String email) async {
    try {
      final db = await _databaseHelper.database;

      // Перевіряємо, чи існує користувач з таким email
      final List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (users.isNotEmpty) {
        // Користувач знайдений, повертаємо його ID
        return users.first['user_id'] as String;
      } else {
        // Створюємо нового користувача
        final userId = const Uuid().v4();
        final now = DateTime.now().toIso8601String();

        await db.insert('users', {
          'user_id': userId,
          'email': email,
          'created_at': now,
          'updated_at': now,
        });

        return userId;
      }
    } catch (e) {
      print('Error creating/getting user: $e');
      // У випадку помилки генеруємо та повертаємо тимчасовий ID
      return 'temp_user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Dexcom'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your Dexcom username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your Dexcom password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
