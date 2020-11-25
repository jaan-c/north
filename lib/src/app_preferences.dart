import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper over [SharedPreferences] only exposing preferences that will
/// actually be used by the app.
class AppPreferences {
  static const _passwordHashKey = 'passwordHash';
  static const _saltKey = 'salt';

  static AppPreferences _instance;

  static AppPreferences getInstance() {
    _instance ??= AppPreferences._internal();

    return _instance;
  }

  final _futurePrefs = SharedPreferences.getInstance();

  AppPreferences._internal();

  Future<String> getPasswordHash() async {
    final prefs = await _futurePrefs;
    return prefs.getString(_passwordHashKey) ?? '';
  }

  Future<void> setPasswordHash(String newHash) async {
    final prefs = await _futurePrefs;
    return prefs.setString(_passwordHashKey, newHash);
  }

  Future<List<int>> getSalt() async {
    final prefs = await _futurePrefs;
    final saltString = prefs.getStringList(_saltKey);
    return saltString.map((s) => int.parse(s));
  }

  Future<void> setSalt(List<int> newSalt) async {
    final prefs = await _futurePrefs;
    final newSaltString = newSalt.map((i) => i.toString());
    return prefs.setStringList(_saltKey, newSaltString);
  }

  Future<void> clear() async {
    final prefs = await _futurePrefs;
    await prefs.clear();
  }
}
