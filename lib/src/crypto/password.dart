import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:isolate/isolate_runner.dart';

final _opsLimit = Sodium.cryptoPwhashOpslimitInteractive;
final _memLimit = Sodium.cryptoPwhashMemlimitInteractive;

/// Compute a hash for verifying [password] with [verifyPassword].
Future<String> derivePasswordHash(String password) async {
  final runner = await IsolateRunner.spawn();
  return runner.run(_derivePasswordHash, password);
}

Future<String> _derivePasswordHash(String password) async {
  return PasswordHash.hashStringStorage(password,
      opslimit: _opsLimit, memlimit: _memLimit);
}

/// Verify [password] if it matches the [hash] produced by [derivePasswordHash].
Future<bool> verifyPassword(String password, String hash) async {
  final runner = await IsolateRunner.spawn();
  final args = _VerifyPasswordArgs(password, hash);
  return runner.run(_verifyPassword, args);
}

class _VerifyPasswordArgs {
  final String password;
  final String hash;
  _VerifyPasswordArgs(this.password, this.hash);
}

Future<bool> _verifyPassword(_VerifyPasswordArgs args) async {
  return PasswordHash.verifyStorage(args.hash, args.password);
}

/// Generate a 128 bit random salt.
List<int> generateSalt() {
  return PasswordHash.randomSalt();
}

/// Generate a key from [password] and [salt] for use in [encryptStream] and
/// [decryptStream].
Future<Uint8List> deriveKey(String password, List<int> salt) async {
  final runner = await IsolateRunner.spawn();
  final args = _DeriveKeyArgs(password, salt);
  return runner.run(_deriveKey, args);
}

class _DeriveKeyArgs {
  final String password;
  final List<int> salt;
  _DeriveKeyArgs(this.password, this.salt);
}

Future<Uint8List> _deriveKey(_DeriveKeyArgs args) async {
  return PasswordHash.hashString(args.password, Uint8List.fromList(args.salt),
      outlen: Sodium.cryptoSecretstreamXchacha20poly1305Keybytes,
      opslimit: _opsLimit,
      memlimit: _memLimit);
}
