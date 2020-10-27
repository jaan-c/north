import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

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
