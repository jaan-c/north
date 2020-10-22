import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Version is 1.0.18", () {
    expect(Sodium.versionString, "1.0.18");
  });
}
