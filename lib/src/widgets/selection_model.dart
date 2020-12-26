import 'package:flutter/foundation.dart';

class SelectionModel<T> with ChangeNotifier {
  final String singularName;
  final String pluralName;

  List<T> _selection = <T>[];

  String get name => isSingle ? singularName : pluralName;

  bool get isEmpty => _selection.isEmpty;

  bool get isSingle => _selection.length == 1;

  int get count => _selection.length;

  T get single => _selection.single;

  SelectionModel({@required this.singularName, String pluralName})
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

    _selection = newSelection;
    notifyListeners();
  }

  void clear() {
    _selection = [];
    notifyListeners();
  }

  List<T> toList() {
    return _selection.toList();
  }
}
