import 'package:shared_preferences/shared_preferences.dart' as sp;

class SharedPreferences {
  static const _passwordHashKey = 'passwordHashKey';

  static SharedPreferences _instance;

  static SharedPreferences getInstance() {
    _instance ??= SharedPreferences._internal();

    return _instance;
  }

  SharedPreferences._internal();

  Future<String> getPasswordHash() async {
    final prefs = await sp.SharedPreferences.getInstance();
    return prefs.getString(_passwordHashKey) ?? '';
  }

  Future<void> setPasswordHash(String hash) async {
    final prefs = await sp.SharedPreferences.getInstance();
    return prefs.setString(_passwordHashKey, hash);
  }

  Future<void> clear() async {
    final prefs = await sp.SharedPreferences.getInstance();
    await prefs.clear();
  }
}
