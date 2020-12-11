import 'dart:async';

import 'package:flutter/material.dart';

typedef SubmitPasswordCallback = FutureOr<void> Function(String password);
typedef CheckPasswordCallback = FutureOr<bool> Function(String password);

/// A page for accepting a password from user.
class PasswordPage extends StatefulWidget {
  final String title;
  final SubmitPasswordCallback onSubmitPassword;
  final CheckPasswordCallback onCheckPassword;

  PasswordPage(
      {@required this.title,
      @required this.onSubmitPassword,
      this.onCheckPassword});

  @override
  _PasswordPageState createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
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
    passwordController.dispose();
    super.dispose();
  }

  void _setIsPasswordValidState() {
    setState(() => isPasswordValid = passwordController.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _body(context)),
      floatingActionButton: _submitFab(),
    );
  }

  Widget _body(BuildContext context) {
    return Center(
      child: Padding(
        child: Column(
          children: [
            _titleText(context),
            SizedBox(height: 32),
            if (isCheckingPassword) ...[
              LinearProgressIndicator(),
              SizedBox(height: 8),
              _checkingPasswordText(context)
            ] else ...[
              _passwordField(context),
            ]
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

  Widget _checkingPasswordText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text('Checking password', style: textTheme.subtitle2);
  }

  Widget _submitFab() {
    if (!isPasswordValid || isCheckingPassword) {
      return null;
    }

    return FloatingActionButton(
      child: Icon(Icons.check),
      onPressed: _submitPassword,
    );
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

    if (!result) {
      _showSnackbar(context, 'Invalid password');
    }

    return result;
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _toggleObscurePassword() {
    setState(() => obscurePassword = !obscurePassword);
  }
}
