import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper over [SharedPreferences] only exposing preferences that will
/// actually be used by the app.
///
/// Only one instance should exist at runtime, otherwise behavior is undefined.
class AppPreferences with ChangeNotifier {
  static const _passwordHashKey = 'passwordHash';
  static const _saltKey = 'salt';

  static Future<AppPreferences> instantiate() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences._internal(prefs);
  }

  final SharedPreferences _prefs;

  String get passwordHash => _prefs.getString(_passwordHashKey) ?? '';

  List<int> get salt =>
      _prefs.getStringList(_saltKey)?.map((s) => int.parse(s))?.toList() ?? [];

  AppPreferences._internal(this._prefs);

  Future<void> setPasswordHash(String newHash) async {
    await _prefs.setString(_passwordHashKey, newHash);
    notifyListeners();
  }

  Future<void> setSalt(List<int> newSalt) async {
    await _prefs.setStringList(
        _saltKey, newSalt.map((i) => i.toString()).toList());
    notifyListeners();
  }

  Future<void> clear() async {
    await _prefs.clear();
    notifyListeners();
  }
}
