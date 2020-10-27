import 'dart:math';
import 'dart:typed_data';

Uint8List randomBytes(int size) {
  final random = Random();
  return Uint8List.fromList(
      [for (var i = 0; i < size; i++) random.nextInt(256)]);
}
