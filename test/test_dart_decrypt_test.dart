import 'package:xaneo_pc/services/crypto_service.dart';

import "package:flutter_test/flutter_test.dart";
void main() {
  test("decrypt", () async {
  final blob = {
    "version": 1,
    "algorithm": "XSEC-2",
    "encrypted_data": "7d959bf8ca7696f3fa132e3865ee75f450e0e697b090e192665ab036bdd25851b3b8e83a27c7eae75c429292e800d30c924a60c5058b9fbc68018ffd5be5454cc490be764b317e9356512bae4ac4ea2c61",
    "nonce": "1aeb5050e9cb581b2a26216e81643582c149d68b251a94bc",
    "salt": "da5c70b93451341de2f3f1b75edd8dbd"
  };

  final password = "password123";

  final cryptoService = CryptoService();
  try {
    final success = await cryptoService.unlockFromBlob(blob, password);
    print("Unlock success: $success");
  } catch (e) {
    print("Error unlocking: $e");
  }
  });
}
