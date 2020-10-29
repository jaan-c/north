import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils.dart';

void main() {
  Uint8List key;

  setUpAll(() {
    Sodium.init();
    key = Sodium.cryptoSecretstreamXchacha20poly1305Keygen();
  });

  test('Message tag is 0.', () {
    expect(Sodium.cryptoSecretstreamXchacha20poly1305TagMessage, 0);
  });

  test('HEADERBYTES is 24', () {
    expect(Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes, 24);
  });

  test('ABYTES is 16', () {
    expect(Sodium.cryptoAeadChacha20poly1305Abytes, 16);
  });

  test('push does not throw on subsequent push after final tag.', () {
    final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    Sodium.cryptoSecretstreamXchacha20poly1305Push(
        result.state,
        randomBytes(1024),
        null,
        Sodium.cryptoSecretstreamXchacha20poly1305TagFinal);

    expect(
        () => Sodium.cryptoSecretstreamXchacha20poly1305Push(
            result.state, randomBytes(1024), null, 0),
        returnsNormally);
    expect(
        () => Sodium.cryptoSecretstreamXchacha20poly1305Push(
            result.state,
            randomBytes(1024),
            null,
            Sodium.cryptoSecretstreamXchacha20poly1305TagFinal),
        returnsNormally);
  });

  test('Full encrypt and decrypt.', () {
    final message1 = randomBytes(1024);
    final message2 = randomBytes(1024);
    final message3 = randomBytes(0);

    final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    final cipher1 = Sodium.cryptoSecretstreamXchacha20poly1305Push(
        result.state, message1, null, 0);
    final cipher2 = Sodium.cryptoSecretstreamXchacha20poly1305Push(
        result.state, message2, null, 0);
    // Often in a real stream, there isn't a way to know if the chunk you have
    // is the last, until the stream closes, so check if libsodium is okay with
    // 0 length chunk.
    final cipher3 = Sodium.cryptoSecretstreamXchacha20poly1305Push(result.state,
        message3, null, Sodium.cryptoSecretstreamXchacha20poly1305TagFinal);

    final state =
        Sodium.cryptoSecretstreamXchacha20poly1305InitPull(result.header, key);
    final result1 =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(state, cipher1, null);
    expect(result1.tag, 0);
    expect(result1.m, message1);
    final result2 =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(state, cipher2, null);
    expect(result2.tag, 0);
    expect(result2.m, message2);
    final result3 =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(state, cipher3, null);
    expect(result3.tag, Sodium.cryptoSecretstreamXchacha20poly1305TagFinal);
    expect(result3.m, message3);
  });
}
