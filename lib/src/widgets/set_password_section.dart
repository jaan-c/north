import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

import 'password_section.dart';

/// A section for accepting a password from user and setting password hash in
/// [AppPreferences] unconditionally.
class SetPasswordSection extends StatefulWidget {
  @override
  _SetPasswordSectionState createState() => _SetPasswordSectionState();
}

class _SetPasswordSectionState extends State<SetPasswordSection> {
  final prefs = AppPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return PasswordSection(
      title: 'Set Password',
      onSubmitPassword: _setPassword,
    );
  }

  Future<void> _setPassword(String password) async {
    final hash = await derivePasswordHash(password);
    await prefs.setPasswordHash(hash);
  }
}
