import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/private_gallery/commons/uuid.dart';
import 'package:north/src/private_gallery/media_store/media_store.dart';

import '../../utils.dart';

void main() {
  final throwsMediaStoreException =
      throwsA(isInstanceOf<MediaStoreException>());

  Directory tempDir;
  Directory mediaDir;
  Directory cacheDir;
  MediaStore store;

  setUp(() async {
    mediaDir = await createTempDir();
    cacheDir = await createTempDir();
    tempDir = await createTempDir();
    store = MediaStore(
        password: 'Password', externalRoot: mediaDir, cacheRoot: cacheDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    await mediaDir.delete(recursive: true);
    await cacheDir.delete(recursive: true);
  });

  test('put throws MediaStoreException on existing id.', () async {
    final id = Uuid.generate();
    final content = randomBytes(2048);
    final file = tempDir.file();

    await file.writeAsBytes(content);
    await store.put(id, file);

    await expectLater(store.put(id, file), throwsMediaStoreException);
  });

  test('get throws MediaStoreException on non-existent id.', () async {
    final id = Uuid.generate();
    final salt = randomBytes(16);

    await expectLater(store.get(id, salt), throwsMediaStoreException);
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
