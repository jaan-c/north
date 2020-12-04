import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

import 'password_section.dart';

class VerifyPasswordSection extends StatefulWidget {
  final SubmitPasswordCallback onSubmitPassword;

  VerifyPasswordSection({@required this.onSubmitPassword});

  @override
  _VerifyPasswordSectionState createState() => _VerifyPasswordSectionState();
}

class _VerifyPasswordSectionState extends State<VerifyPasswordSection> {
  final prefs = AppPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return PasswordSection(
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
