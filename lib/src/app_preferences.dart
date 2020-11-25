import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper over [SharedPreferences] only exposing preferences that will
/// actually be used by the app.
class AppPreferences {
  static const _passwordHashKey = 'passwordHashKey';

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

  Future<void> setPasswordHash(String hash) async {
    final prefs = await _futurePrefs;
    return prefs.setString(_passwordHashKey, hash);
  }

  Future<void> clear() async {
    final prefs = await _futurePrefs;
    await prefs.clear();
  }
}
