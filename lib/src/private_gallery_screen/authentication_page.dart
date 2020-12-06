import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

import 'password_page.dart';

/// A page for authenticating access to private gallery.
class AuthenticationPage extends StatefulWidget {
  final SubmitPasswordCallback onSubmitPassword;

  AuthenticationPage({@required this.onSubmitPassword});

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final prefs = AppPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return PasswordPage(
      title: 'Enter Password',
      onSubmitPassword: widget.onSubmitPassword,
      onCheckPassword: _checkPassword,
    );
  }

  Future<bool> _checkPassword(String password) async {
    final hash = await prefs.getPasswordHash();
    if (hash.isEmpty) {
      throw StateError('Password hash is empty.');
    }

    return verifyPassword(password, hash);
  }
}
