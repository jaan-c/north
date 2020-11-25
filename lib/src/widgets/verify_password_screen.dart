import 'package:flutter/material.dart';
import 'package:north/shared_preferences.dart';
import 'package:north/src/crypto/password.dart';

import 'password_screen.dart';

typedef SubmitPasswordCallback = void Function(String password);

class VerifyPasswordScreen extends StatefulWidget {
  final SubmitPasswordCallback onSubmitPassword;

  VerifyPasswordScreen({@required this.onSubmitPassword});

  @override
  _VerifyPasswordScreenState createState() => _VerifyPasswordScreenState();
}

class _VerifyPasswordScreenState extends State<VerifyPasswordScreen> {
  final prefs = SharedPreferences.getInstance();

  var isCheckingPassword = false;

  @override
  Widget build(BuildContext context) {
    return PasswordScreen(
        onSubmitPassword: _onSubmitPassword, onCheckPassword: _onCheckPassword);
  }

  void _onSubmitPassword(String password) {
    widget.onSubmitPassword(password);
  }

  Future<bool> _onCheckPassword(String password) async {
    final hash = await prefs.getPasswordHash();
    return verifyPassword(password, hash);
  }
}
