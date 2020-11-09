import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:isolate/isolate.dart';
import 'package:quiver/async.dart';
import 'package:quiver/check.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:pedantic/pedantic.dart';

final _headerSize = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;
final _authSize = Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
final _chunkSize = 1048576; // 1 MB
final _messageTag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
final _finalTag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;

final _opsLimit = Sodium.cryptoPwhashOpslimitSensitive;
final _memLimit = Sodium.cryptoPwhashMemlimitSensitive;

class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);
  @override
  String toString() => '${(CryptoException).toString()}: $message';
}

/// Encrypt [plainStream] with a key derived from [password] and [salt].
///
/// [plainStream] can emit arbitrarily sized chunks.
///
/// [ArgumentError] will be thrown if [password] is empty or if [salt] is less
/// than 16 bytes. [CryptoException] is thrown on encryption error.
Stream<List<int>> encryptStream(
    String password, List<int> salt, Stream<List<int>> plainStream) async* {
  yield* _cryptoStream(password, salt, plainStream, _CryptoMode.encrypt);
}

/// Decrypt [cipherStream] with a key derived from [password] and [salt].
///
/// [cipherStream] can emit arbitrarily sized chunks.
///
/// [ArgumentError] will be thrown if [password] is empty or if [salt] is less
/// than 16 bytes. [CryptoException] is thrown on encryption error.
Stream<List<int>> decryptStream(
    String password, List<int> salt, Stream<List<int>> cipherStream) async* {
  yield* _cryptoStream(password, salt, cipherStream, _CryptoMode.decrypt);
}

/// Runs [_cryptoInIsolate] inside an [Isolate] with [_CryptoArgs] populated
/// with [password], [salt], [inStream] and [mode].
///
/// This handles the null signalling expected by [_cryptoInIsolate].
///
/// An [ArgumentError] is thrown if [password] is empty or [salt] is less than
/// 16 bytes. [CryptoException] is thrown on encryption or decryption errors.
Stream<List<int>> _cryptoStream(String password, List<int> salt,
    Stream<List<int>> inStream, _CryptoMode mode) async* {
  checkArgument(password.isNotEmpty, message: 'password must not be empty');
  checkArgument(salt.length >= 16, message: 'salt must be 16 bytes at minimum');

  final receivePort = ReceivePort();
  final channel = IsolateChannel<List<int>>.connectReceive(receivePort);
  final runner = await IsolateRunner.spawn();
  final args = _CryptoArgs(password, salt, mode, receivePort.sendPort);

  final cryptoResult = runner.run(_cryptoInIsolate, args);
  unawaited(channel.sink.addStream(concat([inStream, Stream.value(null)])));

  try {
    yield* channel.stream.takeWhile((chunk) => chunk != null);
    await cryptoResult;
  } finally {
    receivePort.close();
    await runner.close();
  }
}

enum _CryptoMode { encrypt, decrypt }

class _CryptoArgs {
  final String password;
  final List<int> salt;
  final _CryptoMode mode;
  final SendPort sendPort;

  _CryptoArgs(this.password, this.salt, this.mode, this.sendPort);
}

/// Run [_encryptStream] or [_decryptStream], handling [args.salt] and
/// [args.sendPort] casting to [Uint8List]. The [args.sendPort] will be wrapped
/// with [IsolateChannel] for bi-directional communication, the [Stream] from
/// the channel will only be consumed up until a null is encountered and the
/// [Sink] from the channel will be null terminated.
Future<void> _cryptoInIsolate(_CryptoArgs args) async {
  final channel = IsolateChannel<List<int>>.connectSend(args.sendPort);
  final salt = Uint8List.fromList(args.salt);
  final inStream = channel.stream
      .takeWhile((chunk) => chunk != null)
      .map((chunk) => Uint8List.fromList(chunk));
  Stream<Uint8List> outStream;

  switch (args.mode) {
    case _CryptoMode.encrypt:
      outStream = _encryptStream(args.password, salt, inStream);
      break;
    case _CryptoMode.decrypt:
      outStream = _decryptStream(args.password, salt, inStream);
      break;
    default:
      throw StateError('Unhandled ${args.mode}.');
  }

  await channel.sink.addStream(concat([outStream, Stream.value(null)]));
}

/// Encrypt [plainStream] with key derived from [password] and [salt].
Stream<Uint8List> _encryptStream(
    String password, Uint8List salt, Stream<Uint8List> plainStream) async* {
  final key = _deriveKeyFromPassword(password, salt);

  final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
  yield result.header;

  yield* plainStream.rechunk(chunkSize: _chunkSize).withPosition().map(
      (plain) => Sodium.cryptoSecretstreamXchacha20poly1305Push(result.state,
          plain.value, null, plain.isLast ? _finalTag : _messageTag));
}

/// Decrypt [cipherStream] with key derived from [password] and [salt].
Stream<Uint8List> _decryptStream(
    String password, Uint8List salt, Stream<Uint8List> cipherStream) async* {
  final key = _deriveKeyFromPassword(password, salt);

  Pointer<Uint8> state;
  await for (final cipher in cipherStream
      .rechunk(headerSize: _headerSize, chunkSize: _chunkSize + _authSize)
      .withPosition()) {
    if (state == null) {
      final header = cipher.value;
      state = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);
    } else {
      final result = Sodium.cryptoSecretstreamXchacha20poly1305Pull(
          state, cipher.value, null);
      yield result.m;
    }
  }
}

Uint8List _deriveKeyFromPassword(String password, Uint8List salt) {
  return PasswordHash.hashString(password, salt,
      outlen: Sodium.cryptoSecretstreamXchacha20poly1305Keybytes,
      opslimit: _opsLimit,
      memlimit: _memLimit);
}

class _ChunkPosition {
  final Uint8List value;
  final bool isLast;
  _ChunkPosition({@required this.value, @required this.isLast});
}

extension _ChunkStreamTransformer on Stream<Uint8List> {
  /// Re-emit chunks from [this] with given sizes. The first chunk will be of
  /// <= [headerSize] (defaults to [chunkSize]), and the rest will be <=
  /// [chunkSize].
  Stream<Uint8List> rechunk({@required int chunkSize, int headerSize}) async* {
    headerSize ??= chunkSize;

    final buffer = <int>[];
    final flatStream = expand((bytes) => bytes);
    var isFirstYield = true;
    await for (final byte in flatStream) {
      if (isFirstYield && buffer.length == headerSize) {
        yield Uint8List.fromList(buffer);
        buffer.clear();
        isFirstYield = false;
      } else if (!isFirstYield && buffer.length == chunkSize) {
        yield Uint8List.fromList(buffer);
        buffer.clear();
      }

      buffer.add(byte);
    }
    yield Uint8List.fromList(buffer);
  }

  /// Tags chunks from [this] if they are last or not.
  Stream<_ChunkPosition> withPosition() async* {
    final streamIter = StreamIterator(this);
    if (!await streamIter.moveNext()) {
      return;
    }

    while (true) {
      final before = streamIter.current;
      if (await streamIter.moveNext()) {
        yield _ChunkPosition(value: before, isLast: false);
      } else {
        yield _ChunkPosition(value: before, isLast: true);
        break;
      }
    }
  }
}
