import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/private_gallery/file_store.dart';
import 'package:north/src/private_gallery/uuid.dart';

import '../utils.dart';

class TestFileStore with FileStore {
  @override
  final password = 'Password';

  @override
  final futureMediaDir = createTempDir();

  @override
  final futureCacheDir = createTempDir();
}

void main() {
  final throwsFileStoreException = throwsA(isInstanceOf<FileStoreException>());

  TestFileStore store;
  Directory tempDir;

  setUp(() async {
    store = TestFileStore();
    tempDir = await createTempDir();
  });

  tearDown(() async {
    await (await store.futureMediaDir).delete(recursive: true);
    await (await store.futureCacheDir).delete(recursive: true);
    await tempDir.delete(recursive: true);
  });

  test('put throws FileStoreException on existing id.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();

    await file.writeAsBytes(content);
    await store.put(id, file);

    await expectLater(store.put(id, file), throwsFileStoreException);
  });

  test('get throws FileStoreException on non-existent id.', () async {
    final id = Uuid.generate();
    final salt = randomBytes(16);

    await expectLater(store.get(id, salt), throwsFileStoreException);
  });

  test('get retrieves inserted file with put.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();
    await file.writeAsBytes(content);

    final salt = await store.put(id, file);
    final retrievedFile = await store.get(id, salt);
    final retrievedContent = await retrievedFile.readAsBytes();

    expect(content, retrievedContent);
  });
}
