import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static enc.Key _deriveKey(int consultationId) {
    final raw = 'gara-enc-$consultationId-2024';
    final padded = raw.padRight(32, 'X');
    return enc.Key.fromUtf8(padded.substring(0, 32));
  }

  static String encrypt(String plainText, int consultationId) {
    if (plainText.isEmpty) return plainText;
    final key = _deriveKey(consultationId);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${encrypted.base64}:${iv.base64}';
  }

  static String decrypt(String cipherText, int consultationId) {
    if (cipherText.isEmpty || !cipherText.contains(':')) return cipherText;
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return cipherText;
      final key = _deriveKey(consultationId);
      final iv = enc.IV.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[0], iv: iv);
    } catch (_) {
      return cipherText;
    }
  }
}
