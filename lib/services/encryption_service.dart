import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // TODO: In production, this key should be stored securely (e.g. FlutterSecureStorage) or derived from user input.
  // For this MVP/Demo, we use a constant key.
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1'); 
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static String encryptData(String plainText) {
    if (plainText.isEmpty) return '';
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptData(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    try {
      final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      return 'Error decrypting';
    }
  }
}
