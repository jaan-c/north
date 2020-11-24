import 'dart:async';

import 'package:flutter/material.dart';

typedef SubmitPasswordCallback = FutureOr<void> Function(String password);
typedef CheckPasswordCallback = FutureOr<bool> Function(String password);

class PasswordScreen extends StatefulWidget {
  final String title;
  final SubmitPasswordCallback onSubmitPassword;
  final CheckPasswordCallback onCheckPassword;

  PasswordScreen(
      {@required this.onSubmitPassword,
      this.title = 'Enter Password',
      this.onCheckPassword});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final passwordController = TextEditingController();

  var isCheckingPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _body(context)),
      floatingActionButton: !isCheckingPassword ? _submitFab(context) : null,
    );
  }

  Widget _body(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        child: Column(
          children: [
            Text(widget.title, style: textTheme.headline5),
            SizedBox(height: 16),
            _passwordField(context),
          ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _passwordField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: passwordController,
      style: textTheme.subtitle1,
      decoration: InputDecoration(border: OutlineInputBorder()),
      obscureText: true,
      autofocus: true,
      autocorrect: false,
    );
  }

  Widget _submitFab(BuildContext context) {
    return FloatingActionButton.extended(
      icon: Icon(Icons.check),
      label: Text('Submit'),
      onPressed: () => _onSubmitPassword(context),
    );
  }

  void _onSubmitPassword(BuildContext context) async {
    final password = passwordController.text;

    if (password.isEmpty) {
      _showSnackBar(context, 'Empty password.');
      return;
    }

    _showSnackBar(context, 'Checking password.');
    isCheckingPassword = true;

    if (widget.onCheckPassword != null
        ? await widget.onCheckPassword(password)
        : true) {
      await widget.onSubmitPassword(password);
    } else {
      _showSnackBar(context, 'Wrong password.');
    }

    isCheckingPassword = false;
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    final snackBar =
        SnackBar(content: Text(message), duration: Duration(seconds: 1));
    messenger.showSnackBar(snackBar);
  }
}
