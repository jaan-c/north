import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  Box<String> box;

  setUpAll(() async {
    await Hive.initFlutter();
  });

  setUp(() async {
    // Not persisted to disk.
    box = await Hive.openBox('Test', bytes: Uint8List.fromList([]));
  });

  test('put overrides already existing item.', () async {
    await box.put(1, 'Old Item');

    await expectLater(box.put(1, 'New Item'), completes);
    await expectLater(box.get(1), 'New Item');
  });
}
