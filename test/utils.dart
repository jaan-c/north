import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;

Uint8List randomBytes(int size) {
  final random = Random();
  return Uint8List.fromList(
      [for (var i = 0; i < size; i++) random.nextInt(256)]);
}

int randomInt({int min = 0, @required int max}) {
  assert(min >= 0);
  assert(max > min);

  final random = Random();
  return random.nextInt((max - min) + min);
}

String randomString({int length = 16}) {
  final lower = 'abcdefghijklmnopqrstuvwxyz';
  final upper = lower.toUpperCase();
  final digits = '0123456789';
  final separators = '-_.';
  final all = lower + upper + digits + separators;
  return [for (var i = 0; i < length; i++) all[randomInt(max: length)]]
      .join('');
}

Future<Directory> createTempDir([String prefix = 'temp_dir']) async {
  return Directory.systemTemp.createTemp(prefix);
}

extension FileWithin on Directory {
  File file([String name]) {
    name ??= randomString();
    return File(pathlib.join(path, name));
  }
}
