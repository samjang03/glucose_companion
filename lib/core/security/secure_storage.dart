import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class SecureStorage {
  static const _keyEncryptionKey = 'glucose_companion_encryption_key';
  final FlutterSecureStorage _secureStorage;

  late final Key _encryptionKey;
  late final Encrypter _encrypter;
  final IV _iv = IV.fromLength(16);

  SecureStorage(this._secureStorage);

  Future<void> init() async {
    // Ініціалізація ключа шифрування
    String? storedKey = await _secureStorage.read(key: _keyEncryptionKey);

    if (storedKey == null) {
      // Створюємо новий ключ, якщо немає
      final key = Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _keyEncryptionKey,
        value: base64Encode(key.bytes),
      );
      _encryptionKey = key;
    } else {
      // Використовуємо існуючий ключ
      _encryptionKey = Key(base64Decode(storedKey));
    }

    _encrypter = Encrypter(AES(_encryptionKey));
  }

  // Зберігання з шифруванням
  Future<void> write({required String key, required String value}) async {
    final encrypted = _encrypter.encrypt(value, iv: _iv);
    await _secureStorage.write(key: key, value: encrypted.base64);
  }

  // Читання з дешифруванням
  Future<String?> read({required String key}) async {
    final encrypted = await _secureStorage.read(key: key);
    if (encrypted == null) return null;

    try {
      return _encrypter.decrypt64(encrypted, iv: _iv);
    } catch (e) {
      return null;
    }
  }

  // Видалення даних
  Future<void> delete({required String key}) async {
    await _secureStorage.delete(key: key);
  }

  // Очищення всіх даних при виході
  Future<void> clearAll() async {
    // Зберігаємо ключ шифрування
    final encryptionKey = await _secureStorage.read(key: _keyEncryptionKey);
    await _secureStorage.deleteAll();

    if (encryptionKey != null) {
      await _secureStorage.write(key: _keyEncryptionKey, value: encryptionKey);
    }
  }
}
