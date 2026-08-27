import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/services/crypto_service.dart';

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

List<int> _fromHex(String value) => [
  for (var index = 0; index < value.length; index += 2)
    int.parse(value.substring(index, index + 2), radix: 16),
];

void main() {
  test('QR v2 transfer decrypts and is bound to its token', () async {
    const token = '00112233445566778899aabbccddeeff';
    final x25519 = crypto.X25519();
    final receiver = await x25519.newKeyPair();
    final receiverPublic = await receiver.extractPublicKey();
    final receiverPublicHex = _hex(receiverPublic.bytes);

    final sender = await x25519.newKeyPair();
    final senderPublic = await sender.extractPublicKey();
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: sender,
      remotePublicKey: receiverPublic,
    );
    final hkdf = crypto.Hkdf(hmac: crypto.Hmac.sha256(), outputLength: 32);
    final aesKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: _fromHex(token),
      info: utf8.encode('xaneo-qr-login-v2'),
    );
    final aad = utf8.encode('xaneo_qr_login|2|$token|$receiverPublicHex');
    final expected = <String, dynamic>{
      'x25519_private': 'private-key-material',
      'ed25519_private': 'signing-key-material',
    };
    final algorithm = crypto.AesGcm.with256bits();
    final box = await algorithm.encrypt(
      utf8.encode(jsonEncode(expected)),
      secretKey: aesKey,
      nonce: Uint8List.fromList(List<int>.generate(12, (index) => index)),
      aad: aad,
    );
    final payload = <String, dynamic>{
      'ciphertext': _hex([...box.cipherText, ...box.mac.bytes]),
      'nonce': _hex(box.nonce),
      'sender_pub': _hex(senderPublic.bytes),
    };

    final decrypted = await CryptoService().decryptQrTransferPayload(
      transferPayload: payload,
      ephemeralKeyPair: receiver,
      token: token,
      recipientPublicKeyHex: receiverPublicHex,
    );
    expect(decrypted, expected);

    final wrongToken = await CryptoService().decryptQrTransferPayload(
      transferPayload: payload,
      ephemeralKeyPair: receiver,
      token: '10112233445566778899aabbccddeeff',
      recipientPublicKeyHex: receiverPublicHex,
    );
    expect(wrongToken, isNull);
  });
}
