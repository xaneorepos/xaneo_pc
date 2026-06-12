import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xaneo_pc/services/crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CryptoService E2EE Tests', () {
    late CryptoService cryptoService;
    const password = "my_super_secure_password_123";

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cryptoService = CryptoService();
    });

    test('generateAndStoreKeys creates valid flat-format key bundle with signature', () async {
      final blob = await cryptoService.generateAndStoreKeys(password);
      
      expect(blob['algorithm'], equals('XSEC-2'));
      expect(blob['version'], equals(1));
      expect(blob['salt'], isNotNull);
      expect(blob['nonce'], isNotNull);
      expect(blob['encrypted_data'], isNotNull);
      expect(blob['signature'], isNotNull);
      expect(blob['pub'], isNotNull);
      expect(blob['pub']['x25519'], equals(cryptoService.x25519PublicKeyHex));
      expect(blob['pub']['ed25519'], equals(cryptoService.ed25519PublicKeyHex));
    });

    test('unlockFromBlob unlocks from flat format correctly', () async {
      final blob = await cryptoService.generateAndStoreKeys(password);
      
      // Clear memory keys
      await cryptoService.clearKeys();
      expect(cryptoService.hasKeys, isFalse);
      
      // Unlock using the flat blob
      final success = await cryptoService.unlockFromBlob(blob, password);
      expect(success, isTrue);
      expect(cryptoService.hasKeys, isTrue);
      expect(cryptoService.x25519PublicKeyHex, isNotNull);
      expect(cryptoService.ed25519PublicKeyHex, isNotNull);
    });

    test('unlockFromBlob handles nested format correctly', () async {
      final nestedBlob = {
        'version': 1,
        'kdf': 'pbkdf2',
        'kdf_params': {
          'salt': '8a4147c5b3aef7cfb9b07e5e4afff517',
          'iterations': 100000,
        },
        'cipher': 'aes-256-gcm',
        'cipher_params': {
          'nonce': 'd57ed07935c5cae39b86b4adbc2cd14863dfb69053009b6b',
        },
        'data': base64Encode(List<int>.filled(80, 0)),
        'pub': {
          'x25519': 'some_x25519_pub_hex',
          'ed25519': 'some_ed25519_pub_hex',
        }
      };
      
      await cryptoService.clearKeys();
      
      // Decrypt fails due to incorrect MAC, but it should not crash due to Null type cast
      final success = await cryptoService.unlockFromBlob(nestedBlob, password);
      expect(success, isFalse);
    });

    test('unlockFromBlob handles legacy Argon2id/XSEC-2 format gracefully', () async {
      final argon2idBlob = {
        'salt': '8a4147c5b3aef7cfb9b07e5e4afff517',
        'nonce': 'd57ed07935c5cae39b86b4adbc2cd14863dfb69053009b6b',
        'version': 1,
        'algorithm': 'XSEC-2',
        'signature': 'c67a1d0e7a723977bf4264e774b090ed13a3a2a978ea780b78ce2fdc5ea8c5449d5859f0bc8556cb206bb84d09a9b94ebc5a7ed9002ea69a1c662592c4a06002',
        'encrypted_data': '42033577d1a9a24018808fa514965846d81f38eedf4cd7c0b45d1190f5e808335f2fb30086952952c03507d39e4587363bcbb187a779335c105003b13273a40762ea4f2fe8f085fc7359f45766b81e94d7c48ab513d382cc04cd98c0e58b2515e295f843b961f25144e7d869d6791b122863ea1808c6e481c9d23a4f7c04c5c90370c6a1ffd33b95d027879264472beb3564df08bd6764b15be1a0143f437c5e6575a98bd246ecdd5399a9e2c8be5f6d6fb7eda76c661878ba006e19fa4f664348c8047102e3bed760cc79fd542f523e72de4ee4755d9b5ef9998563d0c8430e9df5b54d6ddb41308a728a2fe7f7bfd648d8325b38149c8ca283'
      };
      
      await cryptoService.clearKeys();
      
      // Should return false gracefully without throwing a Null subtype cast crash
      final success = await cryptoService.unlockFromBlob(argon2idBlob, password);
      expect(success, isFalse);
    });

    test('E2EE personal message encrypt and decrypt roundtrip between two users', () async {
      // 1. Generate Alice's keys
      final aliceBlob = await cryptoService.generateAndStoreKeys(password);
      final alicePub = cryptoService.x25519PublicKeyHex!;
      
      // 2. Generate Bob's keys
      final bobBlob = await cryptoService.generateAndStoreKeys(password);
      final bobPub = cryptoService.x25519PublicKeyHex!;
      
      // 3. Switch to Alice
      await cryptoService.unlockFromBlob(aliceBlob, password);
      expect(cryptoService.x25519PublicKeyHex, equals(alicePub));
      
      const originalMessage = "Hello Bob! This is Alice writing to you securely.";
      
      // Alice encrypts for Bob
      final encryptedB64 = await cryptoService.encryptPersonalMessage(originalMessage, bobPub, 'personal_1_2');
      
      // 4. Switch to Bob
      await cryptoService.unlockFromBlob(bobBlob, password);
      expect(cryptoService.x25519PublicKeyHex, equals(bobPub));
      
      // Bob decrypts from Alice
      final decryptedMessage = await cryptoService.decryptPersonalMessage(encryptedB64, alicePub, 'personal_1_2');
      
      expect(decryptedMessage, equals(originalMessage));
    });

    test('Group message encrypt and decrypt roundtrip', () async {
      const chatKeyHex = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"; // 32-byte key
      const originalMessage = "Hello group members!";
      
      final encryptedB64 = await cryptoService.encryptGroupMessage(originalMessage, chatKeyHex);
      final decrypted = await cryptoService.decryptGroupMessage(encryptedB64, chatKeyHex);
      
      expect(decrypted, equals(originalMessage));
    });
  });
}
