class AuthenticationException implements Exception {
  final String message;
  final String? code; // додали поле для коду помилки
  final String? details; // додали поле для деталей
  AuthenticationException(this.message, {this.code, this.details});

  @override
  String toString() {
    final buffer = StringBuffer('API Error: $message');
    if (code != null) buffer.write('\nCode: $code');
    if (details != null) buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  ApiException(this.message, {this.code, this.details});

  @override
  String toString() {
    final buffer = StringBuffer('API Error: $message');
    if (code != null) buffer.write('\nCode: $code');
    if (details != null) buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}
