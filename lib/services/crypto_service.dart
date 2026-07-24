import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:pointycastle/digests/blake2b.dart';
import 'package:x25519/x25519.dart' as x25519;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:argon2/argon2.dart';
import 'logger_service.dart';

/// XSEC-2 Crypto Service for Xaneo PC
///
/// Implements E2E encryption compatible with the web client (xc-encryption.js + xsec2.js).
///
/// Key derivation scheme (must match web exactly):
///   - Personal chat:   BLAKE2b(sharedSecret, key=BLAKE2b(chatId))
///   - Favorites:       BLAKE2b(sharedSecret, key=BLAKE2b("favorites:userId"))
///   - Group/Channel:   Server-managed AES-256 key from /xsec2/keys/chat/{chatId}/
///
/// Message format:     base64(12-byte nonce + AES-GCM ciphertext + 16-byte tag)
///
/// The web client uses Web Crypto AES-GCM which appends the tag to ciphertext,
/// so the full encrypted payload is: nonce(12) || ciphertext || tag(16)
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  // Active keys in memory
  crypto.SimpleKeyPair? _x25519KeyPair;
  crypto.SimpleKeyPair? _ed25519KeyPair;

  // Raw private key bytes for x25519 scalar multiplication (matching libsodium/web)
  Uint8List? _x25519PrivateBytes;

  bool get hasKeys => _x25519KeyPair != null && _x25519PrivateBytes != null;

  // Hex representation of public keys
  String? get x25519PublicKeyHex => _x25519PublicKeyHex;
  String? get ed25519PublicKeyHex => _ed25519PublicKeyHex;

  String? _x25519PublicKeyHex;
  String? _ed25519PublicKeyHex;

  static const String _sharedPrefsKeyX25519 = 'xsec2_x25519_private';
  static const String _sharedPrefsKeyEd25519 = 'xsec2_ed25519_private';

  // Cache for ECDH shared secrets (theirPubHex → sharedSecret)
  final Map<String, Uint8List> _sharedSecretCache = {};

  // Cache for derived chat keys (chatId → derived key)
  final Map<String, Uint8List> _chatKeyCache = {};

  /// Initialize and load keys from local storage
  Future<bool> init() async {
    return await loadKeysFromLocalStorage();
  }

  Uint8List _deriveArgon2idKey(String password, Uint8List salt) {
    final params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      iterations: 3,
      memory: 64, // 64 KiB
      lanes: 1,
      version: Argon2Parameters.ARGON2_VERSION_13,
    );
    final generator = Argon2BytesGenerator()..init(params);
    final key = Uint8List(32);
    generator.generateBytesFromString(password, key);
    return key;
  }

  /// Generate new keys and return the encrypted blob to be uploaded to the server
  Future<Map<String, dynamic>> generateAndStoreKeys(String password) async {
    final x25519Algo = crypto.X25519();
    final ed25519Algo = crypto.Ed25519();

    // 1. Generate keypairs
    final xKeyPair = await x25519Algo.newKeyPair();
    final edKeyPair = await ed25519Algo.newKeyPair();

    // 2. Extract public key bytes
    final xPubKey = await xKeyPair.extractPublicKey();
    final edPubKey = await edKeyPair.extractPublicKey();

    _x25519PublicKeyHex = _bytesToHex(xPubKey.bytes);
    _ed25519PublicKeyHex = _bytesToHex(edPubKey.bytes);

    _x25519KeyPair = xKeyPair;
    _ed25519KeyPair = edKeyPair;

    // 3. Extract private key bytes
    final xPrivBytes = await xKeyPair.extractPrivateKeyBytes();
    final edPrivBytes = await edKeyPair.extractPrivateKeyBytes();

    _x25519PrivateBytes = Uint8List.fromList(xPrivBytes);

    // 4. Save to local SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sharedPrefsKeyX25519, _bytesToHex(xPrivBytes));
    await prefs.setString(_sharedPrefsKeyEd25519, _bytesToHex(edPrivBytes));

    final edPriv64 = Uint8List.fromList([...edPrivBytes, ...edPubKey.bytes]);

    // 5. Encrypt private keys to construct the encrypted_blob matching web exactly
    final keysData = {
      'x25519_private': _bytesToHex(xPrivBytes),
      'ed25519_private': _bytesToHex(edPriv64),
    };
    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(keysData)));

    // Derive key using Argon2id (salt must be exactly 16 bytes for sodium compatibility)
    final salt = _generateRandomBytes(16);
    final derivedPasswordBytes = _deriveArgon2idKey(password, salt);

    // Encrypt using XChaCha20-Poly1305 (nonce = 24 bytes)
    final nonce = _generateRandomBytes(24);
    final xchacha20 = crypto.Xchacha20.poly1305Aead();
    
    final secretBox = await xchacha20.encrypt(
      plaintext,
      secretKey: crypto.SecretKey(derivedPasswordBytes),
      nonce: nonce,
    );

    // Concatenate ciphertext and MAC tag to match web / standard structure
    final encryptedBytes = Uint8List.fromList([...secretBox.cipherText, ...secretBox.mac.bytes]);

    // Construct flat layout and sign it with Ed25519 private key
    final blobWithoutSignature = {
      'version': 1,
      'algorithm': 'XSEC-2',
      'salt': _bytesToHex(salt),
      'nonce': _bytesToHex(nonce),
      'encrypted_data': _bytesToHex(encryptedBytes),
    };
    final blobString = jsonEncode(blobWithoutSignature);
    final signatureObj = await ed25519Algo.sign(
      utf8.encode(blobString),
      keyPair: edKeyPair,
    );
    final signatureHex = _bytesToHex(signatureObj.bytes);

    // 6. Return the blob structure expected by Django
    return {
      ...blobWithoutSignature,
      'signature': signatureHex,
      'pub': {
        'x25519': _x25519PublicKeyHex,
        'ed25519': _ed25519PublicKeyHex,
      },
    };
  }

  /// Decrypt keys from server encrypted_blob and store them
  Future<bool> unlockFromBlob(Map<String, dynamic> blob, String password) async {
    try {
      // 1. Identify format and algorithm
      final String? algorithm = blob['algorithm'] as String?;
      final String? kdf = blob['kdf'] as String?;

      final bool isArgon2id = (algorithm == 'XSEC-2') || (kdf == 'argon2id');
      final bool isPbkdf2 = (kdf == 'pbkdf2') || (algorithm == 'pbkdf2-aes-gcm');

      if (!isArgon2id && !isPbkdf2) {
        Logger.warning('CryptoService', 'Unsupported KDF algorithm: ${kdf ?? algorithm}');
        return false;
      }

      // 2. Extract salt
      Uint8List salt;
      if (blob.containsKey('salt')) {
        salt = _hexToBytes(blob['salt'] as String);
      } else if (blob.containsKey('kdf_params')) {
        final kdfParams = blob['kdf_params'] as Map<String, dynamic>;
        salt = _hexToBytes(kdfParams['salt'] as String);
      } else {
        throw Exception("Missing salt or KDF parameters");
      }

      // 3. Extract nonce
      Uint8List nonce;
      if (blob.containsKey('nonce')) {
        nonce = _hexToBytes(blob['nonce'] as String);
      } else if (blob.containsKey('cipher_params')) {
        final cipherParams = blob['cipher_params'] as Map<String, dynamic>;
        nonce = _hexToBytes(cipherParams['nonce'] as String);
      } else {
        throw Exception("Missing cipher nonce");
      }

      // 4. Extract encrypted data (ciphertext + mac)
      Uint8List ciphertextWithMac;
      if (blob.containsKey('encrypted_data')) {
        final dataStr = blob['encrypted_data'] as String;
        ciphertextWithMac = _hexToBytes(dataStr);
      } else if (blob.containsKey('data')) {
        final dataStr = blob['data'] as String;
        ciphertextWithMac = base64Decode(dataStr);
      } else {
        throw Exception("Missing encrypted data");
      }

      if (ciphertextWithMac.length < 16) {
        throw Exception("Encrypted data is too short");
      }

      Uint8List xPriv;
      Uint8List edPriv;

      if (isArgon2id) {
        // Standard Web XSEC-2 decryption (Argon2id + XChaCha20-Poly1305)
        final derivedBytes = _deriveArgon2idKey(password, salt);
        
        final ciphertext = ciphertextWithMac.sublist(0, ciphertextWithMac.length - 16);
        final macBytes = ciphertextWithMac.sublist(ciphertextWithMac.length - 16);
        
        final xchacha20 = crypto.Xchacha20.poly1305Aead();
        final secretBox = crypto.SecretBox(
          ciphertext,
          nonce: nonce,
          mac: crypto.Mac(macBytes),
        );
        
        final decryptedBytes = await xchacha20.decrypt(
          secretBox,
          secretKey: crypto.SecretKey(derivedBytes),
        );
        
        final String jsonStr = utf8.decode(decryptedBytes);
        final Map<String, dynamic> keysData = jsonDecode(jsonStr);
        
        final String? xPrivHex = keysData['x25519_private'] as String? ?? keysData['x25519_private_key'] as String?;
        final String? edPrivHex = keysData['ed25519_private'] as String? ?? keysData['ed25519_private_key'] as String?;
        
        if (xPrivHex == null || edPrivHex == null) {
          throw Exception("Missing private keys in decrypted json");
        }
        
        xPriv = _hexToBytes(xPrivHex);
        final edPrivFull = _hexToBytes(edPrivHex);
        edPriv = edPrivFull.length == 64
            ? Uint8List.fromList(edPrivFull.sublist(0, 32))
            : edPrivFull;
      } else {
        // Fallback PBKDF2-AES-GCM format
        int iterations = 100000;
        if (blob.containsKey('iterations')) {
          iterations = blob['iterations'] as int;
        } else if (blob.containsKey('kdf_params')) {
          final kdfParams = blob['kdf_params'] as Map<String, dynamic>;
          iterations = kdfParams['iterations'] as int? ?? 100000;
        }

        final pbkdf2 = crypto.Pbkdf2(
          macAlgorithm: crypto.Hmac.sha256(),
          iterations: iterations,
          bits: 256,
        );
        final derivedKey = await pbkdf2.deriveKey(
          secretKey: crypto.SecretKey(utf8.encode(password)),
          nonce: salt,
        );
        final derivedBytes = Uint8List.fromList(await derivedKey.extractBytes());

        final cleanCiphertext = ciphertextWithMac.sublist(0, ciphertextWithMac.length - 16);
        final macBytes = ciphertextWithMac.sublist(ciphertextWithMac.length - 16);

        final aesGcm = crypto.AesGcm.with256bits();
        final secretBox = crypto.SecretBox(
          cleanCiphertext,
          nonce: nonce,
          mac: crypto.Mac(macBytes),
        );

        final decryptedBytes = await aesGcm.decrypt(
          secretBox,
          secretKey: crypto.SecretKey(derivedBytes),
        );

        if (decryptedBytes.length != 64) {
          return false;
        }

        xPriv = Uint8List.fromList(decryptedBytes.sublist(0, 32));
        edPriv = Uint8List.fromList(decryptedBytes.sublist(32, 64));
      }

      // Reconstruct keypairs
      final x25519Algo = crypto.X25519();
      final ed25519Algo = crypto.Ed25519();

      _x25519KeyPair = await x25519Algo.newKeyPairFromSeed(xPriv);
      _ed25519KeyPair = await ed25519Algo.newKeyPairFromSeed(edPriv);
      _x25519PrivateBytes = Uint8List.fromList(xPriv);

      final xPubKey = await _x25519KeyPair!.extractPublicKey();
      final edPubKey = await _ed25519KeyPair!.extractPublicKey();

      _x25519PublicKeyHex = _bytesToHex(xPubKey.bytes);
      _ed25519PublicKeyHex = _bytesToHex(edPubKey.bytes);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sharedPrefsKeyX25519, _bytesToHex(xPriv));
      await prefs.setString(_sharedPrefsKeyEd25519, _bytesToHex(edPriv));

      // Clear caches since keys changed
      _sharedSecretCache.clear();
      _chatKeyCache.clear();

      return true;
    } catch (e) {
      Logger.error('CryptoService', 'Error unlocking key bundle from blob', e);
      return false;
    }
  }

  /// Restore keys from local SharedPreferences
  Future<bool> loadKeysFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final xPrivHex = prefs.getString(_sharedPrefsKeyX25519);
      final edPrivHex = prefs.getString(_sharedPrefsKeyEd25519);

      if (xPrivHex == null || edPrivHex == null) {
        return false;
      }

      final xPriv = _hexToBytes(xPrivHex);
      final edPrivFull = _hexToBytes(edPrivHex);
      final edPriv = edPrivFull.length == 64
          ? Uint8List.fromList(edPrivFull.sublist(0, 32))
          : edPrivFull;

      final x25519Algo = crypto.X25519();
      final ed25519Algo = crypto.Ed25519();

      _x25519KeyPair = await x25519Algo.newKeyPairFromSeed(xPriv);
      _ed25519KeyPair = await ed25519Algo.newKeyPairFromSeed(edPriv);
      _x25519PrivateBytes = Uint8List.fromList(xPriv);

      final xPubKey = await _x25519KeyPair!.extractPublicKey();
      final edPubKey = await _ed25519KeyPair!.extractPublicKey();

      _x25519PublicKeyHex = _bytesToHex(xPubKey.bytes);
      _ed25519PublicKeyHex = _bytesToHex(edPubKey.bytes);

      return true;
    } catch (e) {
      Logger.error('CryptoService', 'Error loading keys from local storage', e);
      return false;
    }
  }

  /// Clear keys from memory and local storage
  Future<void> clearKeys() async {
    _x25519KeyPair = null;
    _ed25519KeyPair = null;
    _x25519PrivateBytes = null;
    _x25519PublicKeyHex = null;
    _ed25519PublicKeyHex = null;
    _sharedSecretCache.clear();
    _chatKeyCache.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sharedPrefsKeyX25519);
    await prefs.remove(_sharedPrefsKeyEd25519);
  }

  // ==================== KEY DERIVATION (WEB-COMPATIBLE) ====================

  /// Compute ECDH shared secret using raw X25519 scalar multiplication.
  /// This matches the web client's sodium.crypto_scalarmult(myPrivKey, theirPubKey).
  Uint8List _computeSharedSecret(String theirPublicKeyHex) {
    final normalizedKey = theirPublicKeyHex.trim().toLowerCase();
    final cached = _sharedSecretCache[normalizedKey];
    if (cached != null) return cached;

    if (_x25519PrivateBytes == null) {
      throw StateError('X25519 private key not loaded');
    }

    final theirPubBytes = _hexToBytes(theirPublicKeyHex);
    // Use raw x25519 scalar multiplication — same as libsodium crypto_scalarmult
    final shared = x25519.X25519(_x25519PrivateBytes!, theirPubBytes);
    _sharedSecretCache[normalizedKey] = shared;
    return shared;
  }

  /// BLAKE2b hash — matches libsodium's sodium.crypto_generichash(outputLength, input, key).
  /// When key is provided, it's a keyed hash (BLAKE2b-MAC).
  Uint8List _blake2b(Uint8List input, {Uint8List? key, int outputLength = 32}) {
    final digest = Blake2bDigest(digestSize: outputLength, key: key);
    digest.update(input, 0, input.length);
    final out = Uint8List(outputLength);
    digest.doFinal(out, 0);
    return out;
  }

  /// Derive AES key from shared secret + context.
  /// Exactly matches web's deriveAESKeyFromSharedSecret():
  ///   salt = crypto_generichash(32, context_string)      // BLAKE2b(context)
  ///   key  = crypto_generichash(32, sharedBytes, salt)    // BLAKE2b(shared, key=salt)
  Uint8List _deriveKeyFromSharedSecret(Uint8List sharedSecret, String context) {
    final contextBytes = Uint8List.fromList(utf8.encode(context));
    final salt = _blake2b(contextBytes, outputLength: 32);
    return _blake2b(sharedSecret, key: salt, outputLength: 32);
  }

  /// Derive personal chat key.
  /// Web client: deriveAESKeyFromSharedSecret(sharedSecret, chatId)
  /// chatId is something like "personal_1_4"
  Uint8List derivePersonalChatKey(String theirPublicKeyHex, String chatId) {
    final cacheKey = 'personal:$chatId';
    final cached = _chatKeyCache[cacheKey];
    if (cached != null) return cached;

    final shared = _computeSharedSecret(theirPublicKeyHex);
    final key = _deriveKeyFromSharedSecret(shared, chatId);
    _chatKeyCache[cacheKey] = key;
    return key;
  }

  /// Derive favorites key.
  /// Web client: deriveAESKeyFromSharedSecret(sharedSecret, "favorites:userId")
  /// where sharedSecret = crypto_scalarmult(myPriv, myPub)
  Uint8List deriveFavoritesChatKey(String myUserId) {
    final cacheKey = 'favorites:$myUserId';
    final cached = _chatKeyCache[cacheKey];
    if (cached != null) return cached;

    if (_x25519PublicKeyHex == null) {
      throw StateError('X25519 public key not loaded');
    }

    final shared = _computeSharedSecret(_x25519PublicKeyHex!);
    final context = 'favorites:$myUserId';
    final key = _deriveKeyFromSharedSecret(shared, context);
    _chatKeyCache[cacheKey] = key;
    return key;
  }

  Future<Uint8List> _legacyShaDerive(Uint8List sharedSecret, String context) async {
    final contextBytes = Uint8List.fromList(utf8.encode(context));
    final input = Uint8List(sharedSecret.length + contextBytes.length);
    input.setRange(0, sharedSecret.length, sharedSecret);
    input.setRange(sharedSecret.length, input.length, contextBytes);

    final sha256 = crypto.Sha256();
    final hash1 = await sha256.hash(input);
    final hash2 = await sha256.hash(hash1.bytes);
    return Uint8List.fromList(hash2.bytes);
  }

  Future<Uint8List> _deriveRootKey(Uint8List sharedSecret) async {
    final context = Uint8List.fromList(utf8.encode("XSEC-2 root key"));
    final hkdf = crypto.Hkdf(
      hmac: crypto.Hmac.sha256(),
      outputLength: 32,
    );

    final derived = await hkdf.deriveKey(
      secretKey: crypto.SecretKey(sharedSecret),
      nonce: context,
      info: context,
    );

    return Uint8List.fromList(await derived.extractBytes());
  }

  Future<List<Uint8List>> _candidateDecryptKeys({
    required String chatId,
    String? peerPublicKeyHex,
  }) async {
    final variants = <Uint8List>[];
    final parts = chatId.split('_');
    if (parts.isEmpty || !hasKeys) return variants;

    void add(Uint8List key) {
      if (key.length != 32) return;
      final hex = _bytesToHex(key);
      if (variants.any((k) => _bytesToHex(k) == hex)) return;
      variants.add(key);
    }

    // 1. For personal chats:
    if (parts[0] == 'personal' && parts.length >= 3 && peerPublicKeyHex != null) {
      try {
        final shared = _computeSharedSecret(peerPublicKeyHex);
        
        // personal.web.exact (blake2b)
        add(derivePersonalChatKey(peerPublicKeyHex, chatId));

        // personal.shared.raw
        add(shared);

        // personal.sha256(shared)
        final shaShared = await crypto.Sha256().hash(shared).then((h) => Uint8List.fromList(h.bytes));
        add(shaShared);

        // personal.legacy.sha(userIds) and personal.legacy.sha(chatId)
        final myUserId = parts[1];
        final otherUserId = parts[2];
        final sortedUsers = [myUserId, otherUserId]..sort();
        
        add(await _legacyShaDerive(shared, 'personal:${sortedUsers[0]}:${sortedUsers[1]}'));
        add(await _legacyShaDerive(shared, chatId));

        // personal.blake(shared | salt=personal:min:max)
        final personalSalt = _blake2b(
          Uint8List.fromList(utf8.encode('personal:${sortedUsers[0]}:${sortedUsers[1]}')),
          outputLength: 32,
        );
        add(_blake2b(shared, key: personalSalt, outputLength: 32));

        // personal.blake(shared | salt=chatId)
        final chatIdSalt = _blake2b(
          Uint8List.fromList(utf8.encode(chatId)),
          outputLength: 32,
        );
        add(_blake2b(shared, key: chatIdSalt, outputLength: 32));

        // personal.legacy.sha(sortedPubKeys)
        if (_x25519PublicKeyHex != null) {
          final sortedPubs = [_x25519PublicKeyHex!, peerPublicKeyHex]..sort();
          add(await _legacyShaDerive(shared, sortedPubs.join(':')));
        }

        // personal.hkdf(shared, default)
        final root = await _deriveRootKey(shared);
        add(root);
        
        // HKDF-SHA256(shared, info=chatId, salt=chatId)
        final hkdf = crypto.Hkdf(hmac: crypto.Hmac.sha256(), outputLength: 32);
        final derivedHkdf = await hkdf.deriveKey(
          secretKey: crypto.SecretKey(shared),
          nonce: Uint8List.fromList(utf8.encode(chatId)),
          info: Uint8List.fromList(utf8.encode(chatId)),
        );
        add(Uint8List.fromList(await derivedHkdf.extractBytes()));
      } catch (e) {
        print("Error deriving personal candidate keys: $e");
      }
    }

    // 2. For favorites:
    if (parts[0] == 'favorites' && _x25519PublicKeyHex != null) {
      try {
        final shared = _computeSharedSecret(_x25519PublicKeyHex!);
        
        // Extract user ID properly from favorites_user_1 or favorites_1
        String myUserId = "1";
        if (parts.length >= 3 && parts[1] == 'user') {
          myUserId = parts[2];
        } else if (parts.length >= 2) {
          myUserId = parts[1];
        }

        // favorites.web.exact (blake2b)
        add(deriveFavoritesChatKey(myUserId));
        if (myUserId != "1") {
          add(deriveFavoritesChatKey("1"));
        }

        // favorites.hkdf.root
        final root = await _deriveRootKey(shared);
        add(root);

        // favorites.shared.raw
        add(shared);

        // favorites.sha256(shared)
        final shaShared = await crypto.Sha256().hash(shared).then((h) => Uint8List.fromList(h.bytes));
        add(shaShared);

        // blake2b variants
        final favContextStr = 'favorites:$myUserId';
        final favNamespace = Uint8List.fromList(utf8.encode('xsec2:favorites:$myUserId'));
        final chatIdBytes = Uint8List.fromList(utf8.encode(chatId));

        final favSaltKeyedByShared = _blake2b(favNamespace, key: shared, outputLength: 32);
        final favSaltKeyedByRoot = _blake2b(favNamespace, key: root, outputLength: 32);
        final favSaltUnkeyed = _blake2b(favNamespace, outputLength: 32);

        add(_blake2b(root, key: favSaltKeyedByShared, outputLength: 32));
        add(_blake2b(shared, key: favSaltKeyedByRoot, outputLength: 32));
        add(_blake2b(root, key: favSaltUnkeyed, outputLength: 32));
        add(_blake2b(shared, key: favSaltUnkeyed, outputLength: 32));
        add(_blake2b(root, key: _blake2b(chatIdBytes, outputLength: 32), outputLength: 32));
        add(_blake2b(shared, key: _blake2b(chatIdBytes, outputLength: 32), outputLength: 32));
        
        final rootHexBytes = Uint8List.fromList(utf8.encode(_bytesToHex(root)));
        final sharedHexBytes = Uint8List.fromList(utf8.encode(_bytesToHex(shared)));
        add(_blake2b(rootHexBytes, key: chatIdBytes, outputLength: 32));
        add(_blake2b(sharedHexBytes, key: chatIdBytes, outputLength: 32));
        add(_blake2b(root, key: chatIdBytes, outputLength: 32));
        add(_blake2b(shared, key: chatIdBytes, outputLength: 32));

        // HKDF variants
        final rootContext = Uint8List.fromList(utf8.encode("XSEC-2 root key"));
        final favContextBytes = Uint8List.fromList(utf8.encode(favContextStr));
        
        final hkdf = crypto.Hkdf(hmac: crypto.Hmac.sha256(), outputLength: 32);
        
        final hkdf1 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: rootContext, info: favContextBytes);
        add(Uint8List.fromList(await hkdf1.extractBytes()));

        final hkdf2 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: favContextBytes, info: rootContext);
        add(Uint8List.fromList(await hkdf2.extractBytes()));

        final hkdf3 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: rootContext, info: const <int>[]);
        add(Uint8List.fromList(await hkdf3.extractBytes()));

        final hkdf4 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: const <int>[], info: rootContext);
        add(Uint8List.fromList(await hkdf4.extractBytes()));

        final hkdf5 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: const <int>[], info: const <int>[]);
        add(Uint8List.fromList(await hkdf5.extractBytes()));

        final hkdf6 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: chatIdBytes, info: Uint8List.fromList(utf8.encode(myUserId)));
        add(Uint8List.fromList(await hkdf6.extractBytes()));

        final hkdf7 = await hkdf.deriveKey(secretKey: crypto.SecretKey(shared), nonce: Uint8List.fromList(utf8.encode(myUserId)), info: chatIdBytes);
        add(Uint8List.fromList(await hkdf7.extractBytes()));

        final hkdf8 = await hkdf.deriveKey(secretKey: crypto.SecretKey(root), nonce: chatIdBytes, info: chatIdBytes);
        add(Uint8List.fromList(await hkdf8.extractBytes()));

        // sha256(favorites_user_$myUserId)
        final hashedFav1 = await crypto.Sha256().hash(utf8.encode('favorites_user_$myUserId')).then((h) => Uint8List.fromList(h.bytes));
        add(hashedFav1);

        // sha256(favorites)
        final hashedFavWeb = await crypto.Sha256().hash(utf8.encode('favorites')).then((h) => Uint8List.fromList(h.bytes));
        add(hashedFavWeb);

        // sha256(favorites:$myUserId)
        final hashedFav2 = await crypto.Sha256().hash(utf8.encode('favorites:$myUserId')).then((h) => Uint8List.fromList(h.bytes));
        add(hashedFav2);

        // sha256(chatId)
        final hashedFav3 = await crypto.Sha256().hash(utf8.encode(chatId)).then((h) => Uint8List.fromList(h.bytes));
        add(hashedFav3);

      } catch (e) {
        print("Error deriving favorites candidate keys: $e");
      }
    }

    return variants;
  }

  // ==================== MESSAGE ENCRYPTION/DECRYPTION ====================

  /// Decrypt a message using AES-256-GCM with the given key bytes.
  /// Format: base64(12-byte nonce + ciphertext + 16-byte tag)
  /// This matches the web client's decryptMessage() in xc-encryption.js
  Future<String> decryptMessageWithKey(
    String base64Message,
    Uint8List keyBytes, {
    String? debugLabel,
    bool quiet = false,
  }) async {
    try {
      final trimmed = base64Message.trim();
      final rawData = base64Decode(trimmed);
      if (rawData.length < 12 + 16) {
        throw Exception("Invalid ciphertext: too short (${rawData.length} bytes)");
      }

      final nonce = rawData.sublist(0, 12);
      // Web Crypto API's AES-GCM returns ciphertext+tag concatenated.
      // The `cryptography` package needs them separated.
      final ciphertextWithTag = rawData.sublist(12);
      final ciphertext = ciphertextWithTag.sublist(0, ciphertextWithTag.length - 16);
      final mac = ciphertextWithTag.sublist(ciphertextWithTag.length - 16);

      final aesGcm = crypto.AesGcm.with256bits();
      final secretBox = crypto.SecretBox(
        ciphertext,
        nonce: nonce,
        mac: crypto.Mac(mac),
      );

      final plaintextBytes = await aesGcm.decrypt(
        secretBox,
        secretKey: crypto.SecretKey(keyBytes),
      );

      return utf8.decode(plaintextBytes);
    } catch (e) {
      if (!quiet) {
        print("========================================");
        print("E2E DECRYPTION FAILURE!");
        if (debugLabel != null) {
          print("Context:\n$debugLabel");
        }
        print("Error details: $e");
        print("Raw Base64: '$base64Message'");
        try {
          final trimmed = base64Message.trim();
          final rawData = base64Decode(trimmed);
          print("Decoded length: ${rawData.length} bytes");
          if (rawData.length >= 12) {
            print("Nonce (hex): ${_bytesToHex(rawData.sublist(0, 12))}");
          }
          if (rawData.length >= 12 + 16) {
            final ciphertextWithTag = rawData.sublist(12);
            final ciphertext = ciphertextWithTag.sublist(0, ciphertextWithTag.length - 16);
            final mac = ciphertextWithTag.sublist(ciphertextWithTag.length - 16);
            print("Ciphertext (hex): ${_bytesToHex(ciphertext)}");
            print("MAC/Tag (hex): ${_bytesToHex(mac)}");
          } else {
            print("Raw bytes (hex): ${_bytesToHex(rawData)}");
          }
        } catch (decodeErr) {
          print("Failed to decode base64 input: $decodeErr");
        }
        print("Key used (hex): ${_bytesToHex(keyBytes)}");
        print("========================================");
      }
      return "[Ошибка дешифрования]";
    }
  }

  /// Encrypt a message using AES-256-GCM with the given key bytes.
  /// Output format: base64(12-byte nonce + ciphertext + 16-byte tag)
  /// Matches the web client's encryptMessage() in xc-encryption.js
  Future<String> encryptMessageWithKey(String plaintext, Uint8List keyBytes) async {
    final plaintextBytes = utf8.encode(plaintext);
    final nonce = _generateRandomBytes(12);
    final aesGcm = crypto.AesGcm.with256bits();

    final secretBox = await aesGcm.encrypt(
      plaintextBytes,
      secretKey: crypto.SecretKey(keyBytes),
      nonce: nonce,
    );

    // Format: nonce(12) + ciphertext + tag(16)
    final encryptedBytes = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return base64Encode(encryptedBytes);
  }

  /// Decrypt personal chat message (ECDH X25519 + BLAKE2b key derivation + AES-GCM)
  Future<String> decryptPersonalMessage(
    String base64Message,
    String otherUserPublicKeyHex,
    String chatId,
  ) async {
    if (otherUserPublicKeyHex == 'bot' || otherUserPublicKeyHex.isEmpty) {
      return base64Message;
    }
    if (!hasKeys) {
      throw Exception("Crypto keys not loaded");
    }

    final candidates = await _candidateDecryptKeys(
      chatId: chatId,
      peerPublicKeyHex: otherUserPublicKeyHex,
    );

    for (final key in candidates) {
      final decrypted = await decryptMessageWithKey(base64Message, key, quiet: true);
      if (decrypted != "[Ошибка дешифрования]") {
        return decrypted;
      }
    }

    final defaultKey = derivePersonalChatKey(otherUserPublicKeyHex, chatId);
    final sharedSecret = _computeSharedSecret(otherUserPublicKeyHex);
    final contextBytes = Uint8List.fromList(utf8.encode(chatId));
    final salt = _blake2b(contextBytes, outputLength: 32);

    final debugLabel = "Personal Chat (ALL CANDIDATES FAILED)\n"
        "  - Chat ID: $chatId\n"
        "  - Peer Public Key: $otherUserPublicKeyHex\n"
        "  - My Public Key: $_x25519PublicKeyHex\n"
        "  - My Private Key: ${(_x25519PrivateBytes != null) ? _bytesToHex(_x25519PrivateBytes!) : 'null'}\n"
        "  - Shared Secret (ecdh): ${_bytesToHex(sharedSecret)}\n"
        "  - Blake2b Context Salt: ${_bytesToHex(salt)}\n"
        "  - Default Derived Key: ${_bytesToHex(defaultKey)}\n"
        "  - Total Candidates Checked: ${candidates.length}";

    return decryptMessageWithKey(base64Message, defaultKey, debugLabel: debugLabel);
  }

  /// Encrypt personal chat message (ECDH X25519 + BLAKE2b key derivation + AES-GCM)
  Future<String> encryptPersonalMessage(
    String plaintext,
    String otherUserPublicKeyHex,
    String chatId,
  ) async {
    if (otherUserPublicKeyHex == 'bot' || otherUserPublicKeyHex.isEmpty) {
      return plaintext;
    }
    if (!hasKeys) {
      throw Exception("Crypto keys not loaded");
    }

    final keyBytes = derivePersonalChatKey(otherUserPublicKeyHex, chatId);
    return encryptMessageWithKey(plaintext, keyBytes);
  }

  /// Decrypt favorites message (ECDH with self + BLAKE2b + AES-GCM)
  Future<String> decryptFavoritesMessage(
    String base64Message,
    String myUserId,
  ) async {
    if (!hasKeys) {
      throw Exception("Crypto keys not loaded");
    }

    // Try candidates for both favorites_1 and favorites_user_1 formats
    final candidates1 = await _candidateDecryptKeys(chatId: "favorites_$myUserId");
    final candidates2 = await _candidateDecryptKeys(chatId: "favorites_user_$myUserId");
    
    final allCandidates = <Uint8List>[];
    final seen = <String>{};
    for (final key in [...candidates1, ...candidates2]) {
      if (seen.add(_bytesToHex(key))) {
        allCandidates.add(key);
      }
    }

    for (final key in allCandidates) {
      final decrypted = await decryptMessageWithKey(base64Message, key, quiet: true);
      if (decrypted != "[Ошибка дешифрования]") {
        return decrypted;
      }
    }

    final defaultKey = deriveFavoritesChatKey(myUserId);
    final sharedSecret = _computeSharedSecret(_x25519PublicKeyHex!);
    final context = 'favorites:$myUserId';
    final contextBytes = Uint8List.fromList(utf8.encode(context));
    final salt = _blake2b(contextBytes, outputLength: 32);

    final debugLabel = "Favorites Chat (ALL CANDIDATES FAILED)\n"
        "  - My User ID: $myUserId\n"
        "  - My Public Key: $_x25519PublicKeyHex\n"
        "  - My Private Key: ${(_x25519PrivateBytes != null) ? _bytesToHex(_x25519PrivateBytes!) : 'null'}\n"
        "  - Shared Secret (ecdh self): ${_bytesToHex(sharedSecret)}\n"
        "  - Blake2b Context Salt: ${_bytesToHex(salt)}\n"
        "  - Default Derived Key: ${_bytesToHex(defaultKey)}\n"
        "  - Total Candidates Checked: ${allCandidates.length}";

    return decryptMessageWithKey(base64Message, defaultKey, debugLabel: debugLabel);
  }

  /// Encrypt favorites message (ECDH with self + BLAKE2b + AES-GCM)
  Future<String> encryptFavoritesMessage(
    String plaintext,
    String myUserId,
  ) async {
    if (!hasKeys) {
      throw Exception("Crypto keys not loaded");
    }

    final keyBytes = deriveFavoritesChatKey(myUserId);
    return encryptMessageWithKey(plaintext, keyBytes);
  }

  /// Decrypt group chat message (XChaCha20-Poly1305 with AES-GCM fallback using server-managed symmetric key)
  Future<String> decryptGroupMessage(
    String base64Message,
    String chatKeyHex,
  ) async {
    final keyBytes = _hexToBytes(chatKeyHex);
    final trimmed = base64Message.trim().replaceAll('"', '');
    if (trimmed.isEmpty) return "";

    Uint8List rawData;
    try {
      rawData = base64Decode(trimmed);
    } catch (_) {
      return base64Message;
    }

    if (rawData.length < 28) {
      return base64Message;
    }

    // 1. Try XChaCha20-Poly1305 (24-byte nonce + ciphertext + 16-byte mac) - Standard group E2EE in Web & Mobile
    if (rawData.length >= 40) {
      try {
        final nonce = rawData.sublist(0, 24);
        final ciphertextWithMac = rawData.sublist(24);
        final ciphertext = ciphertextWithMac.sublist(0, ciphertextWithMac.length - 16);
        final mac = ciphertextWithMac.sublist(ciphertextWithMac.length - 16);

        final xchacha20 = crypto.Xchacha20.poly1305Aead();
        final secretBox = crypto.SecretBox(
          ciphertext,
          nonce: nonce,
          mac: crypto.Mac(mac),
        );

        final decryptedBytes = await xchacha20.decrypt(
          secretBox,
          secretKey: crypto.SecretKey(keyBytes),
        );
        return utf8.decode(decryptedBytes);
      } catch (e) {
        // Fallback to AES-GCM
      }
    }

    // 2. Fallback to AES-256-GCM (12-byte nonce + ciphertext + 16-byte mac)
    final debugLabel = "Group Chat\n"
        "  - Chat Key Hex: $chatKeyHex";
    return decryptMessageWithKey(base64Message, keyBytes, debugLabel: debugLabel, quiet: true);
  }

  /// Encrypt group chat message (XChaCha20-Poly1305 with server-managed symmetric key)
  Future<String> encryptGroupMessage(
    String plaintext,
    String chatKeyHex,
  ) async {
    final keyBytes = _hexToBytes(chatKeyHex);
    final plaintextBytes = utf8.encode(plaintext);
    final nonce = _generateRandomBytes(24);
    final xchacha20 = crypto.Xchacha20.poly1305Aead();

    final secretBox = await xchacha20.encrypt(
      plaintextBytes,
      secretKey: crypto.SecretKey(keyBytes),
      nonce: nonce,
    );

    final encryptedBytes = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return base64Encode(encryptedBytes);
  }

  // ==================== HELPER METHODS ====================

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final clean = hex.trim();
    return Uint8List.fromList(
      List<int>.generate(clean.length ~/ 2, (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  }
}
