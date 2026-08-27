import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xaneo/services/secure_session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates legacy secrets once and removes their plaintext copies',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        'xaneo_access_token': 'access-token',
        'xaneo_refresh_token': 'refresh-token',
        'xsec2_x25519_private': 'x25519-private',
        'xsec2_ed25519_private': 'ed25519-private',
      });

      final storage = SecureSessionStorage();
      final migrated = await storage.readActiveSession();

      expect(migrated?.accessToken, 'access-token');
      expect(migrated?.refreshToken, 'refresh-token');
      expect(migrated?.x25519Private, 'x25519-private');
      expect(migrated?.ed25519Private, 'ed25519-private');

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('xaneo_access_token'), isFalse);
      expect(preferences.containsKey('xaneo_refresh_token'), isFalse);
      expect(preferences.containsKey('xsec2_x25519_private'), isFalse);
      expect(preferences.containsKey('xsec2_ed25519_private'), isFalse);
      expect(preferences.getBool('xaneo_secure_active_migrated_v2'), isTrue);
    },
  );
}
