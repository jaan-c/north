import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart' as uuidlib;

part 'uuid.g.dart';

@HiveType(typeId: 1)
class Uuid {
  @HiveField(0)
  final String asString;

  Uuid(String uuidString)
      : assert(uuidString.length == 32 && _isHex(uuidString)),
        asString = uuidString.toLowerCase();

  factory Uuid.generate() {
    final uuid = uuidlib.Uuid().v4();
    final clean = _removeHyphens(uuid);

    return Uuid(clean);
  }

  @override
  bool operator ==(Object other) => other is Uuid && hashCode == other.hashCode;

  @override
  int get hashCode => asString.hashCode;
}

String _removeHyphens(String string) {
  final hyphen = RegExp(r'-');
  return string.replaceAll(hyphen, '');
}

bool _isHex(String uuid) {
  final hex = RegExp(r'^[0-9a-f]+$', caseSensitive: false);
  return hex.hasMatch(uuid);
}
