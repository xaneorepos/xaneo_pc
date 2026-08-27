import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/services/crypto_service.dart';

void main() {
  test('Test group message encryption and decryption', () async {
    final cryptoService = CryptoService();
    final testKeyHex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    final plaintext = "Привет из группы!";

    // 1. Encrypt with AES-GCM
    final encryptedAes = await cryptoService.encryptGroupMessage(plaintext, testKeyHex);
    final decryptedAes = await cryptoService.decryptGroupMessage(encryptedAes, testKeyHex);
    print("AES encrypted: $encryptedAes");
    print("AES decrypted: $decryptedAes");
    expect(decryptedAes, equals(plaintext));

    // 2. Encrypt with XChaCha20-Poly1305
    final xchacha20 = crypto.Xchacha20.poly1305Aead();
    final keyBytes = Uint8List.fromList(List.generate(testKeyHex.length ~/ 2, (i) => int.parse(testKeyHex.substring(i * 2, i * 2 + 2), radix: 16)));
    final nonce = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];
    final box = await xchacha20.encrypt(
      utf8.encode(plaintext),
      secretKey: crypto.SecretKey(keyBytes),
      nonce: nonce,
    );
    final xchaBytes = Uint8List.fromList([...nonce, ...box.cipherText, ...box.mac.bytes]);
    final xchaB64 = base64Encode(xchaBytes);
    final decryptedXcha = await cryptoService.decryptGroupMessage(xchaB64, testKeyHex);
    print("XChaCha20 decrypted: $decryptedXcha");
    expect(decryptedXcha, equals(plaintext));
  });
}
