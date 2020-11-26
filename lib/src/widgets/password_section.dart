import 'dart:async';

import 'package:flutter/material.dart';

typedef SubmitPasswordCallback = FutureOr<void> Function(String password);
typedef CheckPasswordCallback = FutureOr<bool> Function(String password);

/// A section for accepting a password from user.
class PasswordSection extends StatefulWidget {
  final String title;
  final SubmitPasswordCallback onSubmitPassword;
  final CheckPasswordCallback onCheckPassword;

  PasswordSection(
      {@required this.title,
      @required this.onSubmitPassword,
      this.onCheckPassword});

  @override
  _PasswordSectionState createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<PasswordSection> {
  final passwordController = TextEditingController();
  var obscurePassword = true;
  var isCheckingPassword = false;
  var isPasswordValid = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_setIsPasswordValidState);
  }

  @override
  void dispose() {
    passwordController.removeListener(_setIsPasswordValidState);
    super.dispose();
  }

  void _setIsPasswordValidState() {
    final password = passwordController.text;
    setState(() => isPasswordValid = password.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        child: Column(
          children: [
            _titleText(context),
            if (isCheckingPassword) ...[
              LinearProgressIndicator(),
              _checkingPasswordText(context),
            ] else ...[
              _passwordField(context),
              _submitButton(context),
            ],
          ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _titleText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(widget.title, style: textTheme.headline5);
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

  Widget _submitButton(BuildContext context) {
    return ElevatedButton(
      child: Text('Submit'),
      onPressed: isPasswordValid ? _submitPassword : null,
      autofocus: false,
      clipBehavior: Clip.antiAlias,
    );
  }

  Widget _checkingPasswordText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text('Checking Password', style: textTheme.subtitle2);
  }

  Future<void> _submitPassword() async {
    final password = passwordController.text;
    if (await _checkPassword(password)) {
      await widget.onSubmitPassword(password);
    }
  }

  Future<bool> _checkPassword(String password) async {
    if (widget.onCheckPassword == null) {
      return true;
    }

    setState(() => isCheckingPassword = true);
    final result = await widget.onCheckPassword(password);
    setState(() => isCheckingPassword = false);

    return result;
  }

  void _toggleObscurePassword() {
    setState(() => obscurePassword = !obscurePassword);
  }
}
