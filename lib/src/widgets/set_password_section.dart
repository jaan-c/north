import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

/// A section for accepting a password from user and setting password hash in
/// [AppPreferences] unconditionally.
class SetPasswordSection extends StatefulWidget {
  @override
  _SetPasswordSectionState createState() => _SetPasswordSectionState();
}

class _SetPasswordSectionState extends State<SetPasswordSection> {
  final prefs = AppPreferences.getInstance();
  final passwordController = TextEditingController();
  var obscurePassword = true;

  bool get isPasswordValid => passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _titleText(context),
          _passwordField(context),
          _submitButton(),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  Widget _titleText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text('Set Password', style: textTheme.headline5);
  }

  Widget _passwordField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: passwordController,
      style: textTheme.subtitle1,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(obscurePassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded),
          onPressed: _toggleObscurePassword,
        ),
        border: OutlineInputBorder(),
      ),
      obscureText: obscurePassword,
      autofocus: true,
      autocorrect: false,
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      child: Text('Submit'),
      onPressed: isPasswordValid ? _setPassword : null,
      autofocus: false,
      clipBehavior: Clip.antiAlias,
    );
  }

  Future<void> _setPassword() async {
    final password = passwordController.text;
    final hash = await derivePasswordHash(password);
    await prefs.setPasswordHash(hash);
  }

  void _toggleObscurePassword() {
    setState(() => obscurePassword = !obscurePassword);
  }
}
