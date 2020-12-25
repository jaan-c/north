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

  AppPreferences._internal(this._prefs);

  Future<String> getPasswordHash() async {
    return _prefs.getString(_passwordHashKey) ?? '';
  }

  Future<void> setPasswordHash(String newHash) async {
    await _prefs.setString(_passwordHashKey, newHash);
    notifyListeners();
  }

  Future<List<int>> getSalt() async {
    final saltString = _prefs.getStringList(_saltKey);
    return saltString.map((s) => int.parse(s)).toList();
  }

  Future<void> setSalt(List<int> newSalt) async {
    final newSaltString = newSalt.map((i) => i.toString()).toList();
    await _prefs.setStringList(_saltKey, newSaltString);
    notifyListeners();
  }

  Future<void> clear() async {
    await _prefs.clear();
    notifyListeners();
  }
}
