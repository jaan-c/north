import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

final _opsLimit = Sodium.cryptoPwhashOpslimitSensitive;
final _memLimit = Sodium.cryptoPwhashMemlimitSensitive;

/// Compute a hash for verifying [password] with [verifyPasswordWithHash].
String derivePasswordHash(String password) {
  return PasswordHash.hashStringStorage(password,
      opslimit: _opsLimit, memlimit: _memLimit);
}

/// Verify [password] if it matches the [hash] produced by [derivePasswordHash].
bool verifyPasswordWithHash(String password, String hash) {
  return PasswordHash.verifyStorage(hash, password);
}

/// Generate a 128 bit random salt.
Uint8List generateSalt() {
  return PasswordHash.randomSalt();
}

/// Derive a secret key from [password] and [salt], for use with other cryptos.
Uint8List deriveKeyFromPassword(String password, Uint8List salt) {
  return PasswordHash.hashString(password, salt,
      outlen: 32, opslimit: _opsLimit, memlimit: _memLimit);
}
