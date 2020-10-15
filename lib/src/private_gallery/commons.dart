import 'package:uuid/uuid.dart' as uuidlib;

class Uuid {
  final String _uuidString;

  Uuid._internal(String uuidString) : _uuidString = uuidString.toLowerCase();

  factory Uuid.generate() {
    final uuid = uuidlib.Uuid().v4();
    final stripped = _removeHyphen(uuid);

    return Uuid._internal(stripped);
  }

  factory Uuid.fromString(String uuidString) {
    if (uuidString.length == 32 && _isHex(uuidString)) {
      return Uuid._internal(uuidString);
    } else {
      throw StateError("Invalid uuid $uuidString.");
    }
  }

  @override
  bool operator ==(Object other) => other is Uuid && hashCode == other.hashCode;

  @override
  int get hashCode => _uuidString.hashCode;

  @override
  String toString() => _uuidString;
}

String _removeHyphen(String string) {
  final hyphen = RegExp(r"-");
  return string.replaceAll(hyphen, "");
}

bool _isHex(String uuid) {
  final hex = RegExp(r"^[0-9a-f]+$", caseSensitive: false);
  return hex.hasMatch(uuid);
}
