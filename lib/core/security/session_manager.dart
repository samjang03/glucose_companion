import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:glucose_companion/core/security/secure_storage.dart';

class SessionManager {
  final SecureStorage _secureStorage;

  // Ключі для зберігання
  static const _keySessionToken = 'session_token';
  static const _keyTokenExpiry = 'token_expiry';
  static const _keyUsername = 'dexcom_username';
  static const _keyPassword = 'dexcom_password';

  // Налаштування сесії
  static const sessionExpiryDuration = Duration(hours: 24);
  static const sessionRefreshThreshold = Duration(minutes: 30);

  // Стан сесії
  bool _isAuthenticated = false;
  String? _sessionToken;
  DateTime? _tokenExpiry;
  Timer? _sessionCheckTimer;

  // Обробник закінчення сесії
  VoidCallback? onSessionExpired;

  SessionManager(this._secureStorage);

  bool get isAuthenticated => _isAuthenticated;

  // Ініціалізація з перевіркою збереженої сесії
  Future<void> init() async {
    final token = await _secureStorage.read(key: _keySessionToken);
    final expiryString = await _secureStorage.read(key: _keyTokenExpiry);

    if (token != null && expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (expiry.isAfter(DateTime.now())) {
        _sessionToken = token;
        _tokenExpiry = expiry;
        _isAuthenticated = true;
        _startSessionTimer();
      }
    }
  }

  // Зберігаємо дані для автентифікації
  Future<void> saveCredentials(String username, String password) async {
    await _secureStorage.write(key: _keyUsername, value: username);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  // Отримуємо збережені дані
  Future<Map<String, String?>> getCredentials() async {
    return {
      'username': await _secureStorage.read(key: _keyUsername),
      'password': await _secureStorage.read(key: _keyPassword),
    };
  }

  // Зберігаємо сесійний токен
  Future<void> saveSession(String token) async {
    _sessionToken = token;
    _tokenExpiry = DateTime.now().add(sessionExpiryDuration);
    _isAuthenticated = true;

    await _secureStorage.write(key: _keySessionToken, value: token);
    await _secureStorage.write(
      key: _keyTokenExpiry,
      value: _tokenExpiry!.toIso8601String(),
    );

    _startSessionTimer();
  }

  // Отримуємо активний токен
  Future<String?> getActiveToken() async {
    if (_tokenExpiry == null ||
        _sessionToken == null ||
        DateTime.now().isAfter(
          _tokenExpiry!.subtract(sessionRefreshThreshold),
        )) {
      // Токен старий або відсутній, потрібно оновити
      return null;
    }
    return _sessionToken;
  }

  // Виходимо із сесії
  Future<void> logout() async {
    _sessionToken = null;
    _tokenExpiry = null;
    _isAuthenticated = false;
    _sessionCheckTimer?.cancel();

    await _secureStorage.delete(key: _keySessionToken);
    await _secureStorage.delete(key: _keyTokenExpiry);
  }

  // Таймер для перевірки сесії
  void _startSessionTimer() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkSession();
    });
  }

  // Перевірка стану сесії
  void _checkSession() {
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      _isAuthenticated = false;
      if (onSessionExpired != null) {
        onSessionExpired!();
      }
    }
  }
}
