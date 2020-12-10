import 'dart:async';

import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

import 'password_page.dart';

typedef DoneCallback = FutureOr<void> Function(String password);

/// A page for setting up password authentication.
class SetupAuthenticationPage extends StatefulWidget {
  final DoneCallback onDone;

  SetupAuthenticationPage({this.onDone});

  @override
  _SetupAuthenticationPageState createState() =>
      _SetupAuthenticationPageState();
}

class _SetupAuthenticationPageState extends State<SetupAuthenticationPage> {
  final prefs = AppPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return PasswordPage(
      title: 'Set Password',
      onSubmitPassword: _setPasswordHashInPrefs,
    );
  }

  Future<void> _setPasswordHashInPrefs(String password) async {
    final hash = await derivePasswordHash(password);
    final salt = generateSalt();

    await prefs.setPasswordHash(hash);
    await prefs.setSalt(salt);

    await widget.onDone?.call(password);
  }
}
