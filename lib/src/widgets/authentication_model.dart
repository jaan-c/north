import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

enum AuthenticationStatus { unconfigured, close, open }

class AuthenticationModel with ChangeNotifier {
  static Future<AuthenticationModel> instantiate() async {
    final prefs = await AppPreferences.instantiate();

    AuthenticationStatus status;
    if (prefs.passwordHash.isEmpty && prefs.salt.isEmpty) {
      status = AuthenticationStatus.unconfigured;
    } else {
      status = AuthenticationStatus.close;
    }

    return AuthenticationModel._internal(prefs, status);
  }

  final AppPreferences _prefs;

  AuthenticationStatus get status => _status;
  Uint8List get key => _key;

  Uint8List _key;
  AuthenticationStatus _status;

  AuthenticationModel._internal(this._prefs, AuthenticationStatus initialStatus)
      : _status = initialStatus;

  Future<void> setup(String password) async {
    final passwordHash = await derivePasswordHash(password);
    final salt = generateSalt();

    await _prefs.setPasswordHash(passwordHash);
    await _prefs.setSalt(salt);

    _key = Uint8List.fromList([]);
    _status = AuthenticationStatus.close;
    notifyListeners();
  }

  Future<void> authenticate(String password) async {
    if (status == AuthenticationStatus.unconfigured) {
      throw StateError(
          'Trying to authenticate while authentication status is unconfigured.');
    } else if (status == AuthenticationStatus.open) {
      return;
    }

    if (await verifyPassword(password, _prefs.passwordHash)) {
      _key = await deriveKey(password, _prefs.salt);
      _status = AuthenticationStatus.open;
      notifyListeners();
    }
  }
}
