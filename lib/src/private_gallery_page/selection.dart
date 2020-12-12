import 'package:flutter/widgets.dart';

class Selection<T> {
  final String singularName;
  final String pluralName;
  final void Function(VoidCallback) setState;

  List<T> _selection = <T>[];

  String get name => isSingle ? singularName : pluralName;

  bool get isEmpty => _selection.isEmpty;

  bool get isSingle => _selection.length == 1;

  int get count => _selection.length;

  T get single => _selection.single;

  Selection(
      {@required this.singularName, String pluralName, @required this.setState})
      : pluralName = pluralName ?? singularName;

  bool contains(T item) {
    return _selection.contains(item);
  }

  void toggle(T item) {
    final newSelection = _selection.toList();
    if (newSelection.contains(item)) {
      newSelection.remove(item);
    } else {
      newSelection.add(item);
    }

    setState(() => _selection = newSelection);
  }

  void clear() {
    setState(() => _selection = []);
  }

  List<T> toList() {
    return _selection.toList();
  }
}
