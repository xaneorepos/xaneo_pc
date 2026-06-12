import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/digests/blake2b.dart';

Uint8List _blake2b(Uint8List input, {Uint8List? key, int outputLength = 32}) {
  final digest = Blake2bDigest(digestSize: outputLength, key: key);
  digest.update(input, 0, input.length);
  final out = Uint8List(outputLength);
  digest.doFinal(out, 0);
  return out;
}

Uint8List _deriveKeyFromSharedSecret(Uint8List sharedSecret, String context) {
  final contextBytes = Uint8List.fromList(utf8.encode(context));
  final salt = _blake2b(contextBytes, outputLength: 32);
  return _blake2b(sharedSecret, key: salt, outputLength: 32);
}

void main() {
  final sharedSecretStr = "1fc38e4bb45d8d0c8f32a9d2d97db1b5b6eae0307143521b90a144c5481ef016";
  // Decode hex
  final sharedSecret = Uint8List(sharedSecretStr.length ~/ 2);
  for (var i = 0; i < sharedSecretStr.length; i += 2) {
    sharedSecret[i ~/ 2] = int.parse(sharedSecretStr.substring(i, i + 2), radix: 16);
  }
  
  final context = "favorites:1";
  
  final result = _deriveKeyFromSharedSecret(sharedSecret, context);
  print(result.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
}
