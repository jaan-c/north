import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

final _opsLimit = Sodium.cryptoPwhashOpslimitInteractive;
final _memLimit = Sodium.cryptoPwhashMemlimitInteractive;

/// Compute a hash for verifying [password] with [verifyPassword].
String derivePasswordHash(String password) {
  return PasswordHash.hashStringStorage(password,
      opslimit: _opsLimit, memlimit: _memLimit);
}

/// Verify [password] if it matches the [hash] produced by [derivePasswordHash].
bool verifyPassword(String password, String hash) {
  return PasswordHash.verifyStorage(hash, password);
}

/// Generate a 128 bit random salt.
List<int> generateSalt() {
  return PasswordHash.randomSalt();
}

/// Generate a key from [password] and [salt] for use in [encryptStream] and
/// [decryptStream].
Uint8List deriveKey(String password, List<int> salt) {
  return PasswordHash.hashString(password, Uint8List.fromList(salt),
      outlen: Sodium.cryptoSecretstreamXchacha20poly1305Keybytes,
      opslimit: _opsLimit,
      memlimit: _memLimit);
}
