import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';
import 'package:north/src/private_gallery/cancelable_future.dart';
import 'package:north/src/private_gallery/file_store.dart';
import 'package:north/src/private_gallery/uuid.dart';

import '../utils.dart';

class TestFileStore with FileStore {
  @override
  final Uint8List key;

  @override
  final Directory fileDir;

  @override
  final Directory cacheDir;

  TestFileStore(
      {@required this.key, @required this.fileDir, @required this.cacheDir});
}

void main() {
  final throwsFileStoreException = throwsA(isInstanceOf<FileStoreException>());
  final throwsCancelledException = throwsA(isInstanceOf<CancelledException>());

  TestFileStore store;
  Directory tempDir;

  setUp(() async {
    store = TestFileStore(
        key: await deriveKey('Password', generateSalt()),
        fileDir: await createTempDir('file_dir'),
        cacheDir: await createTempDir('cache_dir'));
    tempDir = await createTempDir();
  });

  tearDown(() async {
    await store.fileDir.delete(recursive: true);
    await store.cacheDir.delete(recursive: true);
    await tempDir.delete(recursive: true);
  });

  test('put and putBytes throws FileStoreException on existing id.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();

    await file.writeAsBytes(content);
    await store.put(id, file);

    await expectLater(store.put(id, file), throwsFileStoreException);
  });

  test('putStream throws FileStoreException on existing id.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);

    await store.putStream(id, Stream.fromIterable([content]));

    await expectLater(store.putStream(id, Stream.fromIterable([content])),
        throwsFileStoreException);
  });

  test('get throws FileStoreException on non-existent id.', () async {
    final id = Uuid.generate();

    await expectLater(store.get(id), throwsFileStoreException);
  });

  test('get retrieves inserted file with put.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();
    await file.writeAsBytes(content);

    await store.put(id, file);
    final retrievedFile = await store.get(id);
    final retrievedContent = await retrievedFile.readAsBytes();

    expect(content, retrievedContent);
  });

  test('get retrieves inserted file with putStream.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);

    await store.putStream(id, Stream.fromIterable([content]));
    final retrievedFile = await store.get(id);
    final retrievedContent = await retrievedFile.readAsBytes();

    expect(content, retrievedContent);
  });

  test('put throws CancelledOperationException on cancel.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();
    await file.writeAsBytes(content);

    final putResult = store.put(id, file);
    await putResult.cancel();

    await expectLater(putResult, throwsCancelledException);
  });

  test('putStream throws CancelledOperationException on cancel.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);

    final putResult = store.putStream(id, Stream.fromIterable([content]));
    await putResult.cancel();

    await expectLater(putResult, throwsCancelledException);
  });

  test('get throws CancelledOperationException on cancel.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();
    await file.writeAsBytes(content);

    await store.put(id, file);
    final getResult = store.get(id);
    await getResult.cancel();

    await expectLater(getResult, throwsCancelledException);
  });
}
