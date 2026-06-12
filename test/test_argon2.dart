import 'dart:typed_data';
import 'package:argon2/argon2.dart';

Uint8List _deriveArgon2idKey(String password, Uint8List salt, int memory) {
  final params = Argon2Parameters(
    Argon2Parameters.ARGON2_id,
    salt,
    iterations: 3,
    memory: memory,
    lanes: 1,
    version: Argon2Parameters.ARGON2_VERSION_13,
  );
  final generator = Argon2BytesGenerator()..init(params);
  final key = Uint8List(32);
  generator.generateBytesFromString(password, key);
  return key;
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  final salt = Uint8List(16)..fillRange(0, 16, 1);
  
  // Test memory = 64
  final key64 = _deriveArgon2idKey("pass123", salt, 64);
  print("Dart Key (memory=64) Hex:    ${_bytesToHex(key64)}");

  // Test memory = 65536 (64 * 1024)
  final key65536 = _deriveArgon2idKey("pass123", salt, 64 * 1024);
  print("Dart Key (memory=65536) Hex: ${_bytesToHex(key65536)}");
}
