import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:isolate/isolate.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:pedantic/pedantic.dart';

final _headerSize = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;
final _authSize = Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
final _chunkSize = 1048576; // 1 MB
final _messageTag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
final _finalTag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;

class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);
  @override
  String toString() => '${(CryptoException).toString()}: $message';
}

/// Encrypt [plainStream] with [key].
///
/// [plainStream] can emit arbitrarily sized chunks. [CryptoException] is thrown
/// on encryption error.
Stream<List<int>> encryptStream(
    Uint8List key, Stream<List<int>> plainStream) async* {
  Sodium.init();

  yield* _cryptoStream(key, plainStream, _CryptoMode.encrypt);
}

/// Decrypt [cipherStream] with [key].
///
/// [cipherStream] can emit arbitrarily sized chunks. [CryptoException] is
/// thrown on decryption error.
Stream<List<int>> decryptStream(
    Uint8List key, Stream<List<int>> cipherStream) async* {
  Sodium.init();

  yield* _cryptoStream(key, cipherStream, _CryptoMode.decrypt);
}

/// Runs [_cryptoInIsolate] inside an [Isolate] with [_CryptoArgs] populated
/// with [key], [inStream] and [mode].
///
/// This handles the null signalling expected by [_cryptoInIsolate].
/// [CryptoException] is thrown on encryption or decryption errors.
Stream<List<int>> _cryptoStream(
    Uint8List key, Stream<List<int>> inStream, _CryptoMode mode) async* {
  final receivePort = ReceivePort();
  final channel = IsolateChannel.connectReceive(receivePort);
  final runner = await IsolateRunner.spawn();
  final args = _CryptoArgs(key, mode, receivePort.sendPort);

  final cryptoResult = runner.run(_cryptoInIsolate, args);
  unawaited(
      channel.sink.addStream(inStream.errorAsLastValue().nullTerminated()));

  try {
    await for (final chunk in channel.stream.takeWhileNotNull()) {
      if (chunk is Exception || chunk is SodiumException) {
        throw chunk;
      }

      yield chunk;
    }

    await cryptoResult;
  } on SodiumException catch (e) {
    throw CryptoException(e.toString());
  } finally {
    receivePort.close();
    await runner.close();
  }
}

enum _CryptoMode { encrypt, decrypt }

class _CryptoArgs {
  final Uint8List key;
  final _CryptoMode mode;
  final SendPort sendPort;

  _CryptoArgs(this.key, this.mode, this.sendPort);
}

/// Run [_encryptStream] or [_decryptStream], handling [args.sendPort] casting
/// to [Uint8List]. The [args.sendPort] will be wrapped with [IsolateChannel]
/// for bi-directional communication, the [Stream] from the channel will only be
/// consumed up until a null is encountered and the [Sink] from the channel will
/// be null terminated.
Future<void> _cryptoInIsolate(_CryptoArgs args) async {
  final channel = IsolateChannel.connectSend(args.sendPort);
  final inStream = channel.stream
      .takeWhileNotNull()
      .rethrowErrorValue()
      .map((chunk) => Uint8List.fromList(chunk));
  Stream<Uint8List> outStream;

  switch (args.mode) {
    case _CryptoMode.encrypt:
      outStream = _encryptStream(args.key, inStream);
      break;
    case _CryptoMode.decrypt:
      outStream = _decryptStream(args.key, inStream);
      break;
    default:
      throw StateError('Unhandled ${args.mode}.');
  }

  try {
    await for (final chunk in outStream) {
      channel.sink.add(chunk);
    }
  } on Exception catch (e) {
    channel.sink.add(e);
  } on SodiumException catch (e) {
    channel.sink.add(e);
  } finally {
    channel.sink.add(null);
  }
}

/// Methods for handling null terminated and error as value pattern used by
/// [_cryptoInIsolate].
extension StreamSignal on Stream {
  /// Re-emit [this] up until a null is encountered.
  Stream takeWhileNotNull() async* {
    yield* takeWhile((value) => value != null);
  }

  Stream rethrowErrorValue() async* {
    await for (final value in this) {
      if (value is Exception || value is SodiumException) {
        throw value;
      }

      yield value;
    }
  }

  /// Emit encountered errors from [this] as the last value. Otherwise re-emit
  /// values as-is.
  Stream errorAsLastValue() async* {
    try {
      await for (final value in this) {
        yield value;
      }
    } catch (e) {
      yield e;
    }
  }

  /// Re-emit [this] and null as the last value.
  Stream nullTerminated() async* {
    yield* this;
    yield null;
  }
}

/// Encrypt [plainStream] with [key].
Stream<Uint8List> _encryptStream(
    Uint8List key, Stream<Uint8List> plainStream) async* {
  final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
  yield result.header;

  yield* plainStream.rechunk(chunkSize: _chunkSize).withPosition().map(
      (plain) => Sodium.cryptoSecretstreamXchacha20poly1305Push(result.state,
          plain.value, null, plain.isLast ? _finalTag : _messageTag));
}

/// Decrypt [cipherStream] with [key].
Stream<Uint8List> _decryptStream(
    Uint8List key, Stream<Uint8List> cipherStream) async* {
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
