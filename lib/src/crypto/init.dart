import 'package:flutter_sodium/flutter_sodium.dart';

/// Initialize crypto functions. Safe to call multiple times.
void initCrypto() {
  Sodium.init();
}
