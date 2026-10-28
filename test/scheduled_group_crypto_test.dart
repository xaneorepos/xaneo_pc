import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/services/crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'scheduled group ciphertext including empty captions stays compatible',
    () async {
      final service = CryptoService();
      final key = '11' * 32;
      for (final text in ['Scheduled group text', '']) {
        final encrypted = await service.encryptGroupMessage(text, key);
        expect(await service.decryptGroupMessage(encrypted, key), text);
      }
    },
  );
  test(
    'web/mobile XChaCha scheduled attachment-only ciphertext decrypts',
    () async {
      final service = CryptoService();
      final bytes = Uint8List.fromList(List.filled(32, 0x11));
      final box = await crypto.Xchacha20.poly1305Aead().encrypt(
        [],
        secretKey: crypto.SecretKey(bytes),
      );
      final encrypted = base64Encode([
        ...box.nonce,
        ...box.cipherText,
        ...box.mac.bytes,
      ]);
      expect(await service.decryptGroupMessage(encrypted, '11' * 32), '');
    },
  );
}
