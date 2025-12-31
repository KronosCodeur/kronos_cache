import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CacheEncryption {
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  CacheEncryption(String key) {
    final keyBytes = sha256.convert(utf8.encode(key)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));

    final ivBytes = md5.convert(utf8.encode(key)).bytes;
    _iv = encrypt.IV(Uint8List.fromList(ivBytes));

    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String encryptString(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptString(String encryptedText) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  String encryptMap(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    return encryptString(json);
  }

  Map<String, dynamic> decryptMap(String encryptedText) {
    final json = decryptString(encryptedText);
    return jsonDecode(json) as Map<String, dynamic>;
  }

  String hashKey(String key) {
    final bytes = utf8.encode(key);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}