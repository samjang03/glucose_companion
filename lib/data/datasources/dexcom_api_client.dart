import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:glucose_companion/core/constants/api_constants.dart';
import 'package:glucose_companion/core/errors/exceptions.dart';
import 'package:glucose_companion/core/security/session_manager.dart';
import 'package:glucose_companion/data/models/glucose_reading.dart';

enum DexcomRegion { us, ous, jp }

class DexcomApiClient {
  final Dio _dio;
  final SessionManager _sessionManager;
  String? _sessionId;

  DexcomApiClient({
    required Dio dio,
    required SessionManager sessionManager,
    DexcomRegion region = DexcomRegion.us,
  }) : _dio = dio,
       _sessionManager = sessionManager {
    _dio.options.baseUrl =
        region == DexcomRegion.us
            ? ApiConstants.baseUrlUS
            : region == DexcomRegion.ous
            ? ApiConstants.baseUrlOUS
            : ApiConstants.baseUrlJP;
    _dio.options.contentType = 'application/json';
    _dio.options.validateStatus = (status) => true;

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
        logPrint: (object) {
          // Маскуємо чутливі дані в логах
          String logText = object.toString();
          if (logText.contains('password')) {
            logText = logText.replaceAllMapped(
              RegExp(r'"password"\s*:\s*"[^"]*"'),
              (match) => '"password":"****"',
            );
          }
          debugPrint(logText);
        },
      ),
    );
  }

  Future<void> authenticate(String username, String password) async {
    try {
      debugPrint('Starting authentication process...');

      // Зберігаємо облікові дані
      await _sessionManager.saveCredentials(username, password);

      // Перший запит - автентифікація
      final authResponse = await _dio.post(
        ApiConstants.authenticateEndpoint,
        data: {
          'accountName': username,
          'password': password,
          'applicationId': ApiConstants.applicationId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (authResponse.statusCode != 200 || authResponse.data == null) {
        if (authResponse.statusCode == 500 && authResponse.data is Map) {
          final errorData = authResponse.data as Map<String, dynamic>;
          throw AuthenticationException(
            errorData['Message'] ?? 'Authentication failed',
            code: errorData['Code']?.toString(),
            details: errorData['SubCode']?.toString(),
          );
        }
        throw AuthenticationException(
          'Authentication failed: Invalid response',
        );
      }

      final accountId = authResponse.data.toString();
      debugPrint('Received account ID: $accountId');

      // Другий запит - отримання sessionId
      final loginResponse = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'accountId': accountId,
          'password': password,
          'applicationId': ApiConstants.applicationId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (loginResponse.statusCode != 200 || loginResponse.data == null) {
        throw AuthenticationException('Login failed: Invalid response');
      }

      _sessionId = loginResponse.data.toString();

      // Зберігаємо сесію
      await _sessionManager.saveSession(_sessionId!);

      debugPrint('Session ID obtained: $_sessionId');
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw AuthenticationException(
          errorData['Message'] ?? 'Network error',
          code: errorData['Code']?.toString(),
          details: errorData['SubCode']?.toString(),
        );
      }
      throw AuthenticationException('Network error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      rethrow;
    }
  }

  // Решта методів оновлюємо для роботи з SecurityManager
  Future<GlucoseReading> getCurrentGlucoseReading() async {
    String? sessionId = await _getValidSessionId();
    if (sessionId == null) {
      throw AuthenticationException('Not authenticated');
    }

    try {
      final response = await _dio.post(
        ApiConstants.latestGlucoseEndpoint,
        queryParameters: {
          'sessionId': sessionId,
          'minutes': 1440,
          'maxCount': 1,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to get glucose reading',
          code: response.statusCode.toString(),
          details: response.data,
        );
      }

      if (response.data is! List || response.data.isEmpty) {
        throw ApiException('No glucose readings available');
      }

      try {
        return GlucoseReading.fromJson(response.data[0]);
      } catch (e) {
        throw ApiException(
          'Failed to parse glucose reading',
          details: e.toString(),
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        'Network error while getting glucose reading',
        details: e.message,
      );
    }
  }

  Future<List<GlucoseReading>> getGlucoseReadings({
    int minutes = 1440,
    int maxCount = 288,
  }) async {
    String? sessionId = await _getValidSessionId();
    if (sessionId == null) {
      throw AuthenticationException('Not authenticated');
    }

    try {
      final response = await _dio.post(
        ApiConstants.latestGlucoseEndpoint,
        queryParameters: {
          'sessionId': sessionId,
          'minutes': minutes,
          'maxCount': maxCount,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to get glucose readings',
          code: response.statusCode.toString(),
          details: response.data,
        );
      }

      if (response.data is! List) {
        throw ApiException('Invalid glucose readings format');
      }

      try {
        return (response.data as List)
            .map((reading) => GlucoseReading.fromJson(reading))
            .toList();
      } catch (e) {
        throw ApiException(
          'Failed to parse glucose readings',
          details: e.toString(),
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        'Network error while getting glucose readings',
        details: e.message,
      );
    }
  }

  // Отримання актуального сесійного ID
  Future<String?> _getValidSessionId() async {
    // Спочатку перевіряємо поточний sessionId
    if (_sessionId != null) return _sessionId;

    // Перевіряємо збережену сесію
    final token = await _sessionManager.getActiveToken();
    if (token != null) {
      _sessionId = token;
      return token;
    }

    // Якщо сесія недійсна, пробуємо автентифікуватись
    final credentials = await _sessionManager.getCredentials();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username != null && password != null) {
      try {
        await authenticate(username, password);
        return _sessionId;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
